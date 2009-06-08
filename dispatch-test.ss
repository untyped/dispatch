#lang scheme/base

(require "base.ss")

(require web-server/dispatchers/dispatch
         web-server/http/request-structs
         web-server/http/response-structs
         "test-base.ss"
         "dispatch.ss")

; Helpers ----------------------------------------

(define-site blog
  ([(url "/")                   index]
   [(url "/new")                create-post]
   [(url "/new/" (integer-arg)) create-post]))

(define-controller index       null (lambda (request . args) (cons "index" args)))
(define-controller create-post null (lambda (request . args) (cons "create-post" args)))

(define-check (check-url url ans)
  (check-equal? (dispatch (test-request url) blog) ans))

; Tests ------------------------------------------

(define dispatch-tests
  (test-suite "dispatch.ss"
    
    (test-case "dispatch"
      (check-url "http://www.example.com/new" (list "create-post"))
      (check-url "http://www.example.com/new/" (list "create-post"))
      (check-url "http://www.example.com/new/123" (list "create-post" 123))
      (check-url "http://www.example.com/new/123/" (list "create-post" 123))
      (check-url "http://www.example.com/new/123#anchor" (list "create-post" 123))
      (check-url "http://www.example.com/new/123/#anchor" (list "create-post" 123))
      (check-url "http://www.example.com/new/123?a=banchor" (list "create-post" 123))
      (check-url "http://www.example.com/new/123/?a=b" (list "create-post" 123)))
    
    (test-case "dispatch: default rule-not-found handler"
      (with-handlers ([(lambda (exn) #t)
                       (lambda (exn) (check-pred exn:dispatcher? exn))])
        (dispatch (test-request "http://www.example.com/new/123/abc") blog)
        (fail "No exception raised")))))

; Provide statements -----------------------------

(provide dispatch-tests)

