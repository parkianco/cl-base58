# cl-base58

A pure Common Lisp implementation of Bitcoin-style Base58 and Base58Check encoding.

## Features

- Base58 encoding/decoding with Bitcoin alphabet
- Base58Check with double-SHA256 checksum verification
- Address encoding/decoding utilities
- WIF (Wallet Import Format) for private keys
- Self-contained SHA-256 implementation (no external crypto dependencies)
- Zero external dependencies
- Thread-safe (pure functions)

## Installation

Clone the repository and load with ASDF:

```lisp
(asdf:load-system :cl-base58)
```

## Usage

### Base58 Encoding/Decoding

```lisp
;; Encode bytes to Base58
(cl-base58:base58-encode #(72 101 108 108 111))
;; => "9Ajdvzr"

;; Decode Base58 to bytes
(cl-base58:base58-decode "9Ajdvzr")
;; => #(72 101 108 108 111)

;; Leading zeros become '1' characters
(cl-base58:base58-encode #(0 0 0 1))
;; => "1112"
```

### Base58Check (with checksum)

```lisp
;; Encode with version byte and checksum
(cl-base58:base58check-encode #x00 pubkey-hash)
;; => "1BvBMSEY..."

;; Decode and verify checksum
(multiple-value-bind (version payload)
    (cl-base58:base58check-decode "1BvBMSEY...")
  (format t "Version: ~X, Payload: ~A bytes~%"
          version (length payload)))
```

### Bitcoin Addresses

```lisp
;; Create address from pubkey hash
(cl-base58:encode-address pubkey-hash #x00)  ; Bitcoin mainnet
(cl-base58:encode-address script-hash #x05)  ; P2SH address

;; Decode address
(multiple-value-bind (version hash)
    (cl-base58:decode-address "1BvBMSEY...")
  ...)

;; Validate address
(cl-base58:valid-address-p "1BvBMSEY...")  ; => T or NIL
```

### WIF (Wallet Import Format)

```lisp
;; Encode private key to WIF
(cl-base58:private-key-to-wif private-key-bytes)
;; => "KwdMANk..." (compressed)

(cl-base58:private-key-to-wif private-key-bytes :compressed nil)
;; => "5Kb8kLf..." (uncompressed)

;; Decode WIF to private key
(multiple-value-bind (key compressed-p)
    (cl-base58:wif-to-private-key "KwdMANk...")
  (format t "Compressed: ~A~%" compressed-p))
```

## Version Bytes

Common Bitcoin version bytes:

| Version | Prefix | Network | Type |
|---------|--------|---------|------|
| #x00 | 1 | Mainnet | P2PKH |
| #x05 | 3 | Mainnet | P2SH |
| #x6F | m/n | Testnet | P2PKH |
| #xC4 | 2 | Testnet | P2SH |
| #x80 | 5/K/L | Mainnet | WIF |
| #xEF | 9/c | Testnet | WIF |

## API Reference

### Base58

- `base58-encode (bytes)` - Encode byte vector to Base58 string
- `base58-decode (string)` - Decode Base58 string to byte vector

### Base58Check

- `base58check-encode (version-byte payload)` - Encode with checksum
- `base58check-decode (string)` - Decode and verify checksum (returns version, payload)

### Addresses

- `encode-address (pubkey-hash &optional version)` - Create address from hash
- `decode-address (address)` - Extract version and hash (returns version, hash)
- `valid-address-p (address)` - Check if address is valid (returns T/NIL)

### WIF

- `private-key-to-wif (key &key compressed testnet)` - Encode private key
- `wif-to-private-key (wif)` - Decode WIF (returns key, compressed-p)

## Testing

```lisp
(asdf:test-system :cl-base58)
```

## License

BSD-3-Clause. See LICENSE file.
