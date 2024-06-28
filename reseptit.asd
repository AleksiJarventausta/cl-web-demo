(asdf:defsystem #:reseptit
  :description "Trying out htmx with common lisp"
  :license  "MIT"
  :version "0.0.1"
  :pathname "src"
  :serial t
  :depends-on (#:clack #:ningle #:spinneret #:alexandria "snooze" #:bknr.datastore "lack-middleware-csrf" "mito")
  :components ((:file "types")
               (:file "utils")
               (:file "db")
               (:file "ui-utils")
               (:file "ui")
               (:file "reseptit")))
