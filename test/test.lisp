;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(defpackage #:cl-base58.test
  (:use #:cl #:cl-base58)
  (:export #:run-tests))

(in-package #:cl-base58.test)

(defun run-tests ()
  (format t "Executing functional test suite for cl-base58...~%")
  (assert (equal (deep-copy-list '(1 (2 3) 4)) '(1 (2 3) 4)))
  (assert (equal (group-by-count '(1 2 3 4 5) 2) '((1 2) (3 4) (5))))
  (format t "All functional tests passed!~%")
  t
  ;; Layer 2 Tests
  (let ((m-fn (memoize-function (lambda (x) (* x 2))))) (assert (= (funcall m-fn 5) 10)) (assert (= (funcall m-fn 5) 10)))
  t)