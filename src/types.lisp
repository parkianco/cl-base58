;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-base58)

;;; Core types for cl-base58
(deftype cl-base58-id () '(unsigned-byte 64))
(deftype cl-base58-status () '(member :ready :active :error :shutdown))
