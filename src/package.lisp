;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-user)

(defpackage #:cl-base58
  (:use #:cl)
  (:export
   ;; Core Base58
   #:base58-encode
   #:base58-decode
   #:base58-char-value
   ;; Base58Check
   #:base58check-encode
   #:base58check-decode
   ;; Address utilities
   #:encode-address
   #:decode-address
   #:valid-address-p
   ;; WIF utilities
   #:wif-to-private-key
   #:private-key-to-wif
   ;; Custom alphabet
   #:encode-with-alphabet
   #:decode-with-alphabet
   ;; SHA256 (from sha256.lisp)
   #:sha256
   #:sha256d
   ;; Constants
   #:+base58-alphabet+
   #:+base64-url-alphabet+))
