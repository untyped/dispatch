#lang scheme/base

(require "base.ss")

(require (schemeunit-in main text-ui)
         "main.ss")

; Test data --------------------------------------

(define-site math
  ([("/divide/"    (integer-arg)           "/" (integer-arg))           divide-numbers]
   [("/add/"       (integer-arg)           "/" (integer-arg))           add-numbers]
   [("/subtract/"  (integer-arg)           "/" (integer-arg))           subtract-numbers]
   [("/and/"       (boolean-arg)           "/" (boolean-arg))           and-booleans]
   [("/after/"     (time-utc-arg "~Y~m~d") "/" (time-utc-arg "~Y~m~d")) time-after]))

; Provide statements -----------------------------

(provide (all-from-out "base.ss")
         (schemeunit-out main text-ui)
         (site-out math))