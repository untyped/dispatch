#lang scheme/base

(require "base.ss")

(require (for-syntax scheme/base)
         srfi/13
         web-server/http
         web-server/servlet-env
         web-server/managers/manager
         (unlib-in keyword)
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

(define (serve/dispatch 
         site
         #:command-line?             [command-line?             (void)]
         #:launch-browser?           [launch-browser?           (void)]
         #:quit?                     [quit?                     (void)]
         #:banner?                   [banner?                   (void)]
         #:listen-ip                 [listen-ip                 (void)]
         #:port                      [port                      (void)]
         #:ssl?                      [ssl?                      (void)]
         #:manager                   [manager                   (void)]
         #:servlet-path              [servlet-path              "/"]
         #:servlet-regexp            [servlet-regexp            #rx""]
         #:stateless?                [stateless?                (void)]
         #:servlet-namespace         [servlet-namespace         (void)]
         #:server-root-path          [server-root-path          (void)]
         #:extra-files-paths         [extra-files-paths         (void)]
         #:servlets-root             [servlets-root             (void)]
         #:servlet-current-directory [servlet-current-directory (void)]
         #:file-not-found-responder  [file-not-found-responder  make-not-found-response]
         #:mime-types-path           [mime-types-path           (void)]
         #:log-file                  [log-file                  (void)]
         #:log-format                [log-format                (void)])
  (keyword-apply*
   serve/servlet
   (if (procedure? site)
       site
       (lambda (request)
         (dispatch request site)))
   (keyword-rest-argument
    command-line?
    launch-browser?
    quit?
    banner?
    listen-ip
    port
    ssl?
    manager
    servlet-path
    servlet-regexp
    stateless?
    servlet-namespace
    server-root-path
    extra-files-paths
    servlets-root
    servlet-current-directory
    file-not-found-responder
    mime-types-path
    log-file
    log-format)))

; Helpers --------------------------------------

; (_ id ...)
(define-syntax (keyword-rest-argument stx)
  (syntax-case stx ()
    [(_ id ...)
     (andmap identifier? (syntax->list #'(id ...)))
     (with-syntax ([(kw ...)
                    (for/list ([id-stx (in-list (syntax->list #'(id ...)))])
                      (datum->syntax id-stx (string->keyword (symbol->string (syntax->datum id-stx)))))])
       #'`(,@(if (void? id) null (list 'kw id)) ...))]))

; Provide statements --------------------------- 

(provide (all-from-out "struct.ss"
                       "syntax.ss")
         dispatch-url-cleaner
         (rename-out [make-not-found-response dispatch-not-found-responder]))

(provide/contract
 [dispatch       (-> request? site? any)]
 [serve/dispatch (->* ((or/c site? (-> request? any)))
                      (#:command-line? boolean?
                                       #:launch-browser? boolean?
                                       #:quit? boolean?
                                       #:banner? boolean?
                                       #:listen-ip (or/c string? #f)
                                       #:port number?
                                       #:ssl? boolean?
                                       #:manager manager?
                                       #:servlet-namespace (listof module-path?)
                                       #:server-root-path path-string?
                                       #:stateless? boolean?
                                       #:extra-files-paths (listof path-string?)
                                       #:servlets-root path-string?
                                       #:file-not-found-responder (-> request? (or/c response/full? response/incremental?))
                                       #:mime-types-path path-string?
                                       #:servlet-path string?
                                       #:servlet-regexp regexp?
                                       #:log-file (or/c path-string? #f))
                      any)])
