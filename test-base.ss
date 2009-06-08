#lang scheme/base

(require "base.ss")

(require (for-syntax scheme/base)
         (schemeunit-in main text-ui))

; (_ expr)
(define-syntax (test-request stx)
  (syntax-case stx ()
    [(_ url)
     (cond [(identifier-binding #'response?)  #'(make-request 'get (string->url url) null null #f "1.2.3.4" 80 "4.3.2.1")]
           [(identifier-binding #'response/c) #'(make-request #"GET" (string->url url) null null #f "1.2.3.4" 80 "4.3.2.1")]
           [else (error "response? and response/c not found")])]))

; Provide statements -----------------------------

(provide (all-from-out "base.ss")
         (schemeunit-out main text-ui)
         test-request)
