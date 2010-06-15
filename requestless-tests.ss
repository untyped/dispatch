#lang scheme/base

(require "test-base.ss")

(require srfi/19
         (mirrors-in)
         (unlib-in time)
         "main.ss")

(require/expose web-server/dispatchers/dispatch
  (exn:dispatcher?))

; Test data --------------------------------------

(define-site math
  ([("/add/"      (integer-arg) "/" (integer-arg)) add-numbers]
   [("/subtract/" (integer-arg) "/" (integer-arg)) subtract-numbers])
  #:requestless? #t)

; integer integer -> integer
(define-controller (add-numbers first second)
  #:access? (and (> first 0) (> second 0))
  (+ first second))

; Tests ------------------------------------------

(define/provide-test-suite requestless-tests
    
  (test-case "site-dispatch : normal case"
    (check-equal? (site-dispatch math (test-request "/add/1/2")) 3))
  
  (test-case "site-dispatch : controller undefined"
    (check-pred response/full? (site-dispatch math (test-request "/subtract/1/2")))
    (parameterize ([default-controller-undefined-responder
                     (lambda (controller . args)
                       (cons (controller-id controller) args))])
      (check-equal? (site-dispatch math (test-request "/subtract/1/2"))
                    '(subtract-numbers 1 2))))
  
  (test-case "site-dispatch : access denied"
    (check-pred response/full? (site-dispatch math (test-request "/add/0/0")))
    (parameterize ([default-access-denied-responder (lambda (controller . args)
                                                      (cons (controller-id controller) args))])
      (check-equal? (site-dispatch math (test-request "/add/0/0"))
                    '(add-numbers 0 0))))
  
  (test-case "site-dispatch : controller not found"
    ; We can't use check-exn because exn:dispatcher isn't actually an exn:
    (check-true (with-handlers ([exn:dispatcher? (lambda _ #t)])
                  (site-dispatch math (test-request "/undefined"))
                  #f)))
    
  (test-case "controller-url"
    (check-equal? (controller-url add-numbers 1 2) "/add/1/2"))
  
  (test-case "controller-link"
    (let* ([link-ref (cut controller-link add-numbers 8 4)]
           [mirrors  (link-ref)]
           [sexp     (parameterize ([default-link-format 'sexp]) (link-ref))]
           [sexps    (parameterize ([default-link-format 'sexps]) (link-ref))])
      (check-pred xml? mirrors)
      (check-equal? (xml->string mirrors) "<a href=\"/add/8/4\">/add/8/4</a>")
      (check-equal? sexp  '(a ([href "/add/8/4"]) "/add/8/4"))
      (check-equal? sexps '((a ([href "/add/8/4"]) "/add/8/4"))))))
