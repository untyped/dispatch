#lang scheme/base

(require scheme/contract
         scheme/match
         web-server/private/request-structs)

(require (planet "pipeline.ss" ("untyped" "unlib.plt" 3)))

; Procedures -------------------------------------

; continue any ... -> ans
(define (eliminate-request-stage continue . args)
  (cond [(null? args)          (continue)]
        [(request? (car args)) (apply continue (cdr args))]
        [else                  (apply continue args)]))

; Provide statements -----------------------------

(provide/contract
 [eliminate-request-stage procedure?])