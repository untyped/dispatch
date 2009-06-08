#lang setup/infotab
  
(define name "Dispatch")

(define blurb
  '((p "A tool for configuring controller procedures in web applications.")))

(define release-notes
  '((p "Changes and additions:")
    (ul (li "added the " (tt "serve/dispatch") " procedure;")
        (li "updated the quick start in the docs;")
        (li "ensured PLT compatibility from PLT 4.1.4.1 upwards."))))

(define categories '(net devtools))

(define primary-file "main.ss")

(define scribblings '(("scribblings/dispatch.scrbl" ())))

(define required-core-version "4.1.4.1")

(define repositories '("4.x"))
