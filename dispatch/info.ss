#lang setup/infotab
  
(define name "Dispatch")

(define blurb
  '((p "A tool for configuring controller procedures in web applications.")))

(define release-notes
  '((p "Changes:")
    (ul (li "updated for PLT 4.1.3.x;"))))

(define categories '(net devtools))

(define primary-file "dispatch.ss")

(define scribblings '(("scribblings/dispatch.scrbl" ())))

(define required-core-version "4.0")

(define repositories '("4.x"))
