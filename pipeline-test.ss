#lang scheme/base

(require "base.ss")

(require (unlib-in pipeline)
         "pipeline.ss"
         "test-base.ss")

; Helpers ----------------------------------------

; request
(define test-request
  (make-request #"get" (string->url "http://www.example.com") null null #f "1.2.3.4" 123 "4.3.2.1"))

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
      (check-stage eliminate-request-stage (list test-request 123) (list 123))
      (check-stage eliminate-request-stage (list test-request) (list))
      (check-stage eliminate-request-stage (list 123) (list 123))
      (check-stage eliminate-request-stage (list) (list)))))

; Provide statements -----------------------------

(provide pipeline-tests)
