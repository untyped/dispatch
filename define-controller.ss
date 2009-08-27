#lang scheme/base

(require (for-syntax scheme/base
                     "base.ss")
         "base.ss"
         (for-template scheme/base))

(require (for-syntax (unlib-in syntax))
         "core.ss")

(define-syntax (define-controller complete-stx)
  
  (define id-stx           #f)
  (define args-stx         #f)
  (define rest-stx         #f)
  (define wrapper-proc-stx #'#f)
  (define access-proc-stx  #'#f)
  (define denied-proc-stx  #'#f)
  (define requestless-stx  #'(requestless-controllers?))
  
  (define (parse-keywords stx)
    (syntax-case stx ()
      [(#:wrapper-proc proc other ...)
       (begin (set! wrapper-proc-stx #'proc)
              (parse-keywords #'(other ...)))]
      [(#:access? expr other ...)
       (begin (set! access-proc-stx
                    (with-syntax ([(arg ...) args-stx])
                      #'(lambda (arg ...) expr)))
              (parse-keywords #'(other ...)))]
      [(#:access-proc proc other ...)
       (begin (set! access-proc-stx #'proc)
              (parse-keywords #'(other ...)))]
      [(#:denied-proc proc other ...)
       (begin (set! denied-proc-stx #'proc)
              (parse-keywords #'(other ...)))]
      [(#:requestless? val other ...)
       (begin (set! requestless-stx #'val)
              (parse-keywords #'(other ...)))]
      [rest   (parse-body #'rest)]))
  
  (define (parse-body body-stx)
    (with-syntax ([id             id-stx]
                  [(arg ...)      args-stx]
                  [(expr ...)     body-stx]
                  [body-id        (make-id id-stx id-stx '-body)]
                  [access-id      (make-id id-stx id-stx '-access?)]
                  [denied-id      (make-id id-stx id-stx '-access-denied)]
                  [wrapper-id     (make-id id-stx id-stx '-wrapper)]
                  [requestless-id (make-id id-stx id-stx '-requestless?)]
                  [wrapper-proc   wrapper-proc-stx]
                  [access-proc    access-proc-stx]
                  [denied-proc    denied-proc-stx]
                  [requestless?   requestless-stx])
      (quasisyntax/loc complete-stx
        (let ([body-id        (lambda (arg ...) expr ...)]
              [wrapper-id     wrapper-proc]
              [access-id      access-proc]
              [denied-id      denied-proc]
              [requestless-id requestless?])
          (set-controller-body-proc! id body-id)
          (when wrapper-id
            (set-controller-wrapper-proc! id wrapper-id))
          (when access-id
            (set-controller-access-proc! id access-id))
          (when denied-id
            (set-controller-access-denied-proc! id denied-id))
          (set-controller-requestless?! id requestless-id)))))
  
  (syntax-case complete-stx ()
    [(_ (id arg ...) keyword+expr ...)
     (identifier? #'id)
     (begin (set! id-stx      #'id)
            (set! args-stx    #'(arg ...))
            (parse-keywords   #'(keyword+expr ...)))]))

; Provide statements -----------------------------

(provide define-controller)