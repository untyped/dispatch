#lang scheme/base

(require (for-syntax scheme/base
                     "base.ss")
         "base.ss"
         (for-template scheme/base))

(require (for-syntax (unlib-in syntax))
         "core.ss")

(define-syntax (define-controller complete-stx)
  
  (define id-stx          #f)
  (define request-stx     #f)
  (define args-stx        #f)
  (define rest-stx        #f)
  (define access-expr-stx #'#t)
  
  (define (parse-keywords stx)
    (syntax-case stx ()
      [(#:access? expr other ...)
       (begin (set! access-expr-stx #'expr)
              (parse-keywords #'(other ...)))]
      [rest   (parse-body #'rest)]))
  
  (define (parse-body body-stx)
    (with-syntax ([id             id-stx]
                  [access-id      (make-id id-stx id-stx '-access?)]
                  [(expr ...)     body-stx]
                  [access-expr    access-expr-stx]
                  [(arg ...)      args-stx])
      (quasisyntax/loc complete-stx
        (begin (set-controller-body-proc!
                id
                (let ([id (lambda (request arg ...) expr ...)])
                  id))
               (set-controller-access-proc!
                id
                (let ([access-id (lambda (arg ...) access-expr)])
                  access-id))))))
  
  (syntax-case complete-stx ()
    [(_ (id request . args) keyword+expr ...)
     (identifier? #'id)
     (begin (set! id-stx      #'id)
            (set! request-stx #'request)
            (set! args-stx    #'args)
            (parse-keywords   #'(keyword+expr ...)))]))

; Provide statements -----------------------------

(provide define-controller)