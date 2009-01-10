#lang scheme/base

(require mzlib/etc)

(require (file "all-dispatch-tests.ss")
         (file "test-base.ss"))

(begin (print-hash-table #t)
       (print-struct #t)
       (error-print-width 1024)
       (test/text-ui all-dispatch-tests))
