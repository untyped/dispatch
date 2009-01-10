#lang scheme/base

(require scheme/contract
         scheme/match
         web-server/http/request-structs
         (planet untyped/unlib:3/pipeline))

; Procedures -------------------------------------

; continue any ... -> ans
(define (eliminate-request-stage continue . args)
  (cond [(null? args)          (continue)]
        [(request? (car args)) (apply continue (cdr args))]
        [else                  (apply continue args)]))

; Provide statements -----------------------------

(provide/contract
 [eliminate-request-stage procedure?])
