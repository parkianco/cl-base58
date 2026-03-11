;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(asdf:defsystem #:cl-base58
  :description "Bitcoin-style Base58 and Base58Check encoding for Common Lisp"
  :author "Parkian Company LLC"
  :license "BSD-3-Clause"
  :version "1.0.0"
  :serial t
  :components ((:file "package")
               (:module "src"
                :components ((:file "sha256")
                             (:file "base58"))))
  :in-order-to ((test-op (test-op #:cl-base58/test))))

(asdf:defsystem #:cl-base58/test
  :description "Tests for cl-base58"
  :depends-on (#:cl-base58)
  :serial t
  :components ((:module "test"
                :components ((:file "test-base58"))))
  :perform (test-op (o c)
             (uiop:symbol-call :cl-base58.test :run-tests)))
