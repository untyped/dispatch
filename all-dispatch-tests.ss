#lang scheme/base

(require "test-base.ss")

(require "arg-tests.ss"
         "codec-tests.ss"
         "requestless-tests.ss")

; Tests ------------------------------------------

(define/provide-test-suite all-dispatch-tests
  arg-tests
  codec-tests
  requestless-tests)
