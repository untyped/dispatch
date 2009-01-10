#lang scheme/base

(require net/url
         scheme/contract
         web-server/servlet
         (planet untyped/mirrors/mirrors)
         (planet untyped/unlib/number)
         (file "base.ss"))

; Procedures -------------------------------------

; request symbol (listof any) -> response
(define (make-undefined-response request controller-id controller-args)
  (make-html-response
   #:code    500
   #:message "Internal error"
   (xml (html (head (title "Controller not defined")
                    ,stylesheet)
              (body (div (@ [id "container"])
                         (h1 "Controller not defined")
                         (p "You called the controller:")
                         (p (@ [class "example"])
                            (span (@ [class "paren"]) "(")
                            (span (@ [class "controller"]) ,(format "~a" controller-id))
                            ,@(map (lambda (arg)
                                     (xml (span (@ [class "argument"]) ,(format " ~s" arg))))
                                   (cons 'request controller-args))
                            (span (@ [class "paren"]) ")"))
                         (p "Unfortunately, it looks like this controller has not been defined with a "
                            (span (@ [class "controller"]) "define-controller") " statement.")
                         (p "If you have written a definition for this controller, make sure it is "
                            "directly or indirectly required by the main module that runs your application.")))))))

; request -> response
(define (make-not-found-response request)
  (make-html-response
   #:code    404
   #:message "Not found"
   #:seconds (current-seconds)
   (xml (html (head (title "404 not found")
                    ,stylesheet)
              (body (div (@ [id "container"])
                         (h1 "Controller not found")
                         (p "You visited the URL:")
                         (p (@ [class "example"])
                            (span (@ [class "argument"])
                                  "\"" ,(url->string (clean-url (request-uri request))) "\""))
                         (p "Unfortunately, we could not find this file on our site.")))))))

; Helpers ----------------------------------------

; xml
(define stylesheet
  (xml (style (@ [type "text/css"])
              #<<ENDCSS
body { background: #eee; }
#container { border: 1px solid #aaa; background: #fff; width: 600px; margin: 50px auto; padding: 10px; }
h1 { font-family: verdana,arial,sans-serif; color: #500; margin-top: 0px; }
p { font-family: arial,sans-serif; }
.example { margin: 5px auto; text-align: center; }
.paren { font-family: monaco,monospace; color: #700; }
.controller { font-family: monaco,monospace; color: #007; }
.argument { font-family: monaco,monospace; color: #070; }
ENDCSS
              )))

; Provide statements -----------------------------

(provide/contract
 [make-undefined-response (-> request? symbol? list? response?)]
 [make-not-found-response (-> request? response?)])
