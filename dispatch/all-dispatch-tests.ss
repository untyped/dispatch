#lang scheme/base

(require "test-base.ss"
         "dispatch-test.ss"
         "pipeline-test.ss"
         "struct-test.ss"
         "syntax-test.ss")

(provide all-dispatch-tests)

(define all-dispatch-tests
  (test-suite "dispatch"
    struct-tests
    dispatch-tests
    syntax-tests
    pipeline-tests))
