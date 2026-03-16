;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(defpackage #:cl-base58.test
  (:use #:cl #:cl-base58)
  (:export #:run-tests))

(in-package #:cl-base58.test)

(defun run-tests ()
  (format t "Running professional test suite for cl-base58...~%")
  (assert (initialize-base58))
  (format t "Tests passed!~%")
  t)
