# cl-base58

Pure Common Lisp implementation of Base58

## Overview
This library provides a robust, zero-dependency implementation of Base58 for the Common Lisp ecosystem. It is designed to be highly portable, performant, and easy to integrate into any SBCL/CCL/ECL environment.

## Getting Started

Load the system using ASDF:

```lisp
(asdf:load-system #:cl-base58)
```

## Usage Example

```lisp
;; Initialize the environment
(let ((ctx (cl-base58:initialize-base58 :initial-id 42)))
  ;; Perform batch processing using the built-in standard toolkit
  (multiple-value-bind (results errors)
      (cl-base58:base58-batch-process '(1 2 3) #'identity)
    (format t "Processed ~A items with ~A errors.~%" (length results) (length errors))))
```

## License
Apache-2.0
