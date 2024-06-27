
(in-package :cl-user)
(uiop:define-package :reseptit
  (:use :cl :lack.middleware.csrf)
  (:LOCAL-NICKNAMES (#:db #:reseptit/db))
  (:import-from :snooze
                #:*clack-request-env*
                #:defresource
                #:defroute)

  (:import-from :reseptit/types
                #:recipe
                #:recipe-name)
  (:import-from :reseptit/ui-utils
                #:get-css)
  (:export #:start))
(in-package :reseptit)

(defvar *server* nil )

(setq spinneret::*print-pretty* T)
(setq spinneret:*always-quote* T)

(pushnew "hx-" spinneret:*unvalidated-attribute-prefixes* :test #'equal)

(setq spinneret:*html-style* :tree)
(setq snooze:*catch-errors* :verbose)


(defresource recipes (verb ct &optional id &key edit) (:genpath recipes-path))


(defun get-css (name)
  (let ((css-mtime (sb-posix:stat-mtime (sb-posix:stat (asdf:system-relative-pathname :reseptit (format nil "static-files/~a.css" name))))))
    (format nil "/public/~a.css?modified=~a" name css-mtime)))

(defmacro main-layout (&body body)
  (let ((main-css (get-css "main"))
        (missing-css (get-css "missing.min")))
    `(spinneret:with-html-string
       (:doctype)
       (:html
        (:head
         (:meta :charset "utf-8")
         (:meta :name "viewport" :content "width=device-width, initial-scale=1")
         (:link :rel "stylesheet" :href ,missing-css)
         (:link :rel "stylesheet" :href ,main-css)
         (:script :src "/public/htmx.min.js"))
        (:body :hx-headers (format nil "{\"X-CSRF-TOKEN\": \" ~a \"}" (csrf-token (getf *clack-request-env* :lack.session)))
               (:main
                ,@body))))))

(defun htmx-page-link (uri text &optional class)
  (spinneret:with-html
    (:a :href uri :hx-boost "true"  :hx-target "body" :hx-swap "innerHTML" text)))


(defun recipe-ui (recipe)
  (spinneret:with-html
    (:li.box.f-row.justify-content\:space-between
     (:p (recipe-name recipe))
     (:button :hx-delete (recipes-path (mito:object-id recipe)) "Delete"))))


(defun recipes-ui ()
  (spinneret:with-html (:ul#recipes
                        (dolist (recipe (db:recipes))
                          (recipe-ui recipe)))))

(defun recipe-add (name)
  (let ((recipe (db:create-recipe :name name)))
    (recipe-ui recipe)))

(defun recipe-edit-form (recipe))

(defun recipe-add-form ()
  (spinneret:with-html
    (:form :hx-post "/recipes" :hx-target "#recipes" :hx-swap "beforeend"
           (:input#name :name "name")
           (:button :type "submit" "Submiti"))))

                                        ;(setf (ningle:route *app* "/" :method :get)
                                        ;      #'(lambda (params)
                                        ;          (main-layout (recipes-ui) (todo-add-form))))

(defroute home (:get "text/html")
  (main-layout (recipes-ui) (recipe-add-form)))

(defun params ()
  (lack.request:request-body-parameters (lack.request:make-request *clack-request-env* )))

(defroute recipes (:post :application/x-www-form-urlencoded &optional id &key (edit nil))
  (let ((req (params)))
    (spinneret:with-html-string
      (recipe-add (cdr (assoc "name" req :test 'string=))))))

(defroute recipes (:delete ignored-type  &optional id &key (edit nil))
  (if id
      (db:delete-recipe id)
      (snooze:http-condition 404 "no id provided")))


(defun recipe-show (id edit)
  (mito:ensure-table-exists 'recipe)
  (let ((recipe (db:recipe-with-id id)))
    (cond ((and recipe edit)
           (main-layout (:p "editoi")))
          (recipe
           (main-layout (:p "katso")))
          (t
           (main-layout (:p "ei löytynyt"))))))

(defroute recipes (:get :text/html  &optional id &key (edit nil))
  (if id
      (recipe-show id edit)
      (main-layout "kaikki")))


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
