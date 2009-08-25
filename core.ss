#lang scheme/base

(require "base.ss")

(require scheme/list
         scheme/string
         (mirrors-in)
         (unlib-in enumeration string))

; Struct types -----------------------------------

(define-struct site
  (id rules)
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
   [body-proc          #:mutable]
   [access-proc        #:mutable]
   [access-denied-proc #:mutable])
  #:property
  prop:custom-write
  (lambda (controller out write?)
    ((if write? write display)
     (vector 'controller (controller-id controller))
     out))
  #:property
  prop:procedure
  (lambda (controller request . args)
    (apply
     (current-controller-wrapper)
     (lambda (controller request . args)
       (if (apply (controller-access-proc        controller) args)
           (apply (controller-body-proc          controller) request args)
           (apply (controller-access-denied-proc controller) request args)))
     controller
     request
     args))
  #:transparent)

; (struct string (string -> any) (any -> string))
(define-struct arg (pattern decoder encoder) #:transparent)

; (struct (-> regexp) (listof arg) (listof (U string arg)))
(define-struct pattern (regexp-maker args elements) #:transparent)

; (struct pattern controller)
(define-struct rule (pattern controller) #:transparent)

; Constructors -----------------------------------

; symbol -> controller
(define (create-controller id)
  (letrec ([ans (make-controller
                 id
                 #f
                 (lambda (request . args)
                   (apply (current-controller-undefined-responder) ans request args))
                 (lambda _ #t)
                 (lambda (request . args)
                   (apply (current-access-denied-responder) ans request args)))])
    ans))

; (U string arg) ... -> pattern
(define (create-pattern . elements)
  (make-pattern (make-regexp-maker elements)
                (filter arg? elements)
                elements))

; Accessors ------------------------------------

; site -> (listof controller)
(define (site-controllers site)
  (remove-duplicates (map rule-controller (site-rules site))))

; Configuration --------------------------------

(define-enum dispatch-link-formats     (mirrors sexp sexps))
(define-enum dispatch-link-substitutes (hide span body))

; (parameter dispatch-link-format)
(define current-link-format
  (make-parameter (dispatch-link-formats mirrors)))

; (parameter (controller request any ... -> response))
; Initialised in response.ss.
(define current-access-denied-responder
  (make-parameter (lambda _ (error "not initialised"))))

; (parameter (controller request any ... -> response))
; Initialised in response.ss.
(define current-controller-undefined-responder
  (make-parameter (lambda _ (error "not initialised"))))

; (parameter ((controller request any ... -> any)
;             controller request any ... -> any))
; Initialised in response.ss.
(define current-controller-wrapper
  (make-parameter (lambda (continue controller request . args)
                    (apply continue controller request args))))

; Helpers ----------------------------------------

; (listof (U string (-> string) arg)) ... -> string
(define (make-regexp-maker elements)
  (let ([parts `("^" ,@(for/list ([elem (in-list elements)])
                         (match elem
                           [(? string?)    (string-append "\\/" (regexp-quote elem))]
                           [(? arg?)       (string-append "\\/(" (arg-pattern elem) ")")]
                           [(? procedure?) (lambda () (string-append "\\/" (regexp-quote (elem))))]))
                      "\\/?$")]) ; optional trailing slash
    (lambda ()
      (pregexp (apply string-append
                      (for/list ([part (in-list parts)])
                        (if (procedure? part)
                            (part)
                            part)))))))

; Provide statements -----------------------------

(provide dispatch-link-formats
         dispatch-link-substitutes)

(provide/contract
 [struct site                            ([id                 symbol?]
                                          [rules              (listof rule?)])]
 [struct controller                      ([id                 symbol?]
                                          [site               site?]
                                          [body-proc          procedure?]
                                          [access-proc        procedure?]
                                          [access-denied-proc procedure?])]
 [struct arg                             ([pattern            string?]
                                          [decoder            procedure?]
                                          [encoder            procedure?])]
 [struct pattern                         ([regexp-maker       (-> regexp?)]
                                          [args               (listof arg?)]
                                          [elements           (listof (or/c string? procedure? arg?))])]
 [struct rule                            ([pattern            pattern?]
                                          [controller         controller?])]
 [create-controller                      (-> symbol? controller?)]
 [create-pattern                         (->* () () #:rest (listof (or/c string? arg? procedure?)) pattern?)]
 [site-controllers                       (-> site? (listof controller?))]
 [current-link-format                    (parameter/c (or/c 'mirrors 'sexp 'sexps))]
 [current-controller-undefined-responder (parameter/c (->* (controller? request?) () #:rest any/c any))]
 [current-access-denied-responder        (parameter/c (->* (controller? request?) () #:rest any/c any))]
 [current-controller-wrapper             (parameter/c (->* (procedure? controller? request?) () #:rest any/c any))])
