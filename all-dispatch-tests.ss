#lang scheme/base

(require "test-base.ss")

(require "dispatch-test.ss"
         "pipeline-test.ss"
         "struct-test.ss"
         "syntax-test.ss")

(define all-dispatch-tests
  (test-suite "dispatch"
    struct-tests
    dispatch-tests
    syntax-tests
    pipeline-tests))

; Provide statements -----------------------------

(provide all-dispatch-tests)
