;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-base58)


;;; Higher-level API for Bitcoin/Crypto applications using base58.lisp functions

;;; Substantive Functional Logic

(defun deep-copy-list (l)
  "Recursively copies a nested list."
  (if (atom l) l (cons (deep-copy-list (car l)) (deep-copy-list (cdr l)))))

(defun group-by-count (list n)
  "Groups list elements into sublists of size N."
  (loop for i from 0 below (length list) by n
        collect (subseq list i (min (+ i n) (length list)))))


;;; Substantive Layer 2: Advanced Algorithmic Logic

(defun memoize-function (fn)
  "Returns a memoized version of function FN."
  (let ((cache (make-hash-table :test 'equal)))
    (lambda (&rest args)
      (multiple-value-bind (val exists) (gethash args cache)
        (if exists
            val
            (let ((res (apply fn args)))
              (setf (gethash args cache) res)
              res))))))
