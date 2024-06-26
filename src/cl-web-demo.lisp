
(in-package :cl-user)
(uiop:define-package :cl-web-demo
  (:use :cl :lack.middleware.csrf)
  (:import-from :snooze
                #:*clack-request-env*
                #:defresource
                #:defroute)
  (:import-from :cl-web-demo/types
                #:recipe
                #:recipe-name)
  (:import-from :cl-web-demo/ui-utils
                #:get-css)
  (:export #:start))
(in-package :cl-web-demo)

(defvar *server* nil )

(setq spinneret::*print-pretty* T)
(setq spinneret:*always-quote* T)
(setq spinneret:*html-style* :tree)
(setq snooze:*catch-errors* :verbose)


(defresource recipes (verb ct &optional id &key edit) (:genpath recipes-path))

(defun get-recipes ()
  (mito:select-dao 'recipe ))

(defun get-css (name)
  (let ((css-mtime (sb-posix:stat-mtime (sb-posix:stat (asdf:system-relative-pathname :cl-web-demo (format nil "static-files/~a.css" name))))))
    (format nil "/public/~a.css?modified=~a" name css-mtime)))

(defmacro main-layout (&body body)
  (let ((main-css (get-css "main"))
        (missing-css (get-css "missing.min"))
        )
    `(spinneret:with-html-string
       (:doctype)
       (:html
        (:head
         (:meta :charset "utf-8")
         (:meta :name "viewport" :content "width=device-width, initial-scale=1")
         (:link :rel "stylesheet" :href ,missing-css)
         (:link :rel "stylesheet" :href ,main-css)
         (:script :src "/public/htmx.min.js"))
        (:body :data-hx-headers (format nil "{\"X-CSRF-TOKEN\": \" ~a \"}" (csrf-token (getf *clack-request-env* :lack.session)))
               (:main
                ,@body))))))

(defun htmx-page-link (uri text &optional class)
  (spinneret:with-html
    (:a :href uri :data-hx-get uri :data-hx-push-url "true" :data-hx-target "body" :data-hx-swap "innerHTML" text)))

(defun htmx-request? ()
  (let ((hx-header (gethash  "hx-request" (lack.request:request-headers ningle:*request*))))
    (string= "true" hx-header)))

(defmacro htmx-layout (&body body)
  `(if (htmx-request?)
       (spinneret:with-html-string ,@body)
       (main-layout ,@body)))

(defun recipe-ui (recipe)
  (spinneret:with-html
    (:li.box.f-row.justify-content\:space-between
     (:p (recipe-name recipe))
     (:button :data-hx-delete (recipes-path (mito:object-id recipe)) "Delete"))))


(defun recipes-ui ()
  (spinneret:with-html (:ul#recipes
                        (dolist (recipe (get-recipes))
                          (recipe-ui recipe)))))

(defun recipe-add (name)
  (let ((recipe (make-instance 'recipe :name name :description "")))
    (mito:insert-dao recipe)
    (recipe-ui recipe)))

(defun recipe-delete (recipe-id)
  (mito:delete-by-values 'recipe :id recipe-id ))
(defun recipe-edit-form (recipe)
  )

(defun recipe-add-form ()
  (spinneret:with-html
    (:form :data-hx-post "/recipes" :data-hx-target "#recipes" :data-hx-swap "beforeend"
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
      (recipe-delete id)
      (snooze:http-condition 404 "no id provided")))

(defun get-recipe (id)
  (mito:find-dao 'recipe :id id))

(defun recipe-show (id edit)
  (let ((recipe (get-recipe id)))
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
                   :root (asdf:system-relative-pathname :cl-web-demo #P"static-files/"))
          (:mito '(:sqlite3 :database-name #P"/tmp/db.db"))
          (snooze:make-clack-app)))))
