
(in-package :cl-user)
(uiop:define-package :reseptit
  (:use :cl :lack.middleware.csrf)
  (:local-nicknames (#:db #:reseptit/db)
                    (#:ui #:reseptit/ui))
  (:import-from :reseptit/config
                #:config)
  (:import-from :snooze
                #:*clack-request-env*
                #:defresource
                #:defroute)
  (:import-from :reseptit/utils
                #:body-params
                #:form-field
                #:redirect-to)
  (:import-from :reseptit/types
                #:recipe
                #:recipe-description
                #:recipe-name
                #:tag
                #:tag-name
                )
  (:export #:start))
(in-package :reseptit)

(defvar *server* nil )

(setq spinneret::*print-pretty* T)
(setq spinneret:*always-quote* T)

(pushnew "hx-" spinneret:*unvalidated-attribute-prefixes* :test #'equal)

(setq spinneret:*html-style* :tree)
(setq snooze:*catch-errors* :verbose)


(defresource recipes (verb ct &optional id &key edit) (:genpath recipes-path))


(defun recipe-ui (recipe)
  (let ((id (mito:object-id recipe))
        (description (recipe-description recipe))
        (tags (db:recipe-tags id)))
    (spinneret:with-html
      (:li.box.crowded
       (ui:link (recipes-path id )  (recipe-name recipe) :class "<h2>")
       (if (string= description "")
           (:p (:br))
           (:p description))
       (:div.f-row
        (ui:link (recipes-path id :edit T) "edit"))))))


(defun recipes-ui ()
  (spinneret:with-html
    (:ul.f-col.dense#recipes
     :role "list"
     (mapcar 'recipe-ui (db:recipes)))))

(defun recipe-add (name)
  (let ((recipe (db:create-recipe :name name)))
    (recipe-ui recipe)))

(defun tag-option (tag)
  (spinneret:with-html
    (:option :value (mito:object-id tag) (tag-name tag))))

(defun recipe-edit-form (recipe)
  (let ((form-id "recipe-form")
        (tags (db:tags)))
      (ui:form :id form-id :caption "Recipe" :method "PATCH" :action (recipes-path (mito:object-id recipe))
        (ui:input :name "name" :label "Name" (recipe-name recipe))
        (ui:select :multiple "true" :name "tags" :label "tags" (mapcar 'tag-option tags))
        (ui:textarea :name "description" :label "Description" (recipe-description recipe)))))

(defun recipe-add-form ()
  (spinneret:with-html
    (:form.f-row.packed :hx-post "/recipes" :hx-target "#recipes" :hx-swap "beforeend"
                        (:input.flex-grow\:1#name :name "name")
                        (:button :type "submit" "Submit"))))


(defroute home (:get "text/html")
  (ui:page (recipes-ui) (recipe-add-form)))

(defroute recipes (:post :application/x-www-form-urlencoded &optional id &key (edit nil))
  (let ((params (body-params)))
    (spinneret:with-html-string
      (recipe-add (form-field params "name")))))

(defroute recipes (:delete ignored-type  &optional id &key (edit nil))
  (cond (id
         (db:delete-recipe id)
         (spinneret:with-html-string (:p "Deleted!")))
        (t (snooze:http-condition 404 "no id provided"))))

(defun tag-chip (tag)
  (spinneret:with-html
    (:span.chip (tag-name tag))))

(defun recipe-page (recipe tags)
  (ui:page
    (:div.f-row.justify-content\:space-between.align-items\:center
     (:h1 (recipe-name recipe))
     (ui:link (recipes-path (mito:object-id recipe) :edit T) "edit"))
     (mapcar #'(lambda (tag) (:span.chip (tag-name tag))) tags)
    (:p (recipe-description recipe))))

(defun recipe-show (id edit)
  (let ((recipe (db:recipe-with-id id)))
    (cond ((and recipe edit)
           (ui:page (recipe-edit-form recipe)))
          (recipe
           (recipe-page recipe (db:recipe-tags (mito:object-id recipe))))
          (t
           (ui:page (:p "ei löytynyt"))))))

(defroute recipes (:get :text/html  &optional id &key (edit nil))
  (if id
      (recipe-show id edit)
      (ui:page "kaikki")))

(defroute recipes (:patch :application/x-www-form-urlencoded  &optional id &key (edit nil))
  (let ((params (body-params)))
    (cond ((and id params)
           (db:update-recipe id params)
           (redirect-to (recipes-path id)))
          (t (snooze:http-condition 400 "No id provided")))))


(defun start (&key (port 5000))
  (when *server*
    (clack:stop *server*))
  (db:init-db)
  (setf *server*
        (clack:clackup
         (lack:builder
          :session
          (:csrf :header-name "X-CSRF-TOKEN")
          (:static :path "/public/"
                   :root (asdf:system-relative-pathname :reseptit #P"static-files/"))
          (:mito (getf (config) :database-config))
          (snooze:make-clack-app)))))
