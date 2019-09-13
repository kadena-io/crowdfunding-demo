
(define-keyset 'admin-keyset (read-keyset "admin-keyset"))

(module crowdfund-campaign 'admin-keyset
  (use coin)
  ;define campaign schema
  (defschema campaign
    title:string
    description:string
    current-raise:decimal
    target-raise:decimal
    start-date:time
    target-date:time
    ownerId:string
    keyset:guard
    status:integer
    )

  (defschema fund
    campaign-title:string
    fundOwner:string
    pact-id:string
    status:integer
    )

  (deftable campaigns-table:{campaign})
  (deftable funds-table:{fund})

  (defconst CREATED 0)
  (defconst CANCELLED 1)
  (defconst SUCCESS 2)
  (defconst FAIL 3)
  (defconst CROWDFUND_ACCT 'escrow-account)

  (defun crowdfund-guard:guard () (create-module-guard 'crowdfund-guard))

  (defcap CREATE (ks)
    (enforce-guard ks)
  )

  (defcap CANCEL:bool (title)
    (with-read campaigns-table title{
      "status":=status
      }
      (= status 1)))

  (defcap OPEN:bool (title)
    (with-read campaigns-table title{
      "target-date":=target-date,
      "start-date":=start-date,
      "status":=status
      }
      (and
        (< (curr-time) target-date)
        (>= (curr-time) start-date)
        (!= status 1))))

  (defcap SUCCESS:bool (title)
    (with-read campaigns-table title{
      "target-raise":=target-raise,
      "current-raise":=current-raise,
      "target-date":=target-date,
      "status":=status
      }
      (and
        (>= (curr-time) target-date)
        (>= current-raise target-raise)
        (!= status 1))))

  (defcap FAIL:bool (title)
    (with-read campaigns-table title{
      "target-raise":=target-raise,
      "target-date":=target-date,
      "current-raise":=current-raise,
      "status":=status
      }
      (and
        (>= (curr-time) target-date)
        (< current-raise target-raise)
        (!= status 1))))

  (defcap REFUND () true)
  (defcap RAISE () true)

  (defun create-campaign (title:string description:string ownerId:string target-raise:decimal start-date:time target-date:time)
    "Adds a campaign to campaign table"
    (enforce (< (curr-time) start-date) "Start Date shouldn't be in the past")
    (enforce (< start-date target-date) "Target Date should be later than start date")
    (enforce (< 0 target-raise) "target-raise must be positive")
    (enforce-guard (at 'guard (account-info ownerId)))

    (with-capability
      (CREATE (at 'guard (account-info ownerId)))
        (insert campaigns-table title {
            "title": title,
            "description": description,
            "target-raise":target-raise,
            "current-raise": 0.0,
            "start-date":start-date,
            "target-date":target-date,
            "ownerId": ownerId,
            "keyset": (at 'guard (account-info ownerId)),
            "status": CREATED
            })))

  (defun raise-campaign (title amount)
    (require-capability (RAISE))
    (with-read campaigns-table title {
      "current-raise":= current-raise
      }
      (update campaigns-table title {
        "current-raise": (+ current-raise amount)
        })))

  (defun refund-campaign (title amount)
    (require-capability (REFUND))
    (with-read campaigns-table title {
      "current-raise":= current-raise
      }
      (update campaigns-table title {
        "current-raise": (- current-raise amount)
        })))

  (defun read-campaigns:list ()
    "Read all campaigns in campaign table"
    (select campaigns-table ['title 'description 'target-raise 'status 'start-date 'target-date] (constantly true)))

  (defun fund-campaign (from title amount)
    (with-capability (OPEN title)
    ;;initiate
      (with-capability (RAISE)
        (transfer-and-create from CROWDFUND_ACCT (crowdfund-guard) amount)
        (with-default-read funds-table (get-fund-account from title) {
          "amount": 0
          } {
            "amount":= current-amount
          }
        (write funds-table (get-fund-account from title) {
          "campaign-title":title,
          "fundOwner":from,
          "status": CREATED,
          "amount": (+ current-amount amount)
          }))
        (raise-campaign title amount)))
    )

  (defun refund (from title)
    (with-capability (REFUND)
      (with-read funds-table (get-fund-account from title){
        "amount":= amount
        }
      (transfer CROWDFUND_ACCT 'from amount)
      (update funds-table (get-fund-account from title) {
          "amount": 0.0,
          "status": CANCELLED
        }
      )
      (refund-campaign title amount))))


  (defun cancel-crowdfund (title)
    ;;enforce account info guard
    (with-read campaigns-table title {
      "keyset":=keyset
      }
      (enforce-guard keyset))
    (update campaigns-table title {
      "status":CANCELLED
    })
    ;;refund everyone
    (map (refund (select ['fundOwner] funds-table (where 'campaign-title (= title)))))
  )

  (defun crowdfund-succeed (title)
    (with-capability (SUCCESS)
      (with-read campaigns-table title{
        "ownerId":=owner,
        "current-raise":=current-raise
        }
      (transfer CROWDFUND_ACCT owner current-raise))
      (update campaigns-table title {
        "status":SUCCESS
        })
    ))


  (defun crowdfund-fail (title)
    (with-capability (FAIL)
      (map (refund (select ['fundOwner] funds-table (where 'campaign-title (= title)))))
      (update campaigns-table title {
        "status":FAIL
        })
    ))

;  (defpact fund-campaign (from title amount)
;
;      (step-with-rollback
;        (with-capability (OPEN title)
;        ;;initiate
;          (with-capability (RAISE)
;            (transfer-and-create from (get-pact-account CROWDFUND_ACCT) (crowdfund-guard) amount)
;            (raise-campaign title amount)))
;        ;;rollback when campaign doesn't meet goal (target raise not met) OR Funder requests refund
;        (with-capability (REFUND)
;          (transfer (get-pact-account CROWDFUND_ACCT) from amount)
;          (refund-campaign title amount)))
;    ;;Executes when the campaign meets the goal - raise is above target before date
;      (step
;        (with-capability (CLOSED title)
;          (with-read campaigns-table title {"ownerId":= owner }
;          (transfer (get-pact-account CROWDFUND_ACCT) owner amount))))
;  )

  ;(defun get-pact-account:string (pfx:string) (format "{}-{}" [pfx (pact-id)]))
  (defun get-fund-account:string (account:string title:string) (format "{}-{}" [account title]))

  (defun curr-time:time ()
    @doc "Returns current chain's block-time in time type"
    (at 'block-time (chain-data)))
)

(create-table campaigns-table)
