#lang scheme/base

(require scheme/contract
         net/url
         srfi/13/string
         web-server/private/request-structs)

(require (file "base.ss")
         (file "response.ss")
         (file "struct.ss")
         (file "syntax.ss"))

; Procedures -----------------------------------

;; (request site -> any)
(define (dispatch request site)
  (define url
    (local-url->string (request-uri request)))
  (define-values (controller match)
    (site-controller/url site url))
  (if controller
      (apply controller request match)
      ((site-rule-not-found site) request)))

;; (url -> string)
(define (local-url->string url)
  (string-append "/"
                 (string-join (map (lambda (elem)
                                     (string-join (cons (path/param-path elem)
                                                        (path/param-param elem))
                                                  ";"))
                                   (url-path url))
                              "/")))

; Provide statements --------------------------- 

(provide (all-from-out (file "struct.ss"))
         (all-from-out (file "syntax.ss")))

(provide/contract
 [dispatch (-> request? site? any)])
