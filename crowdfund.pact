;define keyset to guard module
(define-keyset 'admin-keyset (read-keyset "admin-keyset"))

;define smart-contract code
(module crowdfund-campaign 'admin-keyset

;define campaign table
  (defschema campaign
    targetraise:decimal
    targetdate:time)

  (deftable campaign-table:{campaign})
;define escrow payment function
  (defun escrow)

)

;define table
(create-table campaign-table)
