#lang scheme/base

(require "base.ss")

(require net/uri-codec
         (unlib-in symbol)
         "struct-private.ss")

; Constructors ---------------------------------

; (U string arg) ... -> pattern
(define (create-pattern . elements)
  (make-pattern (make-pattern-regexp-maker elements)
                (filter arg? elements)
                elements))

; Other procedures -----------------------------

; (listof (U string (-> string) arg)) ... -> string
(define (make-pattern-regexp-maker elements)
  (let ([parts `("^" ,@(for/list ([elem (in-list elements)])
                         (match elem
                           [(? string?)    (regexp-quote elem)]
                           [(? arg?)       (format "(~a)" (arg-pattern elem))]
                           [(? procedure?) elem]))
                     "\\/?$")]) ; optional trailing slash
    (lambda ()
      (pregexp (apply string-append
                      (for/list ([part (in-list parts)])
                        (if (procedure? part)
                            (regexp-quote (part))
                            part)))))))

; pattern string -> (U list #f)
;
; Given a pattern and a string (representing a URL on the server), returns:
;
;   - A list of decoded arguments if the pattern matched the string.
;   - #f if the pattern did not match the string.
(define (pattern-match pattern url-string)
  (let* ([regexp  ((pattern-regexp-maker pattern))]
         [matches (regexp-match regexp url-string)])
    (and matches
         (= (length (cdr matches)) 
            (length (pattern-args pattern)))
         (for/list ([arg   (in-list (pattern-args pattern))]
                    [match (in-list (cdr matches))])
           ((arg-decoder arg) match)))))

; pattern list -> (U string #f)
(define (pattern->string pattern args)
  (and (= (length (pattern-args pattern)) (length args))
       (let ([ans (apply string-append
                         (let loop ([elems (pattern-elements pattern)]
                                    [args  args])
                           (match elems
                             [(list) null]
                             [(list elem elem-rest ...)
                              (match elem
                                [(? string?)    (cons elem   (loop elem-rest args))]
                                [(? procedure?) (cons (elem) (loop elem-rest args))]
                                [(? arg?)       (cons ((arg-encoder elem) (car args))
                                                      (loop elem-rest (cdr args)))])])))])
         (if (equal? ans "") "/" ans))))

; Provide statements ---------------------------

(provide/contract
 [create-pattern    (->* () () #:rest (listof (or/c string? procedure? arg?)) pattern?)]
 [pattern-match     (-> pattern? string? (or/c list? false/c))]
 [pattern->string   (-> pattern? (listof any/c) (or/c string? false/c))])
