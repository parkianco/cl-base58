;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; sha256.lisp - Minimal SHA-256 implementation for Base58Check checksums
;;;;
;;;; This is a self-contained SHA-256 implementation providing only what's
;;;; needed for Base58Check encoding (double SHA-256 checksum). No external
;;;; crypto dependencies required.
;;;;
;;;; Thread Safety: Yes (pure functions)

(in-package #:cl-base58)

(declaim (optimize (speed 3) (safety 1)))

;;; ============================================================================
;;; SHA-256 Constants
;;; ============================================================================

(defparameter +sha256-k+
  (make-array 64 :element-type '(unsigned-byte 32)
              :initial-contents
              '(#x428a2f98 #x71374491 #xb5c0fbcf #xe9b5dba5
                #x3956c25b #x59f111f1 #x923f82a4 #xab1c5ed5
                #xd807aa98 #x12835b01 #x243185be #x550c7dc3
                #x72be5d74 #x80deb1fe #x9bdc06a7 #xc19bf174
                #xe49b69c1 #xefbe4786 #x0fc19dc6 #x240ca1cc
                #x2de92c6f #x4a7484aa #x5cb0a9dc #x76f988da
                #x983e5152 #xa831c66d #xb00327c8 #xbf597fc7
                #xc6e00bf3 #xd5a79147 #x06ca6351 #x14292967
                #x27b70a85 #x2e1b2138 #x4d2c6dfc #x53380d13
                #x650a7354 #x766a0abb #x81c2c92e #x92722c85
                #xa2bfe8a1 #xa81a664b #xc24b8b70 #xc76c51a3
                #xd192e819 #xd6990624 #xf40e3585 #x106aa070
                #x19a4c116 #x1e376c08 #x2748774c #x34b0bcb5
                #x391c0cb3 #x4ed8aa4a #x5b9cca4f #x682e6ff3
                #x748f82ee #x78a5636f #x84c87814 #x8cc70208
                #x90befffa #xa4506ceb #xbef9a3f7 #xc67178f2))
  "SHA-256 round constants (first 32 bits of fractional parts of cube roots of first 64 primes).")

(defparameter +sha256-h0+
  #(#x6a09e667 #xbb67ae85 #x3c6ef372 #xa54ff53a
    #x510e527f #x9b05688c #x1f83d9ab #x5be0cd19)
  "SHA-256 initial hash values (first 32 bits of fractional parts of square roots of first 8 primes).")

;;; ============================================================================
;;; Helper Functions
;;; ============================================================================

(declaim (inline u32 u32+ u32-rotr))

(defun u32 (x)
  "Truncate to 32 bits."
  (logand #xFFFFFFFF x))

(defun u32+ (&rest args)
  "32-bit addition with overflow."
  (u32 (apply #'+ args)))

(defun u32-rotr (x n)
  "32-bit right rotation."
  (declare (type (unsigned-byte 32) x)
           (type (integer 0 31) n))
  (logior (ash x (- n))
          (u32 (ash x (- 32 n)))))

(defun sha256-ch (x y z)
  (declare (type (unsigned-byte 32) x y z))
  (logxor (logand x y) (logand (lognot x) z)))

(defun sha256-maj (x y z)
  (declare (type (unsigned-byte 32) x y z))
  (logxor (logand x y) (logand x z) (logand y z)))

(defun sha256-sigma0 (x)
  (declare (type (unsigned-byte 32) x))
  (logxor (u32-rotr x 2) (u32-rotr x 13) (u32-rotr x 22)))

(defun sha256-sigma1 (x)
  (declare (type (unsigned-byte 32) x))
  (logxor (u32-rotr x 6) (u32-rotr x 11) (u32-rotr x 25)))

(defun sha256-gamma0 (x)
  (declare (type (unsigned-byte 32) x))
  (logxor (u32-rotr x 7) (u32-rotr x 18) (ash x -3)))

(defun sha256-gamma1 (x)
  (declare (type (unsigned-byte 32) x))
  (logxor (u32-rotr x 17) (u32-rotr x 19) (ash x -10)))

;;; ============================================================================
;;; SHA-256 Core
;;; ============================================================================

(defun sha256-transform (h block)
  "Process a 64-byte block, updating hash state H."
  (declare (type (simple-array (unsigned-byte 32) (8)) h)
           (type (vector (unsigned-byte 8)) block))
  (let ((w (make-array 64 :element-type '(unsigned-byte 32) :initial-element 0)))
    ;; Prepare message schedule
    (loop for i from 0 below 16
          for j = (* i 4)
          do (setf (aref w i)
                   (logior (ash (aref block j) 24)
                           (ash (aref block (+ j 1)) 16)
                           (ash (aref block (+ j 2)) 8)
                           (aref block (+ j 3)))))
    (loop for i from 16 below 64
          do (setf (aref w i)
                   (u32+ (sha256-gamma1 (aref w (- i 2)))
                         (aref w (- i 7))
                         (sha256-gamma0 (aref w (- i 15)))
                         (aref w (- i 16)))))

    ;; Initialize working variables
    (let ((a (aref h 0)) (b (aref h 1)) (c (aref h 2)) (d (aref h 3))
          (e (aref h 4)) (f (aref h 5)) (g (aref h 6)) (hh (aref h 7)))
      (declare (type (unsigned-byte 32) a b c d e f g hh))

      ;; 64 rounds
      (loop for i from 0 below 64
            for t1 = (u32+ hh (sha256-sigma1 e) (sha256-ch e f g)
                           (aref +sha256-k+ i) (aref w i))
            for t2 = (u32+ (sha256-sigma0 a) (sha256-maj a b c))
            do (setf hh g
                     g f
                     f e
                     e (u32+ d t1)
                     d c
                     c b
                     b a
                     a (u32+ t1 t2)))

      ;; Add to hash
      (setf (aref h 0) (u32+ (aref h 0) a)
            (aref h 1) (u32+ (aref h 1) b)
            (aref h 2) (u32+ (aref h 2) c)
            (aref h 3) (u32+ (aref h 3) d)
            (aref h 4) (u32+ (aref h 4) e)
            (aref h 5) (u32+ (aref h 5) f)
            (aref h 6) (u32+ (aref h 6) g)
            (aref h 7) (u32+ (aref h 7) hh)))))

(defun sha256 (data)
  "Compute SHA-256 hash of DATA (byte vector). Returns 32-byte digest."
  (declare (type (simple-array (unsigned-byte 8) (*)) data))
  (let* ((h (make-array 8 :element-type '(unsigned-byte 32)
                        :initial-contents (coerce +sha256-h0+ 'list)))
         (len (length data))
         (bit-len (* len 8))
         ;; Padding: 1 bit + zeros + 64-bit length
         (padded-len (* 64 (ceiling (+ len 9) 64)))
         (padded (make-array padded-len :element-type '(unsigned-byte 8) :initial-element 0)))

    ;; Copy data
    (replace padded data)

    ;; Append 1 bit
    (setf (aref padded len) #x80)

    ;; Append length (big-endian 64-bit)
    (loop for i from 0 below 8
          do (setf (aref padded (- padded-len 1 i))
                   (ldb (byte 8 (* i 8)) bit-len)))

    ;; Process blocks
    (loop for i from 0 below padded-len by 64
          for block = (make-array 64 :element-type '(unsigned-byte 8)
                                  :displaced-to padded
                                  :displaced-index-offset i)
          do (sha256-transform h block))

    ;; Output hash
    (let ((result (make-array 32 :element-type '(unsigned-byte 8))))
      (loop for i from 0 below 8
            for hi = (aref h i)
            do (setf (aref result (* i 4)) (ldb (byte 8 24) hi)
                     (aref result (+ (* i 4) 1)) (ldb (byte 8 16) hi)
                     (aref result (+ (* i 4) 2)) (ldb (byte 8 8) hi)
                     (aref result (+ (* i 4) 3)) (ldb (byte 8 0) hi)))
      result)))

(defun sha256d (data)
  "Compute double SHA-256 (SHA256(SHA256(data))). Used for Bitcoin checksums."
  (sha256 (sha256 data)))

;;; ============================================================================
;;; Constant-Time Comparison
;;; ============================================================================

(defun constant-time-bytes= (a b)
  "Constant-time comparison of two byte arrays.
   Returns T if equal, NIL otherwise.
   Timing does not depend on where arrays differ (prevents timing attacks)."
  (declare (type (simple-array (unsigned-byte 8) (*)) a b))
  (when (/= (length a) (length b))
    (return-from constant-time-bytes= nil))
  (let ((result 0))
    (declare (type (unsigned-byte 8) result))
    (dotimes (i (length a))
      (setf result (logior result (logxor (aref a i) (aref b i)))))
    (zerop result)))

;;; End of sha256.lisp
