#lang scheme/base

(require net/uri-codec
         net/url
         srfi/26/cut)

(require "test-base.ss"
         "dispatch.ss")

(provide struct-tests)

; Helpers ----------------------------------------

(define-site blog
  ([(url "/")                  index]
   [(url "/new")               create-post]
   [(url "/new/" (string-arg)) create-post]
   [(url "/archive/" 
         (integer-arg) "/"
         (integer-arg) "/"
         (integer-arg))        review-archive])
  #:other-controllers
  (delete-post))

(define arg1 (integer-arg))
(define arg2 (real-arg))
(define arg3 (string-arg))
(define arg4 (symbol-arg))

; (string -> string)
(define (make-test-pattern pattern)
  (format "^(~a)$" pattern))

; (string any ... -> (U (listof string) #f))
; Chops off the whole-pattern part of the regexp match to give us just the
; part we're interested in.
(define (test-match pattern . args)
  (define ans (apply regexp-match pattern args))
  (if (list? ans)
      (cdr ans)
      #f))

; Tests ------------------------------------------

(define struct-tests
  (test-suite "struct.ss"
    
    ; Integer arg --------------------------------
    
    (test-equal? "integer-arg: pattern-matching works"
      (test-match (make-test-pattern (arg-pattern arg1)) "123")
      '("123"))
    
    (test-equal? "integer-arg: pattern-matching fails on blank"
      (test-match (make-test-pattern (arg-pattern arg1)) "")
      #f)
    
    (test-equal? "integer-arg: decoder works"
      ((arg-decoder arg1) "123")
      123)
    
    (test-equal? "integer-arg: encoder works"
      ((arg-encoder arg1) 123)
      "123")
    
    (test-exn "integer-arg: encoder fails on non-integer"
      exn:fail:dispatch?
      (lambda () ((arg-encoder arg1) "123")))
    
    ; Real arg -----------------------------------
    
    (test-equal? "real-arg: pattern-matching works"
      (test-match (make-test-pattern (arg-pattern arg2)) "123.456")
      '("123.456"))
    
    (test-equal? "real-arg: pattern-matching fails on blank"
      (test-match (make-test-pattern (arg-pattern arg2)) "")
      #f)
    
    (test-equal? "real-arg: decoder works"
      ((arg-decoder arg2) "123.456")
      123.456)
    
    (test-equal? "real-arg: encoder works"
      ((arg-encoder arg2) 123.456)
      "123.456")
    
    (test-equal? "real-arg: encoder works on integer"
      ((arg-encoder arg2) 123)
      "123")
    
    (test-equal? "real-arg: encoder works on exact fraction"
      ((arg-encoder arg2) (/ 5 2))
      "2.5")
    
    (test-exn "real-arg: encoder fails on non-real"
      exn:fail:dispatch?
      (lambda () ((arg-encoder arg2) "123.456")))
    
    ; String arg ---------------------------------
    
    (test-equal? "string-arg: pattern-matching works"
      (test-match (make-test-pattern (arg-pattern arg3)) "123")
      '("123"))
    
    (test-equal? "string-arg: pattern-matching fails on blank"
      (test-match (make-test-pattern (arg-pattern arg3)) "")
      #f)
    
    (test-equal? "string-arg: decoder works"
      ((arg-decoder arg3) "123")
      "123")
    
    (test-equal? "string-arg: encoder works"
      ((arg-encoder arg3) "123")
      "123")
    
    (test-exn "string-arg: encoder fails on non-string"
      exn:fail:dispatch?
      (cut (arg-encoder arg3) 123))
    
    (test-equal? "string-arg: decoder works with URL-reserved characters"
      ((arg-decoder arg3) (uri-encode "12/34&56=78#90"))
      "12/34&56=78#90")
    
    (test-equal? "string-arg: encoder works with URL-reserved characters"
      ((arg-encoder arg3) "12/34&56=78#90")
      (uri-encode "12/34&56=78#90"))
    
    ; Symbol arg ---------------------------------
    
    (test-equal? "symbol-arg: pattern-matching works"
      (test-match (make-test-pattern (arg-pattern arg4)) "abc")
      '("abc"))
    
    (test-equal? "symbol-arg: pattern-matching fails on blank"
      (test-match (make-test-pattern (arg-pattern arg4)) "")
      #f)
    
    (test-equal? "symbol-arg: decoder works"
      ((arg-decoder arg4) "abc")
      'abc)
    
    (test-equal? "symbol-arg: encoder works"
      ((arg-encoder arg4) 'abc)
      "abc")
    
    (test-exn "symbol-arg: encoder fails on non-symbol"
      exn:fail:dispatch?
      (cut (arg-encoder arg4) 123))
    
    (test-equal? "symbol-arg: decoder works with URL-reserved characters"
      ((arg-decoder arg4) (uri-encode "ab/cd&ef=gh#ij"))
      'ab/cd&ef=gh#ij)
    
    (test-equal? "symbol-arg: encoder works with URL-reserved characters"
      ((arg-encoder arg4) 'ab/cd&ef=gh#ij)
      (uri-encode "ab/cd&ef=gh#ij"))

    ; Pattern ------------------------------------
    
    (test-equal? "create-pattern: regular expression is produced correctly"
      (format "~a" (pattern-regexp (make-pattern "/alpha/" (string-arg) "/" (integer-arg) "/")))
      (format "~a" (pregexp "^/alpha/([^/]+)/([-]?[0-9]+)/\\/?$")))
    
    (test-equal? "pattern-match: no args"
      (pattern-match (make-pattern "/alpha/beta/gamma/") 
                     "/alpha/beta/gamma/")
      null)
    
    (test-equal? "pattern-match: one string arg"
      (pattern-match (make-pattern "/alpha/" (string-arg) "/gamma/") 
                     "/alpha/beta/gamma/")
      (list "beta"))
    
    (test-equal? "pattern-match: one integer arg"
      (pattern-match (make-pattern "/123/" (integer-arg) "/789/") 
                     "/123/456/789/")
      (list 456))
    
    (test-equal? "pattern-match: no match"
      (pattern-match (make-pattern "/alpha/" (integer-arg) "/gamma/") 
                     "/alpha/beta/gamma/")
      #f)
    
    (test-equal? "pattern-match: various args"
      (pattern-match (make-pattern "/" (string-arg) "/" (integer-arg) "/" (integer-arg) "/") 
                     "/123/456/789/")
      (list "123" 456 789))
    
    (test-equal? "pattern->string"
      (pattern->string (make-pattern "/" (string-arg) "/" (integer-arg) "/" (integer-arg))
                       (list "123" 456 789))
      "/123/456/789")
    
    (test-equal? "pattern->string: empty pattern"
      (pattern->string (make-pattern "")
                       (list))
      "/")
    
    (test-exn "pattern->string: incorrect arg type"
      exn:fail:dispatch?
      (cut pattern->string
           (make-pattern "/" (string-arg) "/" (integer-arg) "/" (integer-arg) "/")
           (list "123" "456" 789)))
    
    (test-equal? "pattern->string: incorrect arity"
      (pattern->string (make-pattern "/" (string-arg) "/" (integer-arg) "/" (integer-arg) "/")
                       (list "123" 456))
      #f)
    
    ; Site and controller ------------------------

    (test-case "site-controller/url"
      (let-values ([(controller match) (site-controller/url blog (string->url "/new"))])
        (check-equal? controller create-post)
        (check-equal? match null)))
    
    (test-case "site-controller/url: with trailing slash"
      (let-values ([(controller match) (site-controller/url blog (string->url "/new/"))])
        (check-equal? controller create-post)
        (check-equal? match null)))
    
    (test-case "site-controller/url: with args"
      (let-values ([(controller match) (site-controller/url blog (string->url "/archive/2008/02/28"))])
        (check-equal? controller review-archive)
        (check-equal? match (list 2008 2 28))))
    
    (test-case "site-controller/url: with args and trailing slash"
      (let-values ([(controller match) (site-controller/url blog (string->url "/archive/2008/02/28/"))])
        (check-equal? controller review-archive)
        (check-equal? match (list 2008 2 28))))
    
    (test-case "site-controller/url: no match"
      (let-values ([(controller match) (site-controller/url blog (string->url "/news"))])
        (check-equal? controller #f)
        (check-equal? match #f)))
    
    (test-case "controller-url"
      (check-equal? (controller-url create-post)        "/new")
      (check-equal? (controller-url create-post "post") "/new/post"))
    
    (test-case "controller-url: incorrect arg type"
      (check-exn exn:fail:dispatch?
        (cut controller-url create-post 123)))
    
    (test-case "controller-url: incorrect arity"
      (check-exn exn:fail:dispatch?
        (cut controller-url create-post "abc" "def" "ghi")))
    
    (test-case "controller-url: no rule"
      (check-exn exn:fail:dispatch?
        (cut controller-url delete-post)))
    
    ))
