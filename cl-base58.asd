;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(asdf:defsystem #:cl-base58
  :description "Bitcoin-style Base58 and Base58Check encoding for Common Lisp"
  :author "Park Ian Co"
  :license "Apache-2.0"
  :version "0.1.0"
  :serial t
             (:module "src"
                :components ((:file "package")
                             (:file "conditions" :depends-on ("package"))
                             (:file "types" :depends-on ("package"))
                             (:file "sha256" :depends-on ("package"))
                             (:file "base58" :depends-on ("package" "conditions" "types" "sha256"))
                             (:file "cl-base58" :depends-on ("package" "conditions" "types" "sha256" "base58"))))))
  :in-order-to ((asdf:test-op (test-op #:cl-base58/test))))

(asdf:defsystem #:cl-base58/test
  :description "Tests for cl-base58"
  :depends-on (#:cl-base58)
  :serial t
  :components ((:module "test"
                :components ((:file "test-base58"))))
  :perform (asdf:test-op (o c)
             (let ((result (uiop:symbol-call :cl-base58.test :run-tests)))
               (unless result
                 (error "Tests failed")))))
