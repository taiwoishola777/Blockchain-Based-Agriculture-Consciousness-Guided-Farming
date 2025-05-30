;; Plant Communication Contract
;; Facilitates farmer-plant consciousness exchange

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-invalid-session (err u301))
(define-constant err-session-exists (err u302))

;; Data structures
(define-map communication-sessions uint
  {
    farmer: principal,
    plant-type: (string-ascii 50),
    session-date: uint,
    consciousness-frequency: uint,
    communication-quality: uint,
    plant-response-score: uint,
    session-duration: uint,
    insights-gained: (string-ascii 500)
  })

(define-map farmer-plant-bonds principal
  {
    total-sessions: uint,
    average-communication-quality: uint,
    strongest-plant-connection: (string-ascii 50),
    consciousness-evolution: uint
  })

(define-map plant-consciousness-data (string-ascii 50)
  {
    total-interactions: uint,
    average-response-score: uint,
    optimal-frequency: uint,
    growth-correlation: uint
  })

(define-data-var session-counter uint u0)

;; Public functions
(define-public (start-communication-session
  (plant-type (string-ascii 50))
  (consciousness-frequency uint)
  (session-duration uint))
  (let ((farmer tx-sender)
        (session-id (+ (var-get session-counter) u1)))

    (asserts! (<= consciousness-frequency u100) err-invalid-session)
    (asserts! (> session-duration u0) err-invalid-session)

    (map-set communication-sessions session-id
      {
        farmer: farmer,
        plant-type: plant-type,
        session-date: block-height,
        consciousness-frequency: consciousness-frequency,
        communication-quality: u0,
        plant-response-score: u0,
        session-duration: session-duration,
        insights-gained: ""
      })

    (var-set session-counter session-id)
    (ok session-id)))

(define-public (complete-communication-session
  (session-id uint)
  (communication-quality uint)
  (plant-response-score uint)
  (insights-gained (string-ascii 500)))
  (let ((farmer tx-sender)
        (session-data (unwrap-panic (map-get? communication-sessions session-id))))

    (asserts! (is-eq farmer (get farmer session-data)) err-invalid-session)
    (asserts! (<= communication-quality u100) err-invalid-session)
    (asserts! (<= plant-response-score u100) err-invalid-session)

    ;; Update session
    (map-set communication-sessions session-id
      (merge session-data
        {
          communication-quality: communication-quality,
          plant-response-score: plant-response-score,
          insights-gained: insights-gained
        }))

    ;; Update farmer bonds
    (let ((current-bonds (default-to
            {total-sessions: u0, average-communication-quality: u0, strongest-plant-connection: "", consciousness-evolution: u0}
            (map-get? farmer-plant-bonds farmer))))
      (map-set farmer-plant-bonds farmer
        {
          total-sessions: (+ (get total-sessions current-bonds) u1),
          average-communication-quality: (/ (+ (* (get average-communication-quality current-bonds) (get total-sessions current-bonds)) communication-quality) (+ (get total-sessions current-bonds) u1)),
          strongest-plant-connection: (get plant-type session-data),
          consciousness-evolution: (+ (get consciousness-evolution current-bonds) u1)
        }))

    ;; Update plant consciousness data
    (let ((plant-data (default-to
            {total-interactions: u0, average-response-score: u0, optimal-frequency: u0, growth-correlation: u0}
            (map-get? plant-consciousness-data (get plant-type session-data)))))
      (map-set plant-consciousness-data (get plant-type session-data)
        {
          total-interactions: (+ (get total-interactions plant-data) u1),
          average-response-score: (/ (+ (* (get average-response-score plant-data) (get total-interactions plant-data)) plant-response-score) (+ (get total-interactions plant-data) u1)),
          optimal-frequency: (get consciousness-frequency session-data),
          growth-correlation: (+ (get growth-correlation plant-data) u1)
        }))

    (ok true)))

;; Read-only functions
(define-read-only (get-session-info (session-id uint))
  (map-get? communication-sessions session-id))

(define-read-only (get-farmer-bonds (farmer principal))
  (map-get? farmer-plant-bonds farmer))

(define-read-only (get-plant-consciousness-data (plant-type (string-ascii 50)))
  (map-get? plant-consciousness-data plant-type))

(define-read-only (get-total-sessions)
  (var-get session-counter))
