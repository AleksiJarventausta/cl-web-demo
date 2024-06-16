
(in-package :cl-user)
(uiop:define-package :cl-web-demo
  (:use :cl :lack.middleware.csrf :cl-web-demo/types)
  (:export #:start)
  )
(in-package :cl-web-demo)

(defvar *server* nil )
(defvar *store* nil )
(defvar *app* (make-instance 'ningle:app))

(defun create-styles()
  (with-open-file (str (asdf:system-relative-pathname :cl-web-demo "static-files/main.css")
                       :direction :output
                       :If-does-not-exist :create
                       :if-exists :supersede)
    (format str (lass:compile-and-write
                 '(body
                   :background "pink"
                   )))))


(defun get-todos ()
  (bknr.datastore:store-objects-with-class 'todo))

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
        (:body
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

(defun todo-ui (tdd)
  (spinneret:with-html (:li (todo-title tdd) )))


(defun todos-ui ()
  (spinneret:with-html (:ul#todos
                        (dolist (tdd (get-todos))
                          (todo-ui tdd)))))

(defun todo-add (title)
  (let ((tdd (make-instance 'todo :title title)))
    (todo-ui tdd)))

(defun todo-add-form ()
  (spinneret:with-html
    (:form :data-hx-post "/todos" :data-hx-target "#todos" :data-hx-swap "beforeend"
           (:input :name "title")
           (:raw (lack.middleware.csrf:csrf-html-tag ningle:*session*))
           (:button :type "submit" "Submit"))))

(setf (ningle:route *app* "/" :method :get)
      #'(lambda (params)
          (main-layout (todos-ui) (todo-add-form))))

(setf (ningle:route *app* "/todos" :method :post)
      #'(lambda (params)
          (let ((req (lack.request:request-body-parameters ningle:*request*)))
            (spinneret:with-html-string
              (todo-add (cdr (assoc "title" req :test 'string=)))))))

(defun start (&key (port 5000))
  (when *server*
    (clack:stop *server*))
  (when *store*
    (bknr.datastore:close-store))
  (setf *store* (make-instance 'bknr.datastore:mp-store
                               :directory "~/bknr/tmp/object-store/"
                               :subsystems (list
                                            (make-instance
                                             'bknr.datastore:store-object-subsystem))))
  (setf *server*
        (clack:clackup
         (lack:builder
          :session
          :csrf
          (:static :path "/public/"
                   :root (asdf:system-relative-pathname :cl-web-demo #P"static-files/"))
          *app*))))
