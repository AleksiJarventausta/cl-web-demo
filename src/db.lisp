(in-package :cl-user)
(uiop:define-package :cl-web-demo/db
  (:use :cl)
  (:import-from :cl-web-demo/types
                #:recipe)
  (:export #:recipe-with-id
           #:recipes
           #:delete-recipe
           #:create-recipe))
(in-package :cl-web-demo/db)


(defun recipe-with-id (recipe-id)
  (mito:find-dao 'recipe :id recipe-id))

(defun recipes ()
  (mito:select-dao 'recipe ))

(defun create-recipe (&key name (description ""))
  (let ((recipe (make-instance 'recipe :name name :description description)))
    (mito:insert-dao recipe)))

(defun delete-recipe (recipe-id)
  (mito:delete-by-values 'recipe :id recipe-id ))
