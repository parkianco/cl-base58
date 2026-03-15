;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-base58)

(define-condition cl-base58-error (error)
  ((message :initarg :message :reader cl-base58-error-message))
  (:report (lambda (condition stream)
             (format stream "cl-base58 error: ~A" (cl-base58-error-message condition)))))
