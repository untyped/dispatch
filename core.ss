#lang scheme/base

(require "base.ss")

(require scheme/list
         scheme/string
         (mirrors-in)
         (unlib-in string))

; Struct types -----------------------------------

(define-struct site
  (id rules controllers not-found-proc)
  #:property
  prop:custom-write
  (lambda (site out write?)
    ((if write? write display)
     (vector 'site (site-id site))
     out))
  #:transparent)

(define-struct controller
  (id
   [site               #:mutable]
   [wrapper-proc       #:mutable]
   [body-proc          #:mutable]
   [access-proc        #:mutable]
   [access-denied-proc #:mutable]
   [requestless?       #:mutable])
  #:property
  prop:custom-write
  (lambda (controller out write?)
    ((if write? write display)
     (vector 'controller (controller-id controller))
     out))
  #:property
  prop:procedure
  (lambda (controller . args)
    (apply (controller-wrapper-proc controller) controller args))
  #:transparent)

; (struct string (string -> any) (any -> string))
(define-struct arg (pattern decoder encoder) #:transparent)

; (struct (-> regexp) (listof arg) (listof (U string arg)))
(define-struct pattern (regexp-maker args elements) #:transparent)

; (struct pattern controller)
(define-struct rule (pattern controller) #:transparent)

; Constructors -----------------------------------

; symbol boolean -> controller
(define (create-controller id requestless?)
  (letrec ([controller (make-controller
                        id
                        #f
                        (lambda (controller . args) (apply (default-controller-wrapper) controller args))
                        (lambda args (apply (default-controller-undefined-responder) controller args))
                        (lambda args (apply (default-access-procedure) controller args))
                        (lambda args (apply (default-access-denied-responder) controller args))
                        requestless?)])
    controller))

; (U string arg) ... -> pattern
(define (create-pattern . elements)
  (make-pattern (make-regexp-maker elements)
                (filter arg? elements)
                elements))

; Configuration --------------------------------

(define-enum link-formats     (mirrors sexp sexps))
(define-enum link-substitutes (hide span body))

; (parameter link-format)
(define default-link-format
  (make-parameter (link-formats mirrors)))

; (parameter link-format)
(define default-link-substitute
  (make-parameter (link-substitutes body)))

; controller any ... -> any
(define (plain-controller-wrapper controller . args)
  (if (apply (controller-access-proc controller) args)
      (apply (controller-body-proc controller) args)
      (apply (controller-access-denied-proc controller) args)))

; (parameter ((any ... -> any) any ... -> any))
; Initialised in response.ss.
(define default-controller-wrapper
  (make-parameter plain-controller-wrapper))

; (parameter (any ... -> boolean))
; Initialised in response.ss.
(define default-access-procedure
  (make-parameter (lambda _ #t)))

; (parameter (controller any ... -> response))
; Initialised in response.ss.
(define default-access-denied-responder
  (make-parameter (lambda _ (error "not initialised"))))

; (parameter (controller any ... -> response))
; Initialised in response.ss.
(define default-controller-undefined-responder
  (make-parameter (lambda _ (error "not initialised"))))

; Helpers ----------------------------------------

; (listof (U string (-> string) arg)) ... -> string
(define (make-regexp-maker elements)
  (let ([parts `("^"
                 ,@(for/list ([elem (in-list elements)])
                     (match elem
                       [(? string?)    (regexp-quote elem)]
                       [(? arg?)       (string-append "(" (arg-pattern elem) ")")]
                       [(? procedure?) (lambda () (regexp-quote (elem)))]))
                 "\\/?$")]) ; optional trailing slash
    (lambda ()
      (pregexp (apply string-append
                      (for/list ([part (in-list parts)])
                        (if (procedure? part)
                            (part)
                            part)))))))

; Provide statements -----------------------------

(provide link-formats
         link-substitutes)

(provide/contract
 [struct site                            ([id                 symbol?]
                                          [rules              (listof rule?)]
                                          [controllers        (listof controller?)]
                                          [not-found-proc     (-> request? response/c)])]
 [struct controller                      ([id                 symbol?]
                                          [site               site?]
                                          [wrapper-proc       (or/c procedure? #f)]
                                          [body-proc          procedure?]
                                          [access-proc        procedure?]
                                          [access-denied-proc procedure?]
                                          [requestless?       boolean?])]
 [struct arg                             ([pattern            string?]
                                          [decoder            procedure?]
                                          [encoder            procedure?])]
 [struct pattern                         ([regexp-maker       (-> regexp?)]
                                          [args               (listof arg?)]
                                          [elements           (listof (or/c string? procedure? arg?))])]
 [struct rule                            ([pattern            pattern?]
                                          [controller         controller?])]
 [create-controller                      (-> symbol? boolean? controller?)]
 [create-pattern                         (->* () () #:rest (listof (or/c string? arg? procedure?)) pattern?)]
 [default-link-format                    (parameter/c (enum-value/c link-formats))]
 [default-link-substitute                (parameter/c (enum-value/c link-substitutes))]
 [plain-controller-wrapper               (->* (controller?) () #:rest any/c any)]
 [default-controller-wrapper             (parameter/c procedure?)]
 [default-access-procedure               (parameter/c procedure?)]
 [default-access-denied-responder        (parameter/c procedure?)]
 [default-controller-undefined-responder (parameter/c procedure?)])
