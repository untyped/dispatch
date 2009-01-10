#lang scheme/base

(require scheme/contract
         srfi/13/string
         web-server/private/request-structs
         (file "base.ss")
         (file "response.ss")
         (file "struct.ss")
         (file "syntax.ss"))

; Procedures -----------------------------------

; request site -> any
(define (dispatch request site)
  (define-values (controller match)
    (site-controller/url site (clean-url (request-uri request))))
  (if controller
      (apply controller request match)
      ((site-rule-not-found site) request)))

; Provide statements --------------------------- 

(provide (all-from-out (file "struct.ss"))
         (all-from-out (file "syntax.ss"))
         dispatch-url-cleaner)

(provide/contract
 [dispatch (-> request? site? any)])
