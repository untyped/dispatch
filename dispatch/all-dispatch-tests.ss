#lang scheme/base

(require (file "test-base.ss")
         (file "dispatch-test.ss")
         (file "pipeline-test.ss")
         (file "struct-test.ss")
         (file "syntax-test.ss"))

(provide all-dispatch-tests)

(define all-dispatch-tests
  (test-suite "dispatch"
    struct-tests
    dispatch-tests
    syntax-tests
    pipeline-tests))
