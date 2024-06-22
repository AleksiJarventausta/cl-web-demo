(in-package :cl-user)
(uiop:define-package :cl-web-demo/types
  (:use :cl)
  (:import-from :mito
                #:deftable)
  (:export #:todo
           #:todo-title
           #:todo-id
           ))

(in-package :cl-web-demo/types)

(deftable todo ()
   ((title :col-type (:varchar 256) ))
  )
