#lang scheme/base

(require (planet untyped/unlib:3/require))

(define-library-aliases mirrors    (planet untyped/mirrors:2:2)     #:provide)
(define-library-aliases unlib      (planet untyped/unlib:3)         #:provide)
(define-library-aliases schemeunit (planet schematics/schemeunit:3) #:provide)

(require net/url
         scheme/contract
         scheme/match
         scheme/pretty
         srfi/26
         web-server/http
         (unlib-in debug exn log url))

; Exception types ------------------------------

(define-struct (exn:dispatch exn) () #:transparent)
(define-struct (exn:fail:dispatch exn:fail) () #:transparent)

; Configuration parameters ---------------------

; (parameter (url -> url))
(define dispatch-url-cleaner
  (make-parameter (lambda (url)
                    (url-remove-params (url-path-only url)))))

; url -> url
(define (clean-url url)
  ((dispatch-url-cleaner) url))

; Provide statements --------------------------- 

(provide (all-from-out net/url
                       scheme/contract
                       scheme/match
                       scheme/pretty
                       srfi/26
                       web-server/http)
         (unlib-out debug exn log url)
         (struct-out exn:dispatch)
         (struct-out exn:fail:dispatch))

(provide/contract
 [dispatch-url-cleaner (parameter/c (-> url? url?))]
 [clean-url            (-> url? url?)])
