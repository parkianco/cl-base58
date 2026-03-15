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


;;; Substantive API Implementations
(define-condition cl-base58-error (cl-base58-error) ())
(define-condition cl-base58-validation-error (cl-base58-error) ())


;;; ============================================================================
;;; Standard Toolkit for cl-base58
;;; ============================================================================

(defmacro with-base58-timing (&body body)
  "Executes BODY and logs the execution time specific to cl-base58."
  (let ((start (gensym))
        (end (gensym)))
    `(let ((,start (get-internal-real-time)))
       (multiple-value-prog1
           (progn ,@body)
         (let ((,end (get-internal-real-time)))
           (format t "~&[cl-base58] Execution time: ~A ms~%"
                   (/ (* (- ,end ,start) 1000.0) internal-time-units-per-second)))))))

(defun base58-batch-process (items processor-fn)
  "Applies PROCESSOR-FN to each item in ITEMS, handling errors resiliently.
Returns (values processed-results error-alist)."
  (let ((results nil)
        (errors nil))
    (dolist (item items)
      (handler-case
          (push (funcall processor-fn item) results)
        (error (e)
          (push (cons item e) errors))))
    (values (nreverse results) (nreverse errors))))

(defun base58-health-check ()
  "Performs a basic health check for the cl-base58 module."
  (let ((ctx (initialize-base58)))
    (if (validate-base58 ctx)
        :healthy
        :degraded)))
