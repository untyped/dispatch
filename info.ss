#lang setup/infotab
  
(define name "Dispatch")

(define blurb
  '((p "A tool for configuring controller procedures in web applications.")))

(define release-notes
  '((p "Changes and additions:")
    (ul (li "new syntaxes for " (tt "define-site") " and " (tt "define-controller") ";")
        (li "tools for restricting access to controllers;")
        (li "tools for creating hyperlinks between controllers;")
        (li "runtime (re)configuration of URLs;")
        (li "dropped pipelines in favour of simpler wrapper procedures;")
        (li "Mirrors support."))))

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