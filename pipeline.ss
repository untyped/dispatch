#lang scheme/base

(require "base.ss")

(require (unlib-in pipeline))

; Procedures -------------------------------------

; continue any ... -> ans
(define (eliminate-request-stage continue . args)
  (cond [(null? args)          (continue)]
        [(request? (car args)) (apply continue (cdr args))]
        [else                  (apply continue args)]))

; Provide statements -----------------------------

(provide/contract
 [eliminate-request-stage procedure?])
