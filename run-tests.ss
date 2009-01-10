#lang scheme/base

(require "all-dispatch-tests.ss"
         "test-base.ss")

(print-hash-table #t)
(print-struct #t)
(error-print-width 1024)

(run-tests all-dispatch-tests)
