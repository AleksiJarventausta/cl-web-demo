
(in-package :cl-user)
(uiop:define-package :cl-web-demo
  (:use :cl :lack.middleware.csrf)
  (:import-from :cl-web-demo/types
                #:todo

                #:todo-id
                #:todo-title)
  (:export #:start))
(in-package :cl-web-demo)

(defvar *server* nil )
(defvar *app* (make-instance 'ningle:app))



(defun get-todos ()
  (mito:select-dao 'todo ))

(defmacro main-layout (&body body)
  (let* ((css-mtime (sb-posix:stat-mtime (sb-posix:stat (asdf:system-relative-pathname :cl-web-demo "static-files/main.css"))))
         (css-href (format nil "/public/main.css?modified=~a" css-mtime)))
    `(spinneret:with-html-string
       (:doctype)
       (:html
        (:head
         (:meta :charset "utf-8")
         (:meta :name "viewport" :content "width=device-width, initial-scale=1")
         (:link :rel "stylesheet" :href ,css-href)
         (:script :src "/public/htmx.min.js"))
        (:body :data-hx-headers (format nil "{\"X-CSRF-TOKEN\": \" ~a \"}" (csrf-token ningle:*session*))
         ,@body)))))

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
    (:li (todo-title todo)
         (:button :data-hx-delete (format nil "/todos/~a"
                                          (mito:object-id todo)) "Delete") )))


(defun todos-ui ()
  (spinneret:with-html (:ul#todos
                        (dolist (todo (get-todos))
                          (todo-ui todo)))))

(defun todo-add (title)
  (let ((todo (make-instance 'todo :title title)))
    (mito:insert-dao todo)
    (todo-ui todo)))

(defun todo-delete (todo-id)
  (bknr.datastore:delete-object (bknr.datastore:store-object-with-id todo-id)))

(defun todo-add-form ()
  (spinneret:with-html
    (:form :data-hx-post "/todos" :data-hx-target "#todos" :data-hx-swap "beforeend"
           (:input :name "title")
           (:button :type "submit" "Submiti"))))

(setf (ningle:route *app* "/" :method :get)
      #'(lambda (params)
          (main-layout (todos-ui) (todo-add-form))))

(setf (ningle:route *app* "/todos" :method :post)
      #'(lambda (params)
          (let ((req (lack.request:request-body-parameters ningle:*request*)))
            (spinneret:with-html-string
              (todo-add (cdr (assoc "title" req :test 'string=)))))))

(setf (ningle:route *app* "/todos/:id" :method :delete)
      #'(lambda (params)
          (let ((todo-id (parse-integer (cdr (assoc :id params)))))
            (todo-delete todo-id)
            (spinneret:with-html-string (:div "aa")))))

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
          *app*))))
