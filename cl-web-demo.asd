(asdf:defsystem #:cl-web-demo
  :description "Trying out htmx with common lisp"
  :license  "MIT"
  :version "0.0.1"
  :serial t
  :depends-on (#:clack #:ningle #:spinneret #:alexandria #:bknr.datastore "lack-middleware-csrf" "lass")
  :components ((:file "package")
               (:file "cl-web-demo")))
