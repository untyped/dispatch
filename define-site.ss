#lang scheme/base

(require "base.ss")

(require (for-syntax scheme/base
                     scheme/list
                     scheme/provide-transform
                     (unlib-in syntax)
                     "syntax-info.ss")
         web-server/dispatchers/dispatch
         "core.ss"
         (for-template "base.ss"))

(define-syntax (define-site complete-stx)
  
  (define id-stx              #f)   ; id
  (define controller-stxs     null) ; in reverse order ...
  (define rule-stxs           null) ; in reverse order ...
  (define requestless-stx     #'#f)
  (define not-found-stx       #'(lambda (request) (next-dispatcher)))
  
  (define (parse-identifier stx)
    (syntax-case stx ()
      [(id (rule ...) kw ...)
       (begin (set! id-stx #'id)
              (parse-rules #'((rule ...) kw ...)))]))
  
  (define (parse-rules stx)
    (syntax-case stx ()
      [(() kw ...)              (parse-keywords #'(kw ...))]
      [((rule rest ...) kw ...) (parse-rule #'rule #'((rest ...) kw ...))]))
  
  (define (parse-rule rule-stx other-stx)
    (syntax-case rule-stx ()
      [((term ...) controller)
       (identifier? #'controller)
       (begin (set! rule-stxs       (cons #'(make-rule (create-pattern term ...) controller) rule-stxs))
              (set! controller-stxs (cons #'controller controller-stxs))
              (parse-rules other-stx))]))
  
  (define (parse-keywords stx)
    (syntax-case stx ()
      [() (parse-finish)]
      [(#:requestless? val rest ...)
       (begin (set! requestless-stx #'val)
              (parse-keywords #'(rest ...)))]
      [(#:not-found expr rest ...)
       (begin (set! not-found-stx #'expr)
              (parse-keywords #'(rest ...)))]
      [(#:other-controllers (id ...) rest ...)
       (if (andmap identifier? (syntax->list #'(id ...)))
           (begin (set! controller-stxs (append (reverse (syntax->list #'(id ...))) controller-stxs))
                  (parse-keywords #'(rest ...)))
           (raise-syntax-error #f "#:other-controllers must be a list of identifiers" #'(id ...) complete-stx))]))
  
  (define (parse-finish)
    (with-syntax ([id-private     (make-id #f id-stx)]
                  [id             id-stx]
                  [(controller ...) (remove-duplicates (reverse controller-stxs) symbolic-identifier=?)]
                  [(rule ...)       (reverse rule-stxs)]
                  [requestless-expr requestless-stx]
                  [not-found-proc   not-found-stx])
      (syntax/loc complete-stx
        (begin
          
          (define requestless? requestless-expr)
          
          (define controller (create-controller 'controller requestless?))
          ...
          
          (define id-private
            (make-site
             'id
             (list rule ...)
             (list controller ...)
             not-found-proc))
          
          (set-controller-site! controller id-private)
          ...
          
          (define-syntax id
            (let ([certify (syntax-local-certifier #t)])
              (site-info-add!
               (make-site-info
                (certify #'id)
                (certify #'id-private)
                (list (certify #'controller) ...)))))))))
  
  (syntax-case complete-stx ()
    [(_ id (rule ...) kw ...)
     (identifier? #'id)
     (parse-identifier #'(id (rule ...) kw ...))]))

; (_ id)
(define-syntax site-out
  (make-provide-transformer
   (lambda (stx modes)
     ; syntax -> export
     (define (create-export id-stx)
       (make-export id-stx (syntax->datum id-stx) 0 #f id-stx))
     ; (listof export)
     (syntax-case stx ()
       [(_ id)
        (let ([info (site-info-ref #'id)])
          (map create-export (list* (site-info-id info)
                                    (site-info-controller-ids info))))]))))

; Provide statements -----------------------------

(provide define-site
         site-out)