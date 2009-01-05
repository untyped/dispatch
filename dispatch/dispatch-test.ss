#lang scheme/base

(require (only-in net/url string->url)
         srfi/26/cut
         web-server/private/request-structs
         web-server/private/response-structs
         (file "test-base.ss")
         (file "dispatch.ss"))

; Helpers ----------------------------------------

(define-site blog
  ([(url "/")                   index]
   [(url "/new")                create-post]
   [(url "/new/" (integer-arg)) create-post]
   [(url (rest-arg))            not-found]))

(define-controller index       null (lambda (request . args) (cons "index" args)))
(define-controller create-post null (lambda (request . args) (cons "create-post" args)))
(define-controller not-found   null (lambda (request . args) (cons "not-found" args)))

(define (test-request url)
  (make-request 'get (string->url url) null null #f "1.2.3.4" 123 "4.3.2.1"))

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
    
    (test-pred "dispatch: rule not found"
      response?
      (dispatch (test-request "http://www.example.com/new/123/abc") blog))))

; Provide statements -----------------------------

(provide dispatch-tests)

