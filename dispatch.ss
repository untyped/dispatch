#lang scheme/base

(require net/url
         scheme/contract
         srfi/13
         web-server/http/request-structs
         "base.ss"
         "response.ss"
         "struct.ss"
         "syntax.ss")

; Procedures -----------------------------------

; request site -> any
(define (dispatch request site)
  (define url
    (clean-url (request-uri request)))
  (define-values (controller match)
    (site-controller/url site url))
  ;(log-info* "Dispatching" (url->string url))
  (if controller
      (apply controller request match)
      ((site-rule-not-found site) request)))

; Provide statements --------------------------- 

(provide (all-from-out "struct.ss"
                       "syntax.ss")
         dispatch-url-cleaner)

(provide/contract
 [dispatch (-> request? site? any)])
