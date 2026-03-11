;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause
;;;;
;;;; base58.lisp - Bitcoin-style Base58 and Base58Check encoding
;;;;
;;;; Base58 encoding is used for Bitcoin addresses and other human-readable
;;;; identifiers. It avoids ambiguous characters (0, O, I, l) making addresses
;;;; safer to transcribe manually.
;;;;
;;;; Base58Check adds a 4-byte checksum (first 4 bytes of double SHA-256)
;;;; for error detection.
;;;;
;;;; Standards: Bitcoin Base58 Alphabet, Base58Check
;;;; Thread Safety: Yes (pure functions)
;;;; Performance: O(n^2) for encoding/decoding (bignum arithmetic)

(in-package #:cl-base58)

;;; ============================================================================
;;; Constants
;;; ============================================================================

(defparameter *base58-alphabet*
  "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  "Bitcoin Base58 alphabet. Excludes 0, O, I, l to avoid visual ambiguity.")

;;; ============================================================================
;;; Base58 Encoding
;;; ============================================================================

(defun base58-char-value (char)
  "Get the numeric value (0-57) of a Base58 character."
  (declare (type character char)
           (optimize (speed 3) (safety 1)))
  (let ((pos (position char *base58-alphabet*)))
    (unless pos
      (error "Invalid Base58 character: ~A" char))
    pos))

(defun base58-encode (bytes)
  "Encode a byte vector to Base58 string using Bitcoin alphabet.

PARAMETERS:
  BYTES - Byte vector (simple-array (unsigned-byte 8))

RETURNS:
  String - Base58 encoded representation

NOTES:
  - Leading zero bytes become leading '1' characters
  - Empty input returns empty string

EXAMPLES:
  (base58-encode #(0 1 2 3)) => \"15Q\"
  (base58-encode #(0 0 0 1)) => \"1112\""
  (declare (optimize (speed 3) (safety 1)))
  (when (zerop (length bytes))
    (return-from base58-encode ""))

  ;; Count leading zeros
  (let ((leading-zeros 0))
    (loop for byte across bytes
          while (zerop byte)
          do (incf leading-zeros))

    ;; Convert bytes to big integer
    (let ((n 0))
      (loop for byte across bytes
            do (setf n (+ (* n 256) byte)))

      ;; Convert to base58
      (let ((result '()))
        (loop while (plusp n)
              do (multiple-value-bind (q r) (floor n 58)
                   (push (char *base58-alphabet* r) result)
                   (setf n q)))

        ;; Add leading '1's for leading zeros
        (dotimes (i leading-zeros)
          (push #\1 result))

        (coerce result 'string)))))

(defun base58-decode (string)
  "Decode a Base58 string back to original byte vector.

PARAMETERS:
  STRING - Base58-encoded string

RETURNS:
  Vector - Byte vector (simple-array (unsigned-byte 8))

SIGNALS:
  Error on invalid Base58 characters

EXAMPLES:
  (base58-decode \"15Q\") => #(0 1 2 3)
  (base58-decode \"1112\") => #(0 0 0 1)"
  (declare (optimize (speed 3) (safety 1)))
  (when (zerop (length string))
    (return-from base58-decode (make-array 0 :element-type '(unsigned-byte 8))))

  ;; Count leading '1's
  (let ((leading-ones 0))
    (loop for char across string
          while (char= char #\1)
          do (incf leading-ones))

    ;; Convert from base58 to big integer
    (let ((n 0))
      (loop for char across string
            do (setf n (+ (* n 58) (base58-char-value char))))

      ;; Convert to bytes
      (let ((result '()))
        (loop while (plusp n)
              do (multiple-value-bind (q r) (floor n 256)
                   (push r result)
                   (setf n q)))

        ;; Add leading zeros
        (dotimes (i leading-ones)
          (push 0 result))

        (make-array (length result)
                    :element-type '(unsigned-byte 8)
                    :initial-contents result)))))

;;; ============================================================================
;;; Base58Check Encoding (with checksum)
;;; ============================================================================

(defun base58check-encode (version-byte payload)
  "Encode payload with version byte and checksum using Base58Check format.

PARAMETERS:
  VERSION-BYTE - Single byte indicating type/network (e.g., #x00 for Bitcoin P2PKH)
  PAYLOAD      - Byte vector (typically 20-byte pubkey hash)

RETURNS:
  String - Base58Check encoded string

FORMAT:
  Base58(version || payload || checksum)
  where checksum = first 4 bytes of SHA256(SHA256(version || payload))

EXAMPLES:
  ;; Bitcoin mainnet address (version #x00)
  (base58check-encode #x00 pubkey-hash) => \"1...\"

  ;; Bitcoin P2SH address (version #x05)
  (base58check-encode #x05 script-hash) => \"3...\""
  (let* ((payload-bytes (etypecase payload
                          ((vector (unsigned-byte 8)) payload)
                          (string (map '(vector (unsigned-byte 8))
                                      #'char-code payload))))
         (version-payload (make-array (1+ (length payload-bytes))
                                      :element-type '(unsigned-byte 8)))
         checksum
         full-data)

    ;; Prepend version byte
    (setf (aref version-payload 0) version-byte)
    (replace version-payload payload-bytes :start1 1)

    ;; Compute checksum (first 4 bytes of double SHA-256)
    (setf checksum (subseq (sha256d version-payload) 0 4))

    ;; Concatenate version-payload and checksum
    (setf full-data (make-array (+ (length version-payload) 4)
                                :element-type '(unsigned-byte 8)))
    (replace full-data version-payload)
    (replace full-data checksum :start1 (length version-payload))

    (base58-encode full-data)))

(defun base58check-decode (string)
  "Decode Base58Check string, validating checksum.

PARAMETERS:
  STRING - Base58Check encoded string

RETURNS:
  Primary: version-byte (unsigned-byte 8)
  Secondary: payload (byte vector)

SIGNALS:
  Error if checksum validation fails
  Error if input too short (< 5 decoded bytes)

EXAMPLES:
  (multiple-value-bind (ver payload)
      (base58check-decode \"1BvBMSEYstW...\")
    (assert (= ver #x00))
    (assert (= (length payload) 20)))"
  (let* ((data (base58-decode string))
         (len (length data)))

    (when (< len 5)
      (error "Base58Check data too short: ~D bytes (need at least 5)" len))

    (let* ((version-byte (aref data 0))
           (payload (subseq data 1 (- len 4)))
           (checksum (subseq data (- len 4)))
           (computed-checksum (subseq (sha256d (subseq data 0 (- len 4))) 0 4)))

      (unless (constant-time-bytes= checksum computed-checksum)
        (error "Base58Check checksum mismatch"))

      (values version-byte payload))))

;;; ============================================================================
;;; Address Utilities
;;; ============================================================================

(defun encode-address (pubkey-hash &optional (version #x00))
  "Encode public key hash as address.

PARAMETERS:
  PUBKEY-HASH - 20-byte RIPEMD160(SHA256(pubkey))
  VERSION     - Address version byte (default #x00 for Bitcoin mainnet P2PKH)

VERSION BYTES:
  #x00 - Bitcoin mainnet P2PKH (starts with '1')
  #x05 - Bitcoin mainnet P2SH (starts with '3')
  #x6F - Bitcoin testnet P2PKH (starts with 'm' or 'n')
  #xC4 - Bitcoin testnet P2SH (starts with '2')

RETURNS:
  String - Base58Check encoded address"
  (base58check-encode version pubkey-hash))

(defun decode-address (address)
  "Decode address string to version byte and public key hash.

PARAMETERS:
  ADDRESS - Base58Check encoded address

RETURNS:
  Primary: version-byte (indicates address type/network)
  Secondary: pubkey-hash (20-byte vector)

SIGNALS:
  Error on invalid checksum or format"
  (base58check-decode address))

(defun valid-address-p (address)
  "Check if address has valid Base58Check format and checksum.

PARAMETERS:
  ADDRESS - Potential address string

RETURNS:
  T if valid, NIL if invalid (never signals error)"
  (handler-case
      (progn
        (base58check-decode address)
        t)
    (error () nil)))

;;; ============================================================================
;;; WIF (Wallet Import Format)
;;; ============================================================================

(defun wif-to-private-key (wif)
  "Decode WIF (Wallet Import Format) string to private key bytes.

PARAMETERS:
  WIF - Base58Check encoded private key
        Mainnet: starts with '5' (uncompressed) or 'K'/'L' (compressed)
        Testnet: starts with '9' (uncompressed) or 'c' (compressed)

RETURNS:
  Primary: 32-byte private key vector
  Secondary: T if compressed pubkey flag set, NIL otherwise

EXAMPLES:
  (wif-to-private-key \"5Kb8kLf...\") => #(32-bytes), NIL
  (wif-to-private-key \"KwdMAN...\") => #(32-bytes), T"
  (multiple-value-bind (version payload) (base58check-decode wif)
    (declare (ignore version))
    (let* ((len (length payload))
           (compressed-p (= len 33)))
      (cond
        ;; Compressed: 33 bytes (32 key + 0x01 flag)
        ((and compressed-p (= (aref payload 32) #x01))
         (values (subseq payload 0 32) t))
        ;; Uncompressed: 32 bytes (just the key)
        ((= len 32)
         (values payload nil))
        ;; Invalid format
        (t
         (error "Invalid WIF format: expected 32 or 33 bytes, got ~D" len))))))

(defun private-key-to-wif (private-bytes &key (compressed t) (testnet nil))
  "Encode private key bytes to WIF (Wallet Import Format) string.

PARAMETERS:
  PRIVATE-BYTES - 32-byte private key
  COMPRESSED    - If T (default), append 0x01 for compressed pubkey derivation
  TESTNET       - If T, use testnet version byte (#xEF instead of #x80)

RETURNS:
  WIF-encoded string

VERSION BYTES:
  #x80 - Mainnet (starts with '5' uncompressed, 'K'/'L' compressed)
  #xEF - Testnet (starts with '9' uncompressed, 'c' compressed)

EXAMPLES:
  (private-key-to-wif key) => \"KwdMANk...\" (compressed mainnet)
  (private-key-to-wif key :compressed nil) => \"5Kb8kLf...\" (uncompressed)"
  (let ((version-byte (if testnet #xEF #x80))
        (payload (if compressed
                     (let ((p (make-array 33 :element-type '(unsigned-byte 8))))
                       (replace p private-bytes)
                       (setf (aref p 32) #x01)
                       p)
                     private-bytes)))
    (base58check-encode version-byte payload)))

;;; End of base58.lisp
