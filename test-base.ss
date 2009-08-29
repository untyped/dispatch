#lang scheme/base

(require "base.ss")

(require (schemeunit-in main text-ui)
         "main.ss")

; Utilities --------------------------------------

; string -> request
(define (test-request url)
  (make-request #"GET" (string->url url) null null #f "1.2.3.4" 80 "4.3.2.1"))

; Provide statements -----------------------------

(provide (all-from-out "base.ss")
         (schemeunit-out main text-ui))

(provide/contract
 [test-request (-> string? request?)])