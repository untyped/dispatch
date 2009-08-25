#lang scheme/base

(require (planet untyped/unlib:3/require))

; Library aliases ------------------------------

(define-library-aliases mirrors    (planet untyped/mirrors:2)       #:provide)
(define-library-aliases unlib      (planet untyped/unlib:3)         #:provide)
(define-library-aliases schemeunit (planet schematics/schemeunit:3) #:provide)

; Require statements --------------------------- 

(require net/url
         scheme/class
         scheme/contract
         scheme/match
         scheme/pretty
         srfi/26
         web-server/http
         (mirrors-in)
         (unlib-in debug enumeration exn url))

; Exceptions -----------------------------------

(define-struct (exn:dispatch exn) () #:transparent)

; Provide statements --------------------------- 

(provide (all-from-out net/url
                       scheme/class
                       scheme/contract
                       scheme/match
                       scheme/pretty
                       srfi/26
                       web-server/http)
         (mirrors-out)
         (unlib-out debug enumeration exn url)
         (struct-out exn:dispatch))

