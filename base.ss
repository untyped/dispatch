#lang scheme/base

(require (planet "debug.ss" ("untyped" "unlib.plt" 3))
         (planet "exn.ss" ("untyped" "unlib.plt" 3)))

; Exception types ------------------------------

(define-struct (exn:dispatch exn) () #:transparent)
(define-struct (exn:fail:dispatch exn:fail) () #:transparent)

; Provide statements --------------------------- 

(provide (all-from-out (planet "debug.ss" ("untyped" "unlib.plt" 3)))
         (all-from-out (planet "exn.ss" ("untyped" "unlib.plt" 3))))

(provide (struct-out exn:dispatch)
         (struct-out exn:fail:dispatch))
