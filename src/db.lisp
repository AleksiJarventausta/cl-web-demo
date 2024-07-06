(in-package :cl-user)
(uiop:define-package :reseptit/db
  (:use :cl)
  (:local-nicknames (:types :reseptit/types))
  (:import-from :reseptit/types
                #:recipe
                #:tag
                #:tag-name
                #:recipe-tags
                #:recipe-tags-tag
                )
  (:import-from :reseptit/config
                #:config)
  (:import-from :reseptit/utils
                #:form-list-field
                #:form-field)
  (:export #:recipe-with-id
           #:recipes
           #:delete-recipe
           #:update-recipe
           #:create-recipe
           #:tags
           #:init-db
           #:recipe-tags
           ))
(in-package :reseptit/db)

(defmacro with-db (&body body)
  `(let* ((db-conf (getf (config) :database-config))
          (mito:*connection* (apply #'dbi:connect-cached db-conf)))
     ,@body
     ))


(defun init-db ()
  (let* ((db-conf (getf (config) :database-config))
         (mito:*connection* (apply #'dbi:connect-cached db-conf)))
    (mito:ensure-table-exists 'recipe)
    (mito:ensure-table-exists 'tag)
    (mito:ensure-table-exists 'recipe-tags)))

(defun seed ()
  (let* ((db-conf (getf (config) :database-config))
         (mito:*connection* (apply #'dbi:connect-cached db-conf)))
    (init-tags)))

(defun recipe-with-id (recipe-id)
  (mito:find-dao 'recipe :id recipe-id))


(defun recipe-tags (recipe-id)
  (mapcar 'recipe-tags-tag
          (mito:select-dao 'recipe-tags
            (mito:includes 'tag)
            (sxql:where (:= :recipe-id recipe-id)))))

(defun recipes ()
  (mito:select-dao 'recipe ))

(defun tags ()
  (mito:select-dao 'tag))

(defun create-recipe (&key name (description ""))
  (let ((recipe (make-instance 'recipe :name name :description description)))
    (mito:insert-dao recipe)))

(defun init-tags ()
  (let ((vege (make-instance 'tag :name "vegaani" :description "Ei lihaa"))
        (gluteeniton (make-instance 'tag  :name "gluteeniton" :description "ei gluteenia")))
    (mito:ensure-table-exists 'tag)
    (mito:ensure-table-exists 'recipe-tags)
    (mito:insert-dao vege)
    (mito:insert-dao gluteeniton)))


(defun insert-tag (tag-id recipe)
  (mito:insert-dao (make-instance 'recipe-tags :recipe recipe :tag-id tag-id )))

(defun update-recipe (id params)
  (let ((name (form-field params "name"))
        (des (form-field params "description"))
        (tagss (form-list-field params "tags"))
        (recipe (recipe-with-id id)))
    (mito:delete-by-values 'recipe-tags :recipe recipe)
    (mapcar #'(lambda (id ) (insert-tag id recipe)) tagss)
    (setf (slot-value recipe 'types::name) name)
    (setf (slot-value recipe 'types::description) des)
    (when recipe
      (mito:save-dao recipe))
    recipe))

(defun delete-recipe (recipe-id)
  (mito:delete-by-values 'recipe :id recipe-id ))
