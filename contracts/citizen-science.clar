;; Citizen Science Platform Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Define data vars
(define-data-var project-id-nonce uint u0)
(define-data-var task-id-nonce uint u0)

;; Define maps
(define-map projects
  { project-id: uint }
  {
    name: (string-ascii 100),
    description: (string-utf8 1000),
    institution: principal,
    status: (string-ascii 20)
  }
)

(define-map tasks
  { task-id: uint }
  {
    project-id: uint,
    description: (string-utf8 1000),
    reward: uint,
    status: (string-ascii 20)
  }
)

(define-map project-tasks
  { project-id: uint }
  { task-ids: (list 100 uint) }
)

(define-map user-contributions
  { user: principal, task-id: uint }
  { data: (string-utf8 10000) }
)

(define-map user-rewards
  { user: principal }
  { balance: uint }
)

;; Define fungible token
(define-fungible-token citizen-science-token)

;; Functions

;; Create a new project
(define-public (create-project (name (string-ascii 100)) (description (string-utf8 1000)) (institution principal))
  (let
    (
      (new-project-id (+ (var-get project-id-nonce) u1))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set projects
      { project-id: new-project-id }
      {
        name: name,
        description: description,
        institution: institution,
        status: "active"
      }
    )
    (var-set project-id-nonce new-project-id)
    (ok new-project-id)
  )
)

;; Create a new task for a project
(define-public (create-task (project-id uint) (description (string-utf8 1000)) (reward uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
      (new-task-id (+ (var-get task-id-nonce) u1))
      (current-task-ids (default-to (list) (get task-ids (map-get? project-tasks { project-id: project-id }))))
    )
    (asserts! (is-eq tx-sender (get institution project)) err-owner-only)
    (map-set tasks
      { task-id: new-task-id }
      {
        project-id: project-id,
        description: description,
        reward: reward,
        status: "open"
      }
    )
    (map-set project-tasks
      { project-id: project-id }
      { task-ids: (unwrap! (as-max-len? (append current-task-ids new-task-id) u100) err-already-exists) }
    )
    (var-set task-id-nonce new-task-id)
    (ok new-task-id)
  )
)

;; Submit data for a task
(define-public (submit-data (task-id uint) (data (string-utf8 10000)))
  (let
    (
      (task (unwrap! (map-get? tasks { task-id: task-id }) err-not-found))
    )
    (asserts! (is-eq (get status task) "open") err-already-exists)
    (map-set user-contributions
      { user: tx-sender, task-id: task-id }
      { data: data }
    )
    (ok true)
  )
)

;; Validate data and distribute rewards
(define-public (validate-data (task-id uint) (user principal))
  (let
    (
      (task (unwrap! (map-get? tasks { task-id: task-id }) err-not-found))
      (project (unwrap! (map-get? projects { project-id: (get project-id task) }) err-not-found))
      (contribution (unwrap! (map-get? user-contributions { user: user, task-id: task-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get institution project)) err-owner-only)
    (map-set tasks
      { task-id: task-id }
      (merge task { status: "completed" })
    )
    (map-set user-rewards
      { user: user }
      { balance: (+ (default-to u0 (get balance (map-get? user-rewards { user: user }))) (get reward task)) }
    )
    (try! (ft-mint? citizen-science-token (get reward task) user))
    (ok true)
  )
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get task details
(define-read-only (get-task (task-id uint))
  (map-get? tasks { task-id: task-id })
)

;; Get tasks for a project
(define-read-only (get-project-tasks (project-id uint))
  (map-get? project-tasks { project-id: project-id })
)

;; Get user contribution
(define-read-only (get-user-contribution (user principal) (task-id uint))
  (map-get? user-contributions { user: user, task-id: task-id })
)

;; Get user rewards balance
(define-read-only (get-user-rewards (user principal))
  (default-to { balance: u0 } (map-get? user-rewards { user: user }))
)

