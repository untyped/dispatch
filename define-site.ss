#lang scheme/base

(require (for-syntax scheme/base)
         "base.ss"
         (for-template "base.ss"))

(require (for-syntax scheme/provide-transform
                     "syntax-info.ss")
         "core.ss")

(require (for-syntax (unlib-in syntax)))

(define-syntax (define-site complete-stx)
  
  (define site-stx          #f) ; site
  (define controller-stxs null) ; in reverse order ...
  (define rule-stxs       null) ; in reverse order ...
  
  (define (parse-identifier stx)
    (syntax-case stx ()
      [(site rule ...)
       (begin (set! site-stx #'site)
              (parse-rules #'(rule ...)))]))
  
  (define (parse-rules stx)
    (syntax-case stx ()
      [()              (parse-finish)]
      [(rule rest ...) (parse-rule #'rule #'(rest ...))]))
  
  (define (parse-rule rule-stx other-stx)
    (syntax-case rule-stx ()
      [((term ...) controller)
       (identifier? #'controller)
       (begin (set! rule-stxs       (cons #'(make-rule (create-pattern term ...) controller) rule-stxs))
              (set! controller-stxs (cons #'controller controller-stxs))
              (parse-rules other-stx))]))
  
  (define (parse-finish)
    (with-syntax ([site-private     (make-id #f site-stx)]
                  [site             site-stx]
                  [(controller ...) (reverse controller-stxs)]
                  [(rule ...)       (reverse rule-stxs)])
      (syntax/loc complete-stx
        (begin
          
          (define controller (create-controller 'controller))
          ...
          
          (define site-private
            (make-site 'site (list rule ...)))
          
          (set-controller-site! controller site-private)
          ...
          
          (define-syntax site
            (let ([certify (syntax-local-certifier #t)])
              (site-info-add!
               (make-site-info
                (certify #'site)
                (certify #'site-private)
                (list (certify #'controller) ...)))))))))
  
  (syntax-case complete-stx ()
    [(_ id rule ...)
     (identifier? #'id)
     (parse-identifier #'(id rule ...))]))

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