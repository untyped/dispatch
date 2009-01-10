#lang scheme/base

(require scheme/contract
         scheme/match
         srfi/13/string
         srfi/26/cut)

(require (file "base.ss")
         (file "pattern.ss")
         (file "response.ss")
         (file "struct-private.ss"))

; Procedures -------------------------------------

;; (symbol (lsitof symbol) -> site controller ...)
(define (create-site site-id controller-ids)
  (define site (make-site site-id null null))
  (define controllers 
    (map (lambda (controller-id)
           (make-controller controller-id site null (create-undefined-body controller-id)))
         controller-ids))
  (set-site-controllers! site controllers)
  (values site controllers))

;; (site string -> (U controller #f) (U (list-of any) #f))
(define (site-controller/url site url)
  (let loop ([rules (site-rules site)])
    (match rules
      [(list) (values #f #f)]
      [(list-rest head tail)
       (let ([match (rule-match head url)])
         (if match
             (values (rule-controller head) match)
             (loop tail)))])))

;; (controller any ... -> string)
(define (controller-url controller . args)
  (or (ormap (lambda (rule)
               (pattern->string (rule-pattern rule) args))
             (site-rules/controller (controller-site controller) controller))
      (raise-exn exn:fail:dispatch 
        (format "No dispatch rules for controller ~a with arity ~a" (controller-id controller) (length args)))))

;; (controller -> boolean)
(define (controller-defined? controller)
  (not (undefined-body? (controller-body controller))))

; Helpers ----------------------------------------

;; (site controller -> (listof rule))
(define (site-rules/controller site controller)
  (filter (lambda (rule)
            (eq? (rule-controller rule) controller))
          (site-rules site)))

;; (rule string -> (U (list-of any) #f))
(define (rule-match rule url)
  (define pattern (rule-pattern rule))
  (if pattern
      (pattern-match pattern url)
      #f))

;; (struct (request any ... -> any))
(define-struct undefined-body
  (body)
  #:property prop:procedure 0)

;; (symbol -> (request -> response))
(define (create-undefined-body id)
  (make-undefined-body
   (lambda (request . args)
     (make-undefined-response request id args))))

; Provide statements --------------------------- 

(provide/contract
 [create-site           (-> symbol? (listof symbol?) (values site? (listof controller?)))]
 [site-controller/url   (-> site? string? (values (or/c controller? false/c) (or/c list? false/c)))]
 [controller-url        (->* (controller?) () #:rest any/c string?)]
 [controller-defined?   (-> controller? boolean?)])
   