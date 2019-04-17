
(define-keyset 'admin-keyset (read-keyset "admin-keyset"))

(module crowdfund-campaign 'admin-keyset

  ;define campaign schema
  (defschema campaign
    target-raise:decimal
    target-date:time
    ownerId:string
    keyset:keyset
    status:string
    )

  ;define account schema
  (defschema account
    balance:decimal
    keyset:keyset
    )

  (deftable campaigns-table:{campaign})
  (deftable accounts-table:{account})

  (defconst UNREACHED "UNREACHED")
  (defconst REACHED "REACHED")

  (defun create-account (accountId keyset initial-balance)
    "Create an account"
    (enforce-keyset 'admin-keyset)
    (insert accounts-table accountId {
      "keyset":(read-keyset keyset),
      "balance":initial-balance
      }))

  (defun create-campaign (campaignId ownerId keyset target-raise target-date)
    "Adds a campaign to campaign table"
    (enforce-keyset (read-keyset keyset))
    (insert campaigns-table campaignId{
        "target-raise":target-raise,
        "target-date":target-date,
        "ownerId":ownerId,
        "keyset":(read-keyset keyset),
        "status":UNREACHED
        })
      (create-account campaignId keyset 0.0))

  (defun debit (acctId amount)
    "Debit AMOUNT from ACCT balance"
    (with-read accounts-table acctId {
      "balance":= balance,
      "keyset":= keyset}
      (enforce-keyset keyset)
      (update accounts-table acctId {
        "balance": (- balance amount)
        })))

  (defun credit (acctId amount)
    "Credit AMOUNT from ACCT balance"
    (with-read accounts-table acctId {"balance":= balance}
      (update accounts-table acctId {
        "balance": (+ balance amount)
        })))

  (defun transfer (from to amount)
    "Transfers amount from from-account to to-account"
    (debit from amount)
    (credit to amount)
    )

  (defpact fund-campaign (from campaignId amount)
    (step-with-rollback
      ;;initiate
      (debit from amount)
      ;;rollback
      (credit from amount))
    ;;Executes when the campaign meets the goal
    (step
      (credit campaignId amount)))
  )

(create-table accounts-table)
(create-table campaigns-table)
