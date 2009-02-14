#lang scheme/base

(require "test-base.ss")

(require "all-dispatch-tests.ss")

(print-hash-table #t)
(print-struct #t)
(error-print-width 1024)

(run-tests all-dispatch-tests)
