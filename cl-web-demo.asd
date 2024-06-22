(asdf:defsystem #:cl-web-demo
  :description "Trying out htmx with common lisp"
  :license  "MIT"
  :version "0.0.1"
  :pathname "src"
  :serial t
  :depends-on (#:clack #:ningle #:spinneret #:alexandria #:bknr.datastore "lack-middleware-csrf" "mito")
  :components ((:file "types")
               (:file "cl-web-demo")))
