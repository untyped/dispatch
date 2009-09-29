#lang scheme/base

(require "base.ss")

(require net/uri-codec
         scheme/string
         srfi/19
         (unlib-in time)
         "core.ss")

; -> arg
(define (boolean-arg)
  (make-arg 
   "yes|no|true|false|y|n|t|f|1|0" 
   (lambda (raw)
     (and (member (string-downcase raw) 
                  (list "yes" "true" "y" "t" "1"))
          #t))
   (lambda (arg)
     (if arg "yes" "no"))))

; -> arg
(define (integer-arg)
  (make-arg 
   "[-]?[0-9]+" 
   (lambda (raw)
     (string->number raw))
   (lambda (arg)
     (if (integer? arg)
         (number->string arg)
         (raise-type-error 'integer-arg "integer" arg)))))

; -> arg
(define (number-arg)
  (make-arg 
   "[-]?[0-9]+|[-]?[0-9]*.[0-9]*?" 
   (lambda (raw)
     (string->number raw))
   (lambda (arg)
     (cond [(integer? arg) (number->string arg)]
           [(real? arg)    (number->string (exact->inexact arg))]
           [else           (raise-type-error 'real-arg "real" arg)]))))

; -> arg
(define (string-arg)
  (make-arg 
   "[^/]+"
   (lambda (raw)
     (uri-decode raw))
   (lambda (arg)
     (if (string? arg)
         (uri-encode arg)
         (raise-type-error 'string-arg "string" arg)))))

; -> arg
(define (symbol-arg)
  (make-arg 
   "[^/]+"
   (lambda (raw)
     (string->symbol (uri-decode raw)))
   (lambda (arg)
     (if (symbol? arg)
         (uri-encode (symbol->string arg))
         (raise-type-error 'symbol-arg "symbol" arg)))))


(define (time-utc-arg [fmt (current-time-format)])
  (make-arg
   "[^/]+"
   (lambda (raw)
     (let ([date (safe-string->date raw fmt)])
       (if date 
           (date->time-utc date)
           (raise-exn exn:dispatch "no match for date-arg"))))
   (lambda (time)
     (if (time-utc? time)
         (date->string (time-utc->date time) fmt)
         (raise-type-error 'time-utc-arg "time-utc" time)))))

; -> arg
(define (rest-arg)
  (make-arg
   ".*"
   (lambda (raw)
     (uri-decode raw))
   (lambda (arg)
     (if (string? arg)
         (uri-encode arg)
         (raise-type-error 'rest-arg "string" arg)))))

; enum -> arg
(define (enum-arg enum)
  (make-arg
   (string-join (map regexp-quote
                     (map (cut format "~a" <>)
                          (enum-values enum)))
                "|")
   (lambda (raw)
     (for/or ([val (in-list (enum-values enum))])
       (and (equal? (format "~a" val) raw) val)))
   (lambda (val)
     (if (enum-value? enum val)
         (format "~a" val)
         (raise-type-error (enum-name enum) (format "~a" (enum-values enum)) val)))))

; Helpers ----------------------------------------

(define (safe-string->date str fmt)
  (with-handlers ([exn? (lambda _ #f)])
    (string->date str fmt)))

; Provide statements -----------------------------

(provide/contract
 [boolean-arg  (-> arg?)]
 [integer-arg  (-> arg?)]
 [number-arg   (-> arg?)]
 [string-arg   (-> arg?)]
 [symbol-arg   (-> arg?)]
 [time-utc-arg (->* () (string?) arg?)]
 [rest-arg     (-> arg?)]
 [enum-arg     (-> enum? arg?)])
