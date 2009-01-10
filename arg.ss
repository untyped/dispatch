#lang scheme/base

(require scheme/contract
         net/uri-codec)

(require "base.ss"
         "struct-private.ss")

; -> arg
(define (boolean-arg)
  (make-arg 
   'boolean
   "yes|no" 
   (lambda (raw)
     (equal? raw "yes"))
   (lambda (arg)
     (if arg "yes" "no"))))

; -> arg
(define (integer-arg)
  (make-arg 
   'integer
   "[-]?[0-9]+" 
   (lambda (raw)
     (string->number raw))
   (lambda (arg)
     (if (integer? arg)
         (number->string arg)
         (raise-exn exn:fail:dispatch
           (format "Expected integer, given: ~s" arg))))))

; -> arg
(define (real-arg)
  (make-arg 
   'real
   "[-]?[0-9]+|[-]?[0-9]*.[0-9]*?" 
   (lambda (raw)
     (string->number raw))
   (lambda (arg)
     (cond [(integer? arg) (number->string arg)]
           [(real? arg)    (number->string (exact->inexact arg))]
           [else           (raise-exn exn:fail:dispatch
                             (format "Expected real, given: ~s" arg))]))))

; -> arg
(define (string-arg)
  (make-arg 
   'string
   "[^/]+"
   (lambda (raw)
     (uri-decode raw))
   (lambda (arg)
     (if (string? arg)
         (uri-encode arg)
         (raise-exn exn:fail:dispatch
           (format "Expected string, given: ~s" arg))))))

; -> arg
(define (symbol-arg)
  (make-arg 
   'symbol
   "[^/]+"
   (lambda (raw)
     (string->symbol (uri-decode raw)))
   (lambda (arg)
     (if (symbol? arg)
         (uri-encode (symbol->string arg))
         (raise-exn exn:fail:dispatch
           (format "Expected symbol, given: ~s" arg))))))

; -> arg
(define (rest-arg)
  (make-arg
   'rest
   ".*"
   (lambda (raw)
     (uri-decode raw))
   (lambda (arg)
     (if (string? arg)
         (uri-encode arg)
         (raise-exn exn:fail:dispatch
           (format "Expected string, given: ~s" arg))))))

; Provide statements -----------------------------

(provide/contract
 [boolean-arg (-> arg?)]
 [integer-arg (-> arg?)]
 [real-arg    (-> arg?)]
 [string-arg  (-> arg?)]
 [symbol-arg  (-> arg?)]
 [rest-arg    (-> arg?)])

