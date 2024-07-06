
(in-package :cl-user)
(uiop:define-package :reseptit/utils
  (:use :cl)
  (:import-from :reseptit/types
                #:recipe)
  (:import-from :snooze
                #:*clack-request-env*)
  (:import-from :alexandria
                #:assoc-value)
  (:export #:form-field
           #:redirect-to))
(in-package :reseptit/utils)
(defun form-field (params field)
  (assoc-value params field :test 'string=  ))

(defun form-list-field (params field)
  (mapcar 'cdr (remove field params :test-not #'string= :key #'car)))

(defun redirect-to (uri)
  (setf (hunchentoot:header-out :location) uri)
  (snooze:http-condition 303 ""))

(defun body-params ()
  (lack.request:request-body-parameters (lack.request:make-request *clack-request-env* )))
