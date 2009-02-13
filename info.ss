#lang setup/infotab
  
(define name "Dispatch")

(define blurb
  '((p "A tool for configuring controller procedures in web applications.")))

(define release-notes
  '((p "Changes:")
    (ul (li "updated to PLT 4.1.4.3."))))

(define categories '(net devtools))

(define primary-file "main.ss")

(define scribblings '(("scribblings/dispatch.scrbl" ())))

(define required-core-version "4.1.4.3")

(define repositories '("4.x"))
