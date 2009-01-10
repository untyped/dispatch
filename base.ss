#lang scheme/base

(require scheme/pretty
         (planet untyped/unlib/debug)
         (planet untyped/unlib/exn))

; Exception types ------------------------------

(define-struct (exn:dispatch exn) () #:transparent)
(define-struct (exn:fail:dispatch exn:fail) () #:transparent)

; Provide statements --------------------------- 

(provide (all-from-out scheme/pretty
                       (planet untyped/unlib/debug)
                       (planet untyped/unlib/exn))
         (struct-out exn:dispatch)
         (struct-out exn:fail:dispatch))
