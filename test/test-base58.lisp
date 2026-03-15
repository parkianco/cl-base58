;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0
;;;;
;;;; test-base58.lisp - Tests for cl-base58

(defpackage #:cl-base58.test
  (:use #:cl #:cl-base58)
  (:export #:run-tests))

(in-package #:cl-base58.test)

(defvar *test-count* 0)
(defvar *pass-count* 0)
(defvar *fail-count* 0)

(defmacro deftest (name &body body)
  `(defun ,name ()
     (incf *test-count*)
     (handler-case
         (progn
           ,@body
           (incf *pass-count*)
           (format t "~&PASS: ~A~%" ',name))
       (error (e)
         (incf *fail-count*)
         (format t "~&FAIL: ~A - ~A~%" ',name e)))))

(defmacro assert-equal (expected actual)
  `(let ((exp ,expected)
         (act ,actual))
     (unless (equal exp act)
       (error "Expected ~S but got ~S" exp act))))

(defmacro assert-equalp (expected actual)
  `(let ((exp ,expected)
         (act ,actual))
     (unless (equalp exp act)
       (error "Expected ~S but got ~S" exp act))))

(defmacro assert-true (form)
  `(unless ,form
     (error "Expected true but got false: ~S" ',form)))

(defmacro assert-false (form)
  `(when ,form
     (error "Expected false but got true: ~S" ',form)))

(defmacro assert-error (form)
  `(handler-case
       (progn ,form
              (error "Expected error but none signaled"))
     (error () nil)))

;;; ============================================================================
;;; Base58 Encoding/Decoding Tests
;;; ============================================================================

(deftest test-base58-encode-empty
  (assert-equal "" (base58-encode #())))

(deftest test-base58-decode-empty
  (assert-equalp #() (base58-decode "")))

(deftest test-base58-single-byte
  ;; Single byte encoding
  (assert-equal "2" (base58-encode #(1)))
  (assert-equal "z" (base58-encode #(57))))

(deftest test-base58-leading-zeros
  ;; Leading zero bytes become leading '1's
  (assert-equal "111" (base58-encode #(0 0 0)))
  (assert-equal "1112" (base58-encode #(0 0 0 1))))

(deftest test-base58-round-trip
  ;; Various data round-trips correctly
  (dolist (data (list #(1 2 3 4 5)
                      #(0 0 1 2 3)
                      #(255 254 253)
                      #(0 0 0 0)
                      #(1)))
    (assert-equalp data (base58-decode (base58-encode data)))))

(deftest test-base58-bitcoin-wiki-vector
  ;; From Bitcoin wiki: "Hello World" in hex = 48656c6c6f20576f726c64
  (let ((hello-bytes #(#x48 #x65 #x6c #x6c #x6f #x20 #x57 #x6f #x72 #x6c #x64)))
    (assert-equal "JxF12TrwUP45BMd" (base58-encode hello-bytes))))

(deftest test-base58-invalid-char
  (assert-error (base58-decode "0InvalidChar"))  ; 0 is not in Base58 alphabet
  (assert-error (base58-decode "OInvalid"))      ; O is not in Base58 alphabet
  (assert-error (base58-decode "IInvalid"))      ; I is not in Base58 alphabet
  (assert-error (base58-decode "lInvalid")))     ; l is not in Base58 alphabet

;;; ============================================================================
;;; Base58Check Tests
;;; ============================================================================

(deftest test-base58check-encode-decode
  ;; Round-trip with checksum
  (let* ((payload #(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20))
         (encoded (base58check-encode #x00 payload)))
    (multiple-value-bind (version decoded-payload)
        (base58check-decode encoded)
      (assert-equal #x00 version)
      (assert-equalp payload decoded-payload))))

(deftest test-base58check-different-versions
  ;; Different version bytes produce different encodings
  (let ((payload #(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)))
    (let ((v0 (base58check-encode #x00 payload))
          (v5 (base58check-encode #x05 payload)))
      (assert-false (equal v0 v5)))))

(deftest test-base58check-invalid-checksum
  ;; Modified string should fail checksum
  (let* ((payload #(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20))
         (encoded (base58check-encode #x00 payload))
         ;; Corrupt the last character
         (corrupted (concatenate 'string
                                (subseq encoded 0 (1- (length encoded)))
                                (if (char= (char encoded (1- (length encoded))) #\1)
                                    "2" "1"))))
    (assert-error (base58check-decode corrupted))))

(deftest test-base58check-too-short
  (assert-error (base58check-decode "1")))

;;; ============================================================================
;;; Address Tests
;;; ============================================================================

(deftest test-encode-address
  ;; Encode with default version
  (let* ((hash #(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19))
         (addr (encode-address hash #x00)))
    (assert-true (> (length addr) 20))))

(deftest test-decode-address
  (let* ((hash #(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19))
         (addr (encode-address hash #x00)))
    (multiple-value-bind (version decoded)
        (decode-address addr)
      (assert-equal #x00 version)
      (assert-equalp hash decoded))))

(deftest test-valid-address-p
  ;; Valid address
  (let ((addr (encode-address #(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19) #x00)))
    (assert-true (valid-address-p addr)))
  ;; Invalid addresses
  (assert-false (valid-address-p ""))
  (assert-false (valid-address-p "invalid"))
  (assert-false (valid-address-p "1")))

;;; ============================================================================
;;; WIF Tests
;;; ============================================================================

(deftest test-wif-round-trip-compressed
  (let ((key (make-array 32 :element-type '(unsigned-byte 8) :initial-element 42)))
    (let ((wif (private-key-to-wif key :compressed t)))
      (multiple-value-bind (decoded compressed-p)
          (wif-to-private-key wif)
        (assert-equalp key decoded)
        (assert-true compressed-p)))))

(deftest test-wif-round-trip-uncompressed
  (let ((key (make-array 32 :element-type '(unsigned-byte 8) :initial-element 42)))
    (let ((wif (private-key-to-wif key :compressed nil)))
      (multiple-value-bind (decoded compressed-p)
          (wif-to-private-key wif)
        (assert-equalp key decoded)
        (assert-false compressed-p)))))

(deftest test-wif-mainnet-vs-testnet
  (let ((key (make-array 32 :element-type '(unsigned-byte 8) :initial-element 1)))
    (let ((mainnet (private-key-to-wif key :testnet nil))
          (testnet (private-key-to-wif key :testnet t)))
      ;; Different version bytes produce different results
      (assert-false (equal mainnet testnet)))))

;;; ============================================================================
;;; Test Runner
;;; ============================================================================

(defun run-tests ()
  (setf *test-count* 0
        *pass-count* 0
        *fail-count* 0)
  (format t "~&Running cl-base58 tests...~%")
  (format t "~&========================================~%")

  ;; Base58 tests
  (test-base58-encode-empty)
  (test-base58-decode-empty)
  (test-base58-single-byte)
  (test-base58-leading-zeros)
  (test-base58-round-trip)
  (test-base58-bitcoin-wiki-vector)
  (test-base58-invalid-char)

  ;; Base58Check tests
  (test-base58check-encode-decode)
  (test-base58check-different-versions)
  (test-base58check-invalid-checksum)
  (test-base58check-too-short)

  ;; Address tests
  (test-encode-address)
  (test-decode-address)
  (test-valid-address-p)

  ;; WIF tests
  (test-wif-round-trip-compressed)
  (test-wif-round-trip-uncompressed)
  (test-wif-mainnet-vs-testnet)

  (format t "~&========================================~%")
  (format t "~&Tests: ~D  Passed: ~D  Failed: ~D~%"
          *test-count* *pass-count* *fail-count*)
  (zerop *fail-count*))

;;; End of test-base58.lisp
