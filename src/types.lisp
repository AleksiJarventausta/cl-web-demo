(in-package :cl-user)
(uiop:define-package :cl-web-demo/types
  (:use :cl)
  (:export #:todo-title
           #:todo-id
           #:todo
           ))

(in-package :cl-web-demo/types)

(defclass todo (bknr.datastore:store-object)
  ((todo-id :accessor todo-id :initarg :todo-id)
   (title :accessor todo-title :initarg :title))
  (:metaclass bknr.datastore:persistent-class))
