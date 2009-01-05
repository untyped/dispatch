#lang scheme/base

(require scheme/contract
         scheme/match
         web-server/private/request-structs)

(require (planet "pipeline.ss" ("untyped" "unlib.plt" 3)))

; Procedures -------------------------------------

; (parameter (U request #f)) -> stage
(define (make-parameterize-request-stage param)
  (make-stage
   'parameterize-request
   (lambda (continue . args)
     (match args
       [(list) (continue)]
       [(list-rest (? request? request) other)
        (parameterize ([param request])
          (apply continue (cdr args)))]
       [else (apply continue args)]))))

; (thread-cell (U request #f)) -> stage
(define (make-thread-cell-request-stage cell)
  (make-stage
   'thread-cell-request
   (lambda (continue . args)
     (match args
       [(list) (continue)]
       [(list-rest (? request? request) other)
        (thread-cell-set! cell request)
        (apply continue (cdr args))]
       [else (apply continue args)]))))

; Provide statements -----------------------------

(provide/contract
 [make-parameterize-request-stage (-> (parameter/c (or/c request? false/c)) stage?)]
 [make-thread-cell-request-stage (-> thread-cell? stage?)])