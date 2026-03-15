;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-base58)

(defparameter *alphabet* "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

(defun encode (data)
  "Encode bytes to Base58 string."
  (let ((num (bytes-to-integer data)) (result nil))
    (if (zerop num)
        "1"
        (loop until (zerop num)
              do (push (char *alphabet* (mod num 58)) result)
                 (setf num (floor num 58))
              finally (return (format nil "~{~A~}" result))))))

(defun bytes-to-integer (bytes)
  (loop for byte across bytes with result = 0
        do (setf result (+ (* result 256) byte))
        finally (return result)))

(defun decode (str)
  "Decode Base58 string to bytes."
  (let ((num 0))
    (loop for ch across str
          do (let ((idx (position ch *alphabet*)))
               (setf num (+ (* num 58) idx))))
    (integer-to-bytes num)))

(defun integer-to-bytes (num)
  (loop while (> num 0)
        collect (mod num 256) into bytes
        do (setf num (floor num 256))
        finally (return (make-array (length bytes) :initial-contents (nreverse bytes)
                                   :element-type '(unsigned-byte 8)))))
