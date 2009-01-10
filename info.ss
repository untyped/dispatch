#lang setup/infotab
  
(define name "Dispatch")

(define blurb
  '((p "A tool for configuring controller procedures in web applications.")))

(define release-notes
  '((p "Added a #:rule-not-found argument to define-site.")))

(define categories '(net devtools))
(define primary-file "dispatch.ss")
(define required-core-version "3.99")

(define doc.txt "doc.txt")

(define scribblings '(("doc/dispatch.scrbl" ())))
