(in-package :cl-user)
(uiop:define-package :reseptit/types
  (:use :cl)
  (:import-from :mito
                #:deftable)
  (:export #:recipe
           #:recipe-name
           #:recipe-description
           #:recipe-id
           #:tag
           #:recipe-tags))

(in-package :reseptit/types)

(deftable tag ()
  ((name :col-type (:varchar 64))
   (description :col-type :text)))

(deftable recipe ()
   ((name :col-type (:varchar 256) )
    (description :col-type :text)))

(deftable recipe-tags ()
  ((recipe :col-type recipe)
   (tag :col-type tag)))
