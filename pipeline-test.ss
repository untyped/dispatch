#lang scheme/base

(require "base.ss")

(require (unlib-in pipeline)
         "pipeline.ss"
         "test-base.ss")

; Helpers ----------------------------------------

; stage list list -> void
(define (check-stage stage actual expected)
  (check-equal? (apply call-with-pipeline 
                       (list stage)
                       (lambda args args)
                       actual)
                expected))

; Tests ------------------------------------------

(define pipeline-tests
  (test-suite "pipeline.ss"
    
    (test-case "eliminate-request-stage"
      (check-stage eliminate-request-stage (list (test-request "http://www.example.com") 123) (list 123))
      (check-stage eliminate-request-stage (list (test-request "http://www.example.com")) (list))
      (check-stage eliminate-request-stage (list 123) (list 123))
      (check-stage eliminate-request-stage (list) (list)))))

; Provide statements -----------------------------

(provide pipeline-tests)
