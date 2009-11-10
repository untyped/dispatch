#lang scheme/base

(require "test-base.ss")

(require srfi/19
         (mirrors-in)
         (unlib-in time)
         "main.ss")

; Test data --------------------------------------

(define-enum options (a b c))

(define-site args
  ([("/bool/" (boolean-arg))           test-bool]
   [("/url/"  (url-arg))               test-url]
   [("/time/" (time-utc-arg "~Y~m~d")) test-time]
   [("/enum/" (enum-arg options))      test-enum]
   [("/rest"  (rest-arg 1))            test-rest]))

(define-controller (test-bool request arg) arg)
(define-controller (test-url  request arg) arg)
(define-controller (test-time request arg) arg)
(define-controller (test-enum request arg) arg)
(define-controller (test-rest request arg) arg)

; Tests ------------------------------------------

(define/provide-test-suite arg-tests
  
  (test-case "boolean-arg"
    (check-equal? (site-dispatch args (test-request "/bool/yes"))   #t)
    (check-equal? (site-dispatch args (test-request "/bool/true"))  #t)
    (check-equal? (site-dispatch args (test-request "/bool/y"))     #t)
    (check-equal? (site-dispatch args (test-request "/bool/1"))     #t)
    (check-equal? (site-dispatch args (test-request "/bool/no"))    #f)
    (check-equal? (site-dispatch args (test-request "/bool/false")) #f)
    (check-equal? (site-dispatch args (test-request "/bool/n"))     #f)
    (check-equal? (site-dispatch args (test-request "/bool/0"))     #f)
    (check-equal? (controller-url test-bool #t) "/bool/yes")
    (check-equal? (controller-url test-bool #f) "/bool/no"))
  
  (test-case "url-arg"
    (check-equal? (url->string (site-dispatch args (test-request "/url/%2Fa-url"))) "/a-url")
    (check-equal? (controller-url test-url (string->url "/a-url")) "/url/%2Fa-url")
    (check-equal? (controller-url test-url "/a-url") "/url/%2Fa-url"))
  
  (test-case "time-utc-arg"
    (check-equal? (site-dispatch args (test-request "/time/20090102"))
                  (date->time-utc (make-date 0 0 0 0 2 1 2009 (current-time-zone-offset))))
    (check-equal? (controller-url test-time (date->time-utc (make-date 0 0 0 0 2 1 2009 (current-time-zone-offset))))
                  "/time/20090102"))
  
  (test-case "enum-arg"
    (check-not-exn
      (lambda ()
        (check-equal? (site-dispatch args (test-request "/enum/a")) 'a)
        (check-equal? (site-dispatch args (test-request "/enum/b")) 'b)
        (check-equal? (site-dispatch args (test-request "/enum/c")) 'c)
        (check-equal? (controller-url test-enum 'a) "/enum/a")
        (check-equal? (controller-url test-enum 'b) "/enum/b")
        (check-equal? (controller-url test-enum 'c) "/enum/c"))))
  
  (test-case "rest-arg"
    (check-equal? (site-dispatch args (test-request "/rest/a")) "/a")
    (check-equal? (site-dispatch args (test-request "/rest%2Fa")) "/a")
    (check-equal? (site-dispatch args (test-request "/rest/a/b/c")) "/a/b/c")
    (check-equal? (site-dispatch args (test-request "/rest/a/b/c?d=e")) "/a/b/c")
    (check-equal? (site-dispatch args (test-request "/rest/a/b/c#d")) "/a/b/c")
    (check-equal? (site-dispatch args (test-request "/rest/a;x/b;y/c;z")) "/a/b/c")
    (check-equal? (controller-url test-rest "/a") "/rest/a")
    (check-equal? (controller-url test-rest "%2Fa") "/rest%252Fa")
    (check-equal? (controller-url test-rest "/a/b/c") "/rest/a/b/c")))
