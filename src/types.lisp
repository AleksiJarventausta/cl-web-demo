(in-package :cl-user)
(uiop:define-package :reseptit/types
  (:use :cl)
  (:import-from :mito
                #:deftable)
  (:export #:recipe
           #:recipe-name
           #:recipe-description
           #:recipe-id
           ))

(in-package :reseptit/types)

(deftable recipe ()
   ((name :col-type (:varchar 256) )
    (description :col-type :text)
    )
  )
