#lang scheme/base

(require scheme/contract
         srfi/26/cut
         syntax/boundmap
         "base.ss")

(define info-cache (make-module-identifier-mapping))

(define-struct site-info (site-id controller-ids) #:transparent)

; syntax (listof syntax) -> boolean
(define (site-info-set! site-id controller-ids)
  (module-identifier-mapping-put! info-cache site-id (make-site-info site-id controller-ids)))

; syntax -> boolean
(define (site-info-set? id)
  (with-handlers ([exn? (lambda _ #f)])
    (module-identifier-mapping-get info-cache id) 
    #t))

; syntax -> site-info
(define (site-info-ref id [default (cut raise-syntax-error #f "No such site." #f id)])
  (module-identifier-mapping-get info-cache id default))

; Provide statements -----------------------------

(provide/contract
 [struct site-info ([site-id        identifier?]
                    [controller-ids (listof identifier?)])]
 [site-info-set!   (-> identifier? (listof identifier?) void?)]
 [site-info-set?   (-> identifier? boolean?)]
 [site-info-ref    (->* (identifier?) (procedure?) (or/c site-info? false/c))])
