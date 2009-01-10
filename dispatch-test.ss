#lang scheme/base

(require (prefix-in net: net/url)
         srfi/26/cut
         web-server/private/request-structs
         web-server/private/response-structs)

(require (file "test-base.ss")
         (file "dispatch.ss"))

(require/expose (file "dispatch.ss") (local-url->string))

(provide dispatch-tests)

; Helpers ----------------------------------------

(define-site blog
  ([(url "/")                   index]
   [(url "/new")                create-post]
   [(url "/new/" (integer-arg)) create-post]))

(define-controller index       null (lambda (request . args) (cons "index" args)))
(define-controller create-post null (lambda (request . args) (cons "create-post" args)))

(define (test-request url)
  (make-request 'get (net:string->url url) null null #f "1.2.3.4" 123 "4.3.2.1"))

; Tests ------------------------------------------

(define dispatch-tests
  (test-suite "dispatch.ss"
    
    (test-equal? "local-url->string"
      (local-url->string (net:string->url "http://www.example.com/alpha/beta;param1/gamma;param1;param2"))
      "/alpha/beta;param1/gamma;param1;param2")
    
    (test-equal? "local-url->string: with final slash"
      (local-url->string (net:string->url "http://www.example.com/alpha/beta;param1/gamma;param1;param2/"))
      "/alpha/beta;param1/gamma;param1;param2/")
    
    (test-case "dispatch"
      (check-equal? (dispatch (test-request "http://www.example.com/new") blog) (list "create-post"))
      (check-equal? (dispatch (test-request "http://www.example.com/new/") blog) (list "create-post"))
      (check-equal? (dispatch (test-request "http://www.example.com/new/123") blog) (list "create-post" 123))
      (check-equal? (dispatch (test-request "http://www.example.com/new/123/") blog) (list "create-post" 123))
      (check-equal? (dispatch (test-request "http://www.example.com/new/123#anchor") blog) (list "create-post" 123))
      (check-equal? (dispatch (test-request "http://www.example.com/new/123/#anchor") blog) (list "create-post" 123))
      (check-equal? (dispatch (test-request "http://www.example.com/new/123?a=banchor") blog) (list "create-post" 123))
      (check-equal? (dispatch (test-request "http://www.example.com/new/123/?a=b") blog) (list "create-post" 123)))
    
    (test-pred "dispatch: rule not found"
      response?
      (dispatch (test-request "http://www.example.com/new/123/abc") blog))
    
    ))
