#lang scheme/base

(require net/url
         scheme/contract
         scheme/pretty
         (planet untyped/unlib/debug)
         (planet untyped/unlib/exn)
         (planet untyped/unlib/log)
         (planet untyped/unlib/url))

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

(provide (all-from-out scheme/pretty
                       (planet untyped/unlib/debug)
                       (planet untyped/unlib/exn)
                       (planet untyped/unlib/log))
         (struct-out exn:dispatch)
         (struct-out exn:fail:dispatch))

(provide/contract
 [dispatch-url-cleaner (parameter/c (-> url? url?))]
 [clean-url            (-> url? url?)])
