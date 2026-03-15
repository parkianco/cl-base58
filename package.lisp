;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

(defpackage #:cl-base58
  (:use #:cl)
  (:export
   ;; Base58 encoding/decoding
   #:base58-encode
   #:base58-decode

   ;; Base58Check (with checksum)
   #:base58check-encode
   #:base58check-decode

   ;; Address utilities
   #:encode-address
   #:decode-address
   #:valid-address-p

   ;; WIF (Wallet Import Format)
   #:wif-to-private-key
   #:private-key-to-wif

   ;; Constants
   #:+base58-alphabet+))
