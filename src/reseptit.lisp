
(in-package :cl-user)
(uiop:define-package :reseptit
  (:use :cl :lack.middleware.csrf)
  (:local-nicknames (#:db #:reseptit/db)
                    (#:ui #:reseptit/ui))
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
                #:recipe-name)
  (:export #:start))
(in-package :reseptit)

(defvar *server* nil )

(setq spinneret::*print-pretty* T)
(setq spinneret:*always-quote* T)

(pushnew "hx-" spinneret:*unvalidated-attribute-prefixes* :test #'equal)

(setq spinneret:*html-style* :tree)
(setq snooze:*catch-errors* :verbose)


(defresource recipes (verb ct &optional id &key edit) (:genpath recipes-path))


(defun htmx-page-link (uri text &optional class)
  (spinneret:with-html
    (:a :href uri :hx-boost "true"  :hx-target "body" :hx-swap "innerHTML" text)))


(defun recipe-ui (recipe)
  (let ((id (mito:object-id recipe))
        (description (recipe-description recipe)))
  (spinneret:with-html
    (:li.box
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

(defun recipe-edit-form (recipe)
  (spinneret:with-html
    (ui:form "Edit" :method "PATCH" :action (recipes-path (mito:object-id recipe))
      (ui:input "name" (recipe-name recipe) "Name")
      (ui:textarea "description" (recipe-description recipe) "Description")
      (ui:form-submit-row "/"))))

(defun recipe-add-form ()
  (spinneret:with-html
    (:form.f-row :hx-post "/recipes" :hx-target "#recipes" :hx-swap "beforeend"
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

(defun recipe-page (recipe)
  (ui:page (:h1 (recipe-name recipe))
    (:p (recipe-description recipe))))

(defun recipe-show (id edit)
  (let ((recipe (db:recipe-with-id id)))
    (cond ((and recipe edit)
           (ui:page (recipe-edit-form recipe)))
          (recipe
           (recipe-page recipe))
          (t
           (ui:page (:p "ei löytynyt"))))))

(defroute recipes (:get :text/html  &optional id &key (edit nil))
  (if id
      (recipe-show id edit)
      (ui:page "kaikki")))

(defroute recipes (:patch :application/x-www-form-urlencoded  &optional id &key (edit nil))
  (let ((params (params)))
    (cond ((and id params)
           (db:update-recipe id params)
           (redirect-to (recipes-path id)))
          (t (snooze:http-condition 400 "No id provided")))))


(defun start (&key (port 5000))
  (when *server*
    (clack:stop *server*))
  (setf *server*
        (clack:clackup
         (lack:builder
          :session
          (:csrf :header-name "X-CSRF-TOKEN")
          (:static :path "/public/"
                   :root (asdf:system-relative-pathname :reseptit #P"static-files/"))
          (:mito '(:sqlite3 :database-name #P"/tmp/db.db"))
          (snooze:make-clack-app)))))
