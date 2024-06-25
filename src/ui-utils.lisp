(in-package :cl-user)
(uiop:define-package :cl-web-demo/ui-utils
  (:use :cl)
  (:export #:get-css))
(in-package :cl-web-demo/ui-utils)

(defun get-css (name)
  (let ((css-mtime (sb-posix:stat-mtime (sb-posix:stat (asdf:system-relative-pathname :cl-web-demo (format nil "static-files/~a.css" name))))))
     (format nil "/public/~a.css?modified=~a" name css-mtime)))
