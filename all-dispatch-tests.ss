#lang scheme/base

(require "test-base.ss")

(require srfi/19
         (mirrors-in)
         (unlib-in time)
         "main.ss")

; Test data --------------------------------------

; request integer integer -> real
(define-controller (divide-numbers request num den)
  #:access? (not (zero? den))
  (/ num den))

; request integer integer -> integer
(define-controller (add-numbers request first second)
  (+ first second))

; Leave subtract-numbers undefined.

; request boolean boolean -> boolean
(define-controller (and-booleans request first second)
  (if (and (boolean? first) (boolean? second))
      (and first second)
      (raise-type-error #f "booleans" (list first second))))

; request time-utc time-utc -> boolean
(define-controller (time-after request first second)
  (if (and (time-utc? first) (time-utc? second))
      (time>? first second)
      (raise-type-error #f "time-utcs" (list first second))))

; string -> request
(define (test-request url)
  (make-request #"GET" (string->url url) null null #f "1.2.3.4" 80 "4.3.2.1"))

; Tests ------------------------------------------

(define all-dispatch-tests
  (test-suite "dispatch"
    
    (test-case "site-dispatch : divide-numbers"
      (check-equal? (site-dispatch math (test-request "/divide/8/2")) 4)
      (check-equal? (site-dispatch math (test-request "/divide/8/4")) 2))
    
    (test-case "site-dispatch : add-numbers"
      #;(check-equal? (site-dispatch math (test-request "/add/1"))     1)
      (check-equal? (site-dispatch math (test-request "/add/1/2"))   3)
      #;(check-equal? (site-dispatch math (test-request "/add/1/2/3")) 6))
    
    (test-case "site-dispatch : controller undefined"
      (check-pred response/full? (site-dispatch math (test-request "/subtract/1/2")))
      (parameterize ([default-controller-undefined-responder
                      (lambda (controller request . args)
                        (cons (controller-id controller) args))])
        (check-equal? (site-dispatch math (test-request "/subtract/1/2"))
                      '(subtract-numbers 1 2))))
    
    (test-case "site-dispatch : access denied"
      (check-pred response/full? (site-dispatch math (test-request "/divide/8/0")))
      (parameterize ([default-access-denied-responder
                      (lambda (controller request . args)
                        (cons (controller-id controller) args))])
        (check-equal? (site-dispatch math (test-request "/divide/8/0"))
                      '(divide-numbers 8 0))))
    
    (test-case "site-dispatch : controller not found"
      (check-exn exn:dispatch? (cut site-dispatch math (test-request "/undefined"))))
    
    (test-case "site-dispatch : anchor / query string / url-params"
      (check-equal? (site-dispatch math (test-request "/divide/8/2#anchor"))   4)
      (check-equal? (site-dispatch math (test-request "/divide/8/4;((a . b))")) 2)
      (check-equal? (site-dispatch math (test-request "/divide/8/8?a=b&c=d"))   1))
    
    (test-case "controller-url : divide-numbers"
      (check-equal? (controller-url divide-numbers 8 2) "/divide/8/2")
      (check-equal? (controller-url divide-numbers 8 4) "/divide/8/4"))
    
    (test-case "controller-url : add-numbers"
      (check-equal? (controller-url add-numbers 1 2)    "/add/1/2"))
    
    (test-case "controller-access? : divide-numbers"
      (check-true  (controller-access? divide-numbers (test-request "foo") 8 2))
      (check-false (controller-access? divide-numbers (test-request "foo") 8 0)))
    
    (test-case "controller-link : no arguments"
      (let* ([link-ref (cut controller-link divide-numbers (test-request "foo") 8 4)]
             [mirrors  (link-ref)]
             [sexp     (parameterize ([current-link-format 'sexp]) (link-ref))]
             [sexps    (parameterize ([current-link-format 'sexps]) (link-ref))])
        (check-pred xml? mirrors)
        (check-equal? (xml->string mirrors) "<a href=\"/divide/8/4\">/divide/8/4</a>")
        (check-equal? sexp  '(a ([href "/divide/8/4"]) "/divide/8/4"))
        (check-equal? sexps '((a ([href "/divide/8/4"]) "/divide/8/4")))))
    
    (test-case "controller-link : all arguments"
      (let* ([link-ref (lambda (body)
                         (controller-link
                          divide-numbers
                          (test-request "foo") 8 4
                          #:id    'id
                          #:class 'class
                          #:title "title"
                          #:body  body))]
             [mirrors  (link-ref "body")]
             [sexp     (parameterize ([current-link-format 'sexp]) (link-ref "body"))]
             [sexps    (parameterize ([current-link-format 'sexps]) (link-ref '("body")))])
        (check-pred xml? mirrors)
        (check-equal? (xml->string mirrors) "<a href=\"/divide/8/4\" id=\"id\" class=\"class\" title=\"title\">body</a>")
        (check-equal? sexp  '(a ([href "/divide/8/4"] [id "id"] [class "class"] [title "title"]) "body"))
        (check-equal? sexps '((a ([href "/divide/8/4"] [id "id"] [class "class"] [title "title"]) "body")))))
    
    (test-case "controller-link : no access : hide"
      (let* ([link-ref (cut controller-link divide-numbers (test-request "foo") 8 0)]
             [mirrors  (link-ref)]
             [sexp     (parameterize ([current-link-format 'sexp]) (link-ref))]
             [sexps    (parameterize ([current-link-format 'sexps]) (link-ref))])
        (check-pred xml? mirrors)
        (check-pred xml-empty? mirrors)
        (check-equal? sexp  '(span))
        (check-equal? sexps null)))
    
    (test-case "controller-link : no access : span"
      (let* ([link-ref (cut controller-link divide-numbers (test-request "foo") 8 0 #:else 'span #:id 'id #:class 'class #:title "title")]
             [mirrors  (link-ref)]
             [sexp     (parameterize ([current-link-format 'sexp]) (link-ref))]
             [sexps    (parameterize ([current-link-format 'sexps]) (link-ref))])
        (check-pred xml? mirrors)
        (check-equal? (xml->string mirrors) "<span id=\"id\" class=\"no-access-link class\" title=\"title\">/divide/8/0</span>")
        (check-equal? sexp  '(span ([id "id"] [class "no-access-link class"] [title "title"]) "/divide/8/0"))
        (check-equal? sexps '((span ([id "id"] [class "no-access-link class"] [title "title"]) "/divide/8/0")))))
    
    (test-case "controller-link : no access : body"
      (let* ([link-ref (cut controller-link divide-numbers (test-request "foo") 8 0 #:else 'body)]
             [mirrors  (link-ref)]
             [sexp     (parameterize ([current-link-format 'sexp]) (link-ref))]
             [sexps    (parameterize ([current-link-format 'sexps]) (link-ref))])
        (check-pred xml? mirrors)
        (check-equal? (xml->string mirrors) "/divide/8/0")
        (check-equal? sexp  "/divide/8/0")
        (check-equal? sexps '("/divide/8/0"))))
    
    (test-equal? "site-controllers"
      (map controller-id (site-controllers math))
      '(divide-numbers
        add-numbers
        subtract-numbers
        and-booleans
        time-after))
    
    (test-case "default-controller-wrapper"
      (parameterize ([default-controller-wrapper
                      (lambda (controller request . args)
                        (add1 (apply (controller-body-proc controller) request args)))])
        (check-equal? (site-dispatch math (test-request "/divide/8/2")) 5)))
    
    (test-case "boolean-arg"
      (check-equal? (site-dispatch math (test-request "/and/yes/yes"))   #t)
      (check-equal? (site-dispatch math (test-request "/and/true/true")) #t)
      (check-equal? (site-dispatch math (test-request "/and/y/y"))       #t)
      (check-equal? (site-dispatch math (test-request "/and/yes/no"))    #f)
      (check-equal? (site-dispatch math (test-request "/and/yes/false")) #f)
      (check-equal? (site-dispatch math (test-request "/and/yes/n"))     #f)
      (check-equal? (controller-url and-booleans #t #f) "/and/yes/no"))
    
    (test-case "time-utc-arg"
      (check-equal? (site-dispatch math (test-request "/after/20090102/20090101")) #t)
      (check-equal? (site-dispatch math (test-request "/after/20090101/20090102")) #f))))

; Provide statements -----------------------------

(provide all-dispatch-tests)