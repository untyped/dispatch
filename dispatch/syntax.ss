#lang scheme/base

(require (for-syntax scheme/base
                     scheme/match
                     scheme/pretty
                     scheme/provide-transform
                     srfi/26/cut
                     (planet untyped/unlib/syntax)
                     (file "base.ss")
                     (file "site-info.ss"))
         scheme/pretty
         (file "base.ss")
         (file "site-info.ss")
         (file "struct.ss"))

; Syntax -----------------------------------------

;; (syntax -> syntax (listof syntax))
(define-for-syntax (parse-site-definition original-stx)
  
  ;; identifier-syntax
  (define site-id-stx #f)
  
  ;; (listof identifier-syntax)
  (define controller-id-stxs null)
  
  ;; (listof syntax)
  (define rule-stxs null)
  
  ;; (U syntax #f)
  (define rule-not-found-stx #f)
  
  ;; (syntax -> syntax)
  (define (resolve-controller-id! id)
    (or (ormap (lambda (id2)
                 (if (eq? (syntax->datum id) (syntax->datum id2)) id2 #f))
               controller-id-stxs)
        (begin (set! controller-id-stxs (cons id controller-id-stxs))
               id)))
  
  ;; (syntax (listof syntax) -> syntax)
  (define (parse-at-rules dispatch-stx args-stxs)
    (for-each parse-at-rule (syntax->list dispatch-stx))
    (parse-at-site-keywords args-stxs))
  
  ;; (syntax -> void)
  (define (parse-at-rule stx)
    (syntax-case* stx (url) symbolic-identifier=?
      [((url arg ...) controller)
       (identifier? #'controller)
       (set! rule-stxs (cons #`(make-rule (make-pattern arg ...) #,(resolve-controller-id! #'controller)) rule-stxs))]))
  
  ;; ((listof syntax) -> syntax)
  (define (parse-at-site-keywords args-stxs)
    (match args-stxs
      [(list) (void)]
      [(list-rest kw-stx value-stx args-stxs)
       (match (syntax->datum kw-stx)
         ['#:rule-not-found    (set! rule-not-found-stx value-stx)]
         ['#:other-controllers (for-each resolve-controller-id! (syntax->list value-stx))])
       (parse-at-site-keywords args-stxs)])
    (parse-at-end))
  
  ;; (-> syntax)
  (define (parse-at-end)
    (with-syntax ([site             site-id-stx]
                  [(controller ...) (reverse controller-id-stxs)]
                  [(rule ...)       (reverse rule-stxs)])
      (site-info-set! #'site (syntax->list #'(controller ...)))
      (values (quasisyntax/loc original-stx
                (define-values (site controller ...)
                  (let-values ([(site controllers) (make-site 'site '(controller ...))])
                    (let-values ([(controller ...) (apply values controllers)])
                      (set-site-rules! site (list rule ...))
                      #,@(if rule-not-found-stx
                             (list #`(set-site-rule-not-found! site #,rule-not-found-stx))
                             null)
                      (values site controller ...)))))
              (cons #'site (syntax->list #'(controller ...))))))
  
  ;; syntax
  (syntax-case original-stx ()
    [(_ site-id rules arg ...)
     (identifier? #'site-id)
     (begin (set! site-id-stx #'site-id)
            (parse-at-rules #'rules (syntax->list #'(arg ...))))]))

;; syntax (_ id ((pattern id) ...) [#:other-controllers (id ...)])
(define-syntax (define-site stx)
  (define-values (definition-stx id-stxs)
    (parse-site-definition stx))
  #`(begin #,definition-stx))

;; syntax (_ id ((pattern id) ...) [#:other-controllers (id ...)])
(define-syntax (define/provide-site stx)
  (define-values (definition-stx id-stxs)
    (parse-site-definition stx))
  #`(begin (begin #,definition-stx (provide #,@id-stxs))))

; (_ site-id)
(define-syntax site-out
  (make-provide-transformer
   (lambda (stx modes)
     ; syntax -> export
     (define (create-export id-stx)
       (make-export id-stx (syntax->datum id-stx) 0 #f id-stx))
     ; (listof export)
     (syntax-case stx ()
       [(_ id)
        (let ([controllers (site-info-controller-ids (site-info-ref #'id (cut raise-syntax-error #f "No such site." stx #'id)))])
          (map create-export (cons #'id controllers)))]))))

;; syntax (_ identifier (list-of stage) (any ... -> void))
(define-syntax (define-controller stx)
  (syntax-case stx ()
    [(_ (id arg ...) expr ...)
     (with-syntax ([pipeline-id (make-id #'id #'id '-controller-pipeline)]
                   [body-id     (make-id #'id #'id '-controller-body)])
       #'(define _
           (if (controller-defined? id)
               (raise-exn exn:fail:dispatch
                 (format "Controller ~a has already been defined." 'id))
               (let ([pipeline-id null] [body-id (lambda (arg ...) expr ...)])
                 (set-controller-pipeline! id pipeline-id)
                 (set-controller-body! id body-id)))))]
    [(_ id pipeline body)
     (with-syntax ([pipeline-id (make-id #'id #'id '-controller-pipeline)]
                   [body-id     (make-id #'id #'id '-controller-body)])
       #'(define _
           (if (controller-defined? id)
               (raise-exn exn:fail:dispatch
                 (format "Controller ~a has already been defined." 'id))
               (let ([pipeline-id pipeline] [body-id body])
                 (set-controller-pipeline! id pipeline-id)
                 (set-controller-body! id body-id)))))]))

; Provide statements -----------------------------

(provide define-site
         define/provide-site
         define-controller
         site-out)