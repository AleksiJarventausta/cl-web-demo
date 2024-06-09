(in-package #:cl-web-demo)

(defvar *app* (make-instance 'ningle:app))

(defvar *contacts* '((:id 1 :name "John" :email "john@doe.com")
                     (:id 2 :name "Matti" :email "matti@mattilainen.fi")))


(defmacro main-layout (&body body)
  `(spinneret:with-html-string
     (:doctype)
     (:html
      (:head
       (:meta :charset "utf-8")
       (:meta :name "viewport" :content "width=device-width, initial-scale=1")
       (:script :src "https://unpkg.com/htmx.org@1.9.9")
      (:body
       (:section :class "container"
                 (:div :class "row"
                       ,@body)))))))


(defun htmx-request? ()
  (let ((hx-header (gethash  "hx-request" (lack.request:request-headers ningle:*request*))))
   (string= "true" hx-header)))

(defmacro htmx-layout (&body body)
  `(if (htmx-request?)
       (spinneret:with-html-string ,@body)
       (main-layout ,@body)))


(defun list-contacts ()
  (spinneret:with-html (:ul)
    (dolist (contact *contacts*)
      (let ((get-route (format nil "/contact/~a" (getf contact :id))))
        (:li (getf contact :name) (:button :data-hx-get get-route "muokkaa"))))))

(setf (ningle:route *app* "/" :method :get)
      #'(lambda (params)
          (let ((headers (getf params :content-type)))
            (main-layout (list-contacts)))))


(setf (ningle:route *app* "/contact/:id" :method :get)
      #'(lambda (params)
          (let* ((id (parse-integer (cdr (assoc :id params))))
                 (contact (find-if #'(lambda (c) (eq (getf c :id) id)) *contacts*)))
            (htmx-layout (:div (getf contact :name) id)))))

(clack:clackup *app*)
