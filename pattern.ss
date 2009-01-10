#lang scheme/base

(require scheme/contract
         net/uri-codec)

(require (planet "symbol.ss" ("untyped" "unlib.plt" 3)))

(require (file "base.ss")
         (file "struct-private.ss"))

; Constructors ---------------------------------

;; create-pattern : (U string arg) ... -> pattern
(define (create-pattern . elements)
  (make-pattern (make-pattern-regexp elements)
                (filter arg? elements)
                elements))

; Other procedures -----------------------------

;; make-pattern-regexp : (list-of (U string arg)) boolean ... -> string
(define (make-pattern-regexp elements)
  ; The call to format is a hack to allow an optional extra ending slash on the URL.
  (pregexp (format "^~a\\/?$"
                   (let loop ([rest elements])
                     (cond [(null? rest)         ""]
                           [(string? (car rest)) (string-append (regexp-quote (car rest)) (loop (cdr rest)))]
                           [(arg?    (car rest)) (string-append "(" (arg-pattern (car rest)) ")" (loop (cdr rest)))]
                           [else                 (raise-exn exn:fail:dispatch
                                                   (format "Unrecognised pattern component: ~a" (car rest)))])))))

;; pattern-match pattern string -> (U (list-of any) #f)
;;
;; Given a pattern and a string (representing a URL on the server),
;; returns:
;;
;;   - A list of decoded arguments if the pattern matched the string.
;;   - #f if the pattern did not match the string.
(define (pattern-match pattern url-string)
  (define regexp (pattern-regexp pattern))
  (define matches (regexp-match regexp url-string))
  (if (and matches (= (length (cdr matches)) 
                      (length (pattern-args pattern))))
      (map (lambda (arg match)
             ((arg-decoder arg) match))
           (pattern-args pattern)
           (cdr matches))
      #f))

;; pattern->string pattern (list-of any) -> (U string #f)
(define (pattern->string pattern args)
  (if (= (length (pattern-args pattern)) (length args))
      (let loop ([elem-rest (pattern-elements pattern)]
                 [arg-rest args])
        (if (null? elem-rest)
            ""
            (let ([elem (car elem-rest)])
              (if (string? elem)
                  (string-append elem 
                                 (loop (cdr elem-rest) arg-rest))
                  (string-append ((arg-encoder elem) (car arg-rest))
                                 (loop (cdr elem-rest) (cdr arg-rest)))))))
      #f))

; Provide statements ---------------------------

(provide/contract
 [create-pattern    (->* () () #:rest (listof (or/c string? arg?)) pattern?)]
 [pattern-match     (-> pattern? string? (or/c list? false/c))]
 [pattern->string   (-> pattern? (listof any/c) (or/c string? false/c))])
