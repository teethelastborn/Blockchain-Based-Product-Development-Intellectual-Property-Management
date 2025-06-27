;; IP Manager Verification Contract
;; Validates and manages IP managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Data structures
(define-map ip-managers
  principal
  {
    name: (string-ascii 100),
    email: (string-ascii 100),
    organization: (string-ascii 100),
    status: (string-ascii 20),
    registered-at: uint,
    verified-by: (optional principal)
  }
)

(define-map manager-permissions
  principal
  {
    can-register-patents: bool,
    can-manage-licenses: bool,
    can-monitor-infringement: bool,
    can-coordinate-protection: bool
  }
)

(define-data-var total-managers uint u0)

;; Public functions
(define-public (register-manager (name (string-ascii 100)) (email (string-ascii 100)) (organization (string-ascii 100)))
  (let ((manager tx-sender))
    (asserts! (is-none (map-get? ip-managers manager)) ERR_ALREADY_REGISTERED)
    (map-set ip-managers manager {
      name: name,
      email: email,
      organization: organization,
      status: "pending",
      registered-at: block-height,
      verified-by: none
    })
    (var-set total-managers (+ (var-get total-managers) u1))
    (print {event: "manager-registered", manager: manager, name: name})
    (ok true)
  )
)

(define-public (verify-manager (manager principal))
  (let ((manager-data (unwrap! (map-get? ip-managers manager) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status manager-data) "pending") ERR_INVALID_STATUS)
    (map-set ip-managers manager (merge manager-data {
      status: "verified",
      verified-by: (some tx-sender)
    }))
    (map-set manager-permissions manager {
      can-register-patents: true,
      can-manage-licenses: true,
      can-monitor-infringement: true,
      can-coordinate-protection: true
    })
    (print {event: "manager-verified", manager: manager, verified-by: tx-sender})
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-manager (manager principal))
  (map-get? ip-managers manager)
)

(define-read-only (get-manager-permissions (manager principal))
  (map-get? manager-permissions manager)
)

(define-read-only (is-verified-manager (manager principal))
  (match (map-get? ip-managers manager)
    manager-data (is-eq (get status manager-data) "verified")
    false
  )
)

(define-read-only (get-total-managers)
  (var-get total-managers)
)
