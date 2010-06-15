#lang setup/infotab
  
(define name "Dispatch")

(define blurb
  '((p "Bidirectional mapping between web application URLs and controller procedures.")))

(define release-notes
  '((p "Changes and additions:")
    (ul (li "evaluation of strings in URL patterns can now be deffered to request handling time by wrapping them in thunks;")
        (li "fixed typo in the docs."))))

(define categories '(net devtools))

(define primary-file "main.ss")

(define scribblings '(("scribblings/dispatch.scrbl" ())))

(define required-core-version "4.1.4.1")

(define repositories '("4.x"))

(define compile-omit-paths
  '("autoplanet.ss"
    "build.ss"
    "planet"
    "planetdev"))
