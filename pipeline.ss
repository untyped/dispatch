#lang scheme/base

(require scheme/contract
         web-server/private/request-structs)

(require (planet "pipeline.ss" ("untyped" "unlib.plt" 3)))

; Procedures -------------------------------------

(define (make-parameterize-request-stage param)
  (make-stage
   'parameterize-request
   (lambda (continue possible-request . args)
     (if (request? possible-request)
         (parameterize ([param possible-request])
           (apply continue args))
         (apply continue possible-request args)))))

; Provide statements -----------------------------

(provide/contract
 [make-parameterize-request-stage (-> (parameter/c request?) stage?)])