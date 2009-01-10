#lang scheme/base

(require scheme/contract)

(require (planet "pipeline.ss" ("untyped" "unlib.plt" 3)))

; Structure types ------------------------------

;; (struct symbol string (string -> any) (any -> string))
(define-struct arg
  (id pattern decoder encoder)
  #:property prop:custom-write
  (lambda (arg out write?)
    (define show (if write? write display))
    (display "#(arg " out)
    (show (arg-id arg) out)
    (display ")" out))
  #:transparent)

;; (struct regexp (list-of arg) (list-of (U string arg)))
(define-struct pattern 
  (regexp args elements)
  #:transparent)

;; (stuct pattern controller)
(define-struct rule
  (pattern controller)
  #:property prop:custom-write
  (lambda (rule out write?)
    (define show (if write? write display))
    (display "#(rule " out)
    (show (rule-pattern rule) out)
    (display " " out)
    (show (controller-id (rule-controller rule)) out)
    (display ")" out))
  #:transparent)

;; (struct symbol site (listof stage) (any ... -> response))
(define-struct controller 
  (id site [pipeline #:mutable] [body #:mutable])
  #:property prop:procedure 
  (lambda (controller . args)
    (apply call-with-pipeline
           (controller-pipeline controller)
           (controller-body controller)
           args))
  #:property prop:custom-write
  (lambda (controller out write?)
    (define show (if write? write display))
    (display "#(controller " out)
    (show (controller-id controller) out)
    (display " " out)
    (show (controller-pipeline controller) out)
    (display " " out)
    (show (controller-body controller) out)
    (display ")" out))
  #:transparent)

;; (struct symbol (listof rule) (listof controller))
(define-struct site
  (id [rules #:mutable] [controllers #:mutable] [rule-not-found #:mutable])
  #:transparent)

; Provide statements -----------------------------

(provide/contract
 [struct arg          ([id symbol?] [pattern string?] [decoder procedure?] [encoder procedure?])]
 [struct pattern      ([regexp regexp?] [args (listof arg?)] [elements (listof (or/c string? arg?))])]
 [struct rule         ([pattern pattern?] [controller controller?])]
 [struct controller   ([id symbol?] [site site?] [pipeline (listof procedure?)] [body procedure?])]
 [struct site         ([id symbol?] [rules (listof rule?)] [controllers (listof controller?)] [rule-not-found procedure?])])
 