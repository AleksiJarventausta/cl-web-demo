(in-package :cl-user)
(uiop:define-package :reseptit/ui-utils
  (:use :cl)
  (:import-from :reseptit/config
                #:config)
  (:export #:get-css))
(in-package :reseptit/ui-utils)

(defun get-css (name)
  (let* ((static-directory (getf (config) :static-directory))
        (css-mtime (sb-posix:stat-mtime (sb-posix:stat (merge-pathnames (format nil "~a.css" name) static-directory)))))
     (format nil "/public/~a.css?modified=~a" name css-mtime)))
