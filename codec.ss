#lang scheme/base

(require "base.ss")

(require net/uri-codec
         (only-in srfi/13 string-join)
         "core.ss")

; Accessors --------------------------------------

; site string -> any
(define (site-dispatch site request)
  (let ([url-string (clean-request-url request)])
    (match-let ([(list-rest controller args) (site-decode site url-string)])
      (if controller
          (if (controller-requestless? controller)
              (apply controller args)
              (apply controller request args))
          ((site-not-found-proc site) request)))))

; controller any ... -> boolean
(define (controller-access? controller . args)
  (with-handlers ([exn? (lambda (exn)
                          (raise (make-exn:fail (format "error determining access for ~s:~n~a"
                                                        (cons (controller-id controller) args)
                                                        (exn-message exn))
                                                (exn-continuation-marks exn))))])
    (let ([ans (apply (controller-access-proc controller) args)])
      (unless (boolean? ans)
        (printf "Warning: access predicate for ~a returned non-boolean value: ~s"
                (controller-id controller)
                ans))
      (and ans #t))))

; controller any ... -> string
(define (controller-url controller . args)
  (or (for/or ([rule (in-list (site-rules (controller-site controller)))])
        (and (eq? (rule-controller rule) controller)
             (pattern-encode (rule-pattern rule) args)))
      (error "no url for controller" (cons controller args))))

;  controller
;  [#:body    (U xml sexp #f)]
;  [#:id      (U string symbol #f)]
;  [#:class   (U string symbol #f)]
;  [#:classes (listof (U string symbol))]
;  [#:target  (U string #f)]
;  [#:title   (U string #f)]
;  [#:format  link-format]
;  [#:else    (U link-substitute html)]
; ->
;  (U xml sexp (listof sexp))
(define (controller-link
         controller
         #:body    [body        #f]
         #:id      [id          #f]
         #:class   [class       #f]
         #:classes [classes     (if class (list class) null)]
         #:title   [title       #f]
         #:target  [target      #f]
         #:anchor  [anchor      #f]
         #:format  [link-format (default-link-format)]
         #:else    [substitute  (default-link-substitute)]
         . args)
  (let* ([requestless? (controller-requestless?  controller)]
         [access?      (apply controller-access? controller args)]
         [plain–href   (if (controller-requestless? controller)
                           (apply controller-url controller args)
                           (apply controller-url controller (cdr args)))]
         [href         (if anchor
                           (format "~a#~a" plain–href anchor)
                           plain–href)]
         [body         (cond [body body]
                             [(eq? link-format 'sexps) (list href)]
                             [else href])]
         [id           (and id (string+symbol->string id))]
         [class        (and (pair? classes) (string-join (map string+symbol->string classes) " "))])
    (if access?
        (enum-case link-formats link-format
          [(mirrors) (xml (a (@ [href ,href]
                                ,(opt-xml-attr id)
                                ,(opt-xml-attr class)
                                ,(opt-xml-attr target)
                                ,(opt-xml-attr title)) ,body))]
          [(sexp)    `(a ([href ,href]
                          ,@(opt-attr-list id)
                          ,@(opt-attr-list class)
                          ,@(opt-attr-list target)
                          ,@(opt-attr-list title)) ,body)]
          [(sexps)   `((a ([href ,href]
                           ,@(opt-attr-list id)
                           ,@(opt-attr-list class)
                           ,@(opt-attr-list target)
                           ,@(opt-attr-list title)) ,@body))])
        (enum-case link-formats link-format
          [(mirrors) (enum-case link-substitutes substitute
                       [(hide) (xml)]
                       [(span) (xml (span (@ ,(opt-xml-attr id)
                                             ,(opt-xml-attr class class (format "no-access-link ~a" class))
                                             ,(opt-xml-attr title)) ,body))]
                       [(body) (xml ,body)]
                       [else   substitute])]
          [(sexp)    (enum-case link-substitutes substitute
                       [(hide) '(span)]
                       [(span) `(span (,@(opt-attr-list id)
                                       ,@(opt-attr-list class class (format "no-access-link ~a" class))
                                       ,@(opt-attr-list title)) ,body)]
                       [(body) body]
                       [else   substitute])]
          [(sexps)   (enum-case link-substitutes substitute
                       [(hide) null]
                       [(span) `((span (,@(opt-attr-list id)
                                        ,@(opt-attr-list class class (format "no-access-link ~a" class))
                                        ,@(opt-attr-list title)) ,@body))]
                       [(body) body]
                       [else   substitute])]))))

; Patterns ---------------------------------------

; site string -> (cons controller list)
(define (site-decode site url-string)
  (or (for/or ([rule (in-list (site-rules site))])
        (let ([match (pattern-decode (rule-pattern rule) url-string)])
          (and match (cons (rule-controller rule) match))))
      (list #f #f)))

; pattern string -> (U list #f)
(define (pattern-decode pattern url-string)
  (let* ([url-string url-string]
         [regexp     ((pattern-regexp-maker pattern))]
         [matches    (regexp-match regexp url-string)]
         [decoded    (and matches
                          (= (length (cdr matches)) 
                             (length (pattern-args pattern)))
                          (for/list ([arg   (in-list (pattern-args pattern))]
                                     [match (in-list (cdr matches))])
                            ((arg-decoder arg) match)))])
    decoded))

; pattern list -> (U string #f)
(define (pattern-encode pattern args)
  (and (= (length (pattern-args pattern)) (length args))
       (apply string-append
              (let loop ([elems (pattern-elements pattern)]
                         [args  args])
                (match elems
                  [(list) null]
                  [(list elem elem-rest ...)
                   (match elem
                     [(? string?)    (cons elem   (loop elem-rest args))]
                     [(? procedure?) (cons (elem) (loop elem-rest args))]
                     [(? arg?)       (cons ((arg-encoder elem) (car args))
                                           (loop elem-rest (cdr args)))])])))))

; request -> string
(define (clean-request-url request)
  (string-append "/" (string-join (map (compose uri-encode path/param-path)
                                       (url-path (request-uri request)))
                                  "/")))

; (_ id)
; (_ boolean-expr id)
; (_ boolean-expr id expr)
(define-syntax opt-attr-list
  (syntax-rules ()
    [(_ test id expr) (if test `([id ,expr]) null)]
    [(_ test id) (opt-attr-list test id id)]
    [(_ id) (opt-attr-list id id id)]))

; (U string symbol) -> string
(define (string+symbol->string val)
  (if (string? val)
      val
      (symbol->string val)))

; Provides ---------------------------------------

(provide/contract
 [site-dispatch      (-> site? request? any)]
 [controller-access? (->* (controller?) () #:rest any/c boolean?)]
 [controller-url     (->* (controller?) () #:rest any/c (or/c string? #f))]
 [controller-link    (->* (controller?)
                          (#:body (or/c xml+quotable? pair? null? #f)
                                  #:id      (or/c symbol? string? #f)
                                  #:class   (or/c symbol? string? #f)
                                  #:classes (listof (or/c symbol? string?))
                                  #:target  (or/c string? #f)
                                  #:title   (or/c string? #f)
                                  #:format  (enum-value/c link-formats)
                                  #:anchor  (or/c string? #f)
                                  #:else    any/c)
                          #:rest any/c
                          any)])
