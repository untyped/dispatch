#lang scheme/base

(require "base.ss")

(require syntax/boundmap)

; Variables --------------------------------------

(define-struct site-info
  (id private-id controller-ids)
  #:transparent
  #:property
  prop:procedure
  (lambda (info stx)
    (syntax-case stx ()
      [id (identifier? #'id) (site-info-private-id info)])))

(define info-cache (make-module-identifier-mapping))

; Procedures -------------------------------------

; site-info -> site-info
(define (site-info-add! info)
  (module-identifier-mapping-put! info-cache (site-info-id info) info)
  info)

; identifier -> boolean
(define (site-info-set? id)
  (with-handlers ([exn? (lambda _ #f)])
    (module-identifier-mapping-get info-cache id) 
    #t))

; identifier -> site-info
(define (site-info-ref id)
  (module-identifier-mapping-get info-cache id))

; Provide statements -----------------------------

(provide (struct-out site-info))

(provide/contract
 [site-info-add! (-> site-info? site-info?)]
 [site-info-set? (-> identifier? boolean?)]
 [site-info-ref  (-> identifier? (or/c site-info? #f))])
