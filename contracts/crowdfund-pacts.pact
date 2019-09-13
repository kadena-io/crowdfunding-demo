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
  (deftable funds-table: {fund})

  (defconst CREATED 0)
  (defconst CANCELLED 1)
  (defconst SUCCEEDED 2)
  (defconst FAILED 3)

  (defconst CROWDFUND_ACCT 'escrow-account)

  (defun crowdfund-guard:guard () (create-module-guard 'crowdfund-guard))

  (defcap ACCT_GUARD (account)
    (enforce-guard (at 'guard (account-info account))))

  (defcap CAMPAIGN_GUARD (title)
    (with-read campaigns-table title {
      "keyset":=guard
      }
      (enforce-guard guard))
  )

  (defcap ROLLBACK (title from)
    (with-read campaigns-table title {
      "status":=status
      }
      (enforce-one "refund guard failure or campaign already succeeded" [
        (enforce-guard (at 'guard (account-info from)))
        (enforce (= status CANCELLED) "Campaign has cancelled")
        (enforce (= status FAILED) "Campaign has failed")
        ])))

  (defcap CANCEL:bool (title)
    (with-read campaigns-table title{
      "status":=status
      }
      (enforce (= status CANCELLED) "NOT CANCELLED")))

  (defcap OPEN:bool (title)
    (with-read campaigns-table title{
      "target-date":=target-date,
      "start-date":=start-date,
      "status":=status
      }
      (enforce (!= status CANCELLED) "CAMPAIGN HAS BEEN CANCELLED")
      (enforce (< (curr-time) target-date) "CAMPAIGN HAS ENDED")
      (enforce (>= (curr-time) start-date) "CAMPAIGN HAS NOT STARTED")))

  (defcap SUCCESS:bool (title)
    (with-read campaigns-table title{
      "target-raise":=target-raise,
      "current-raise":=current-raise,
      "target-date":=target-date,
      "status":=status
      }
      (enforce (>= (curr-time) target-date) "CAMPAIGN HAS NOT ENDED")
      (enforce (>= current-raise target-raise) "CAMPAIGN HAS NOT RAISED ENOUGH")
      (enforce (!= status CANCELLED) "CAMPAIGN HAS BEEN CANCELLED")))

  (defcap FAIL:bool (title)
    (with-read campaigns-table title{
      "target-raise":=target-raise,
      "target-date":=target-date,
      "current-raise":=current-raise,
      "status":=status
      }
      (enforce (!= status CANCELLED) "CAMPAIGN HAS BEEN CANCELLED")
      (enforce (>= (curr-time) target-date) "CAMPAIGN HAS NOT ENDED")
      (enforce (< current-raise target-raise) "CAMPAIGN HAS SUCCEEDED")))


  (defcap REFUND () true)
  (defcap RAISE () true)

  (defun create-campaign (
    title:string description:string
    ownerId:string target-raise:decimal
    start-date:time target-date:time)
    "Adds a campaign to campaign table"
    (enforce (< (curr-time) start-date) "Start Date shouldn't be in the past")
    (enforce (< start-date target-date) "Start Date should be before target-date")
    (enforce (< 0 target-raise) "Target raise is not positive number")

    (with-capability (ACCT_GUARD ownerId)
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

  (defun read-campaigns:list ()
    "Read all campaigns in campaign table"
    (select campaigns-table
      ['title 'description 'start-date 'target-date  'current-raise 'target-raise 'status]
      (constantly true)))

  (defun cancel-campaign (title)
    (with-capability (CAMPAIGN_GUARD title)
      (update campaigns-table title {
          "status": CANCELLED
       }))
  ;;Rollback all -get all pacts and rollback
  )

  (defun succeed-campaign (title)
    (with-capability (SUCCESS title)
      (update campaigns-table title {
          "status": SUCCEEDED
       }))
  ;;resolve pacts - get all pacts and resolve
  )

  (defun fail-campaign (title)
    (with-capability (FAIL title)
      (update campaigns-table title {
          "status": FAILED
       }))
  ;;Rollback all -get all pacts and rollback
  )

  (defun create-fund (title funder)
     (insert funds-table (pact-id) {
       "campaign-title":title,
       "fundOwner":funder,
       "pact-id":(pact-id),
       "status":CREATED
       }))

  (defun cancel-fund (title funder)
    (require-capability (ROLLBACK))
     (insert funds-table (pact-id) {
       "campaign-title":title,
       "fundOwner":funder,
       "pact-id":(pact-id),
       "status":CANCELLED
       }))

  (defun fetch-pacts (title)
    (select funds-table (where 'campaign-title (= title))))

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

  (defpact fund-campaign (from title amount)

      (step-with-rollback
        ;;initiate
        (with-capability (ACCT_GUARD from)
          (with-capability (OPEN title)
            (with-capability (RAISE)
              (transfer-and-create from (get-pact-account CROWDFUND_ACCT) (crowdfund-guard) amount)
              (create-fund title from)
              (raise-campaign title amount)
              )))
        ;;rollback
        (with-capability (REFUND)
          (with-capability (ROLLBACK title from)
            (transfer (get-pact-account CROWDFUND_ACCT) from amount)
            (cancel-fund title from)
            (refund-campaign title amount)))
        )
      ;;Executes when the campaign meets the goal
      (step
        (with-capability (SUCCESS title)
          (with-read campaigns-table title {"ownerId":= owner }
          (transfer (get-pact-account CROWDFUND_ACCT) owner amount)))))

  (defun get-pact-account:string (pfx:string) (format "{}-{}" [pfx (pact-id)]))

  (defun curr-time:time ()
    @doc "Returns current chain's block-time in time type"
    (at 'block-time (chain-data)))

  )
