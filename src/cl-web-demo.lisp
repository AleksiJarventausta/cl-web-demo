
(in-package :cl-user)
(uiop:define-package :cl-web-demo
  (:use :cl :lack.middleware.csrf)
  (:import-from :snooze
                #:*clack-request-env*
                #:defroute)
  (:import-from :cl-web-demo/types
                #:todo
                #:todo-title)
  (:import-from :cl-web-demo/ui-utils
                #:get-css)
  (:export #:start))
(in-package :cl-web-demo)

(defvar *server* nil )
(defvar *app* (make-instance 'ningle:app))

(setq spinneret::*print-pretty* T)
(setq spinneret:*always-quote* T)
(setq spinneret:*html-style* :tree)


(defun get-todos ()
  (mito:select-dao 'todo ))

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
ningle:*session*
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

(defun todo-ui (todo)
  (spinneret:with-html
    (:li.box.f-row.justify-content\:space-between
     (:p (todo-title todo))
     (:button :data-hx-delete (format nil "/todos/~a" (mito:object-id todo)) "Delete"))))


(defun todos-ui ()
  (spinneret:with-html (:ul#todos
                        (dolist (todo (get-todos))
                          (todo-ui todo)))))

(defun todo-add (title)
  (let ((todo (make-instance 'todo :title title)))
    (mito:insert-dao todo)
    (todo-ui todo)))

(defun todo-delete (todo-id)
  (mito:delete-by-values 'todo :id todo-id ))

(defun todo-add-form ()
  (spinneret:with-html
    (:form :data-hx-post "/todos" :data-hx-target "#todos" :data-hx-swap "beforeend"
     (:input :name "title")
     (:button :type "submit" "Submiti"))))

;(setf (ningle:route *app* "/" :method :get)
;      #'(lambda (params)
;          (main-layout (todos-ui) (todo-add-form))))

(defroute home (:get "text/html")
  (main-layout (todos-ui) (todo-add-form)))

(defun params ()
  (lack.request:request-body-parameters (lack.request:make-request *clack-request-env* )))

(defroute todos (:post :application/x-www-form-urlencoded &optional id)
  (let ((req (params)))
    (spinneret:with-html-string
      (todo-add (cdr (assoc "title" req :test 'string=))))))

(defroute todos (:delete ignored-type  &optional id)
  (if id
      (todo-delete id)
      (snooze:http-condition 404 "no id provided")))
      

;(setf (ningle:route *app* "/todos" :method :post)
;      #'(lambda (params)
;          (let ((req (lack.request:request-body-parameters ningle:*request*)))
;            (spinneret:with-html-string
;              (todo-add (cdr (assoc "title" req :test 'string=)))))))

;(setf (ningle:route *app* "/todos/:id" :method :delete)
;      #'(lambda (params)
;          (let ((todo-id (parse-integer (cdr (assoc :id params)))))
;            (todo-delete todo-id)
;            (spinneret:with-html-string (:div "aa")))))

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
