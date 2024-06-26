(in-package :cl-user)
(uiop:define-package :cl-web-demo/types
  (:use :cl)
  (:import-from :mito
                #:deftable)
  (:export #:recipe
           #:recipe-name
           #:recipe-description
           #:recipe-id
           ))

(in-package :cl-web-demo/types)

(deftable recipe ()
   ((name :col-type (:varchar 256) )
    (description :col-type :text)
    )
  )
