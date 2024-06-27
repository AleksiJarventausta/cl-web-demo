(in-package :cl-user)
(uiop:define-package :reseptit/ui-utils
  (:use :cl)
  (:export #:get-css))
(in-package :reseptit/ui-utils)

(defun get-css (name)
  (let ((css-mtime (sb-posix:stat-mtime (sb-posix:stat (asdf:system-relative-pathname :reseptit (format nil "static-files/~a.css" name))))))
     (format nil "/public/~a.css?modified=~a" name css-mtime)))
