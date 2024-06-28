(in-package :cl-user)
(uiop:define-package :reseptit/db
  (:use :cl)
  (:local-nicknames (:types :reseptit/types))
  (:import-from :reseptit/types
                #:recipe)
  (:import-from :reseptit/utils
                #:form-field)
  (:export #:recipe-with-id
           #:recipes
           #:delete-recipe
           #:update-recipe
           #:create-recipe))
(in-package :reseptit/db)


(defun recipe-with-id (recipe-id)
  (mito:find-dao 'recipe :id recipe-id))

(defun recipes ()
  (mito:select-dao 'recipe ))

(defun create-recipe (&key name (description ""))
  (let ((recipe (make-instance 'recipe :name name :description description)))
    (mito:insert-dao recipe)))

(defun update-recipe (id params)
  (let ((name (form-field params "name"))
        (des (form-field params "description"))
        (recipe (recipe-with-id id)))
  (setf (slot-value recipe 'types::name) name)
  (setf (slot-value recipe 'types::description) des)
  (when recipe
    (mito:save-dao recipe))
  recipe))

(defun delete-recipe (recipe-id)
  (mito:delete-by-values 'recipe :id recipe-id ))
