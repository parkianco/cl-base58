(asdf:defsystem #:cl-base58
  :depends-on (#:alexandria #:bordeaux-threads)
  :components ((:module "src"
                :components ((:file "package")
                             (:file "cl-base58" :depends-on ("package"))))))