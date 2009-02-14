#lang scheme/base

(require "base.ss")

(require web-server/dispatchers/dispatch
         (unlib-in pipeline)
         "dispatch.ss"
         "test-base.ss")

; Test data --------------------------------------

(define-site blog
  ([(url "")                     index]
   [(url "/posts/" (string-arg)) review-post])
  #:other-controllers (handle-form))

(define-site blog2
  ([(url "") index2])
  #:rule-not-found    (lambda (request) 123)
  #:other-controllers (handle-form2))

(define (append-x continue request slug)
  (continue request (string-append slug "x")))

(define-controller (index request)
  (list "index" request))

(define-controller review-post
  (list append-x)
  (lambda (request slug)
    (list "review-post" request slug)))

; Helpers ----------------------------------------

(define (test-request url)
  (make-request #"get" (string->url url) null null #f "1.2.3.4" 123 "4.3.2.1"))

; Tests ------------------------------------------

(define syntax-tests
  (test-suite "syntax.ss"
    
    (test-case "define-site: #:other-controllers"
      (check-pred controller? handle-form  "blog")
      (check-pred controller? handle-form2 "blog2"))
    
    (test-case "define-site: #:rule-not-found"
      (check-exn exn:dispatcher? (cut dispatch (test-request "/blah") blog) "blog")
      (check-equal? (dispatch (test-request "/blah") blog2) 123 "blog2"))
    
    (test-case "define-controller: repeat definition"
      (with-handlers ([exn:fail:dispatch? (lambda args (void))])
        (define-controller (index request)
          (list "redefined-index" request))
        (fail "Controller defined successfully.")))

    (test-case "define-controller: no pipeline"
      (let* ([request  (test-request "/")]
             [response (dispatch request blog)])
        (check-equal? response (list "index" request))))
    
    (test-case "define-controller: pipeline"
      (let* ([request  (test-request "/posts/slug")]
             [response (dispatch request blog)])
        (check-equal? response (list "review-post" request "slugx"))))))

; Provide statements -----------------------------

(provide syntax-tests)
