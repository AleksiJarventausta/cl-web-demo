
(in-package :cl-user)
(uiop:define-package :reseptit/ui
  (:use :cl)
  (:import-from :snooze
                #:*clack-request-env*)
  (:import-from :reseptit/ui-utils
                #:get-css)
  (:import-from :lack.middleware.csrf
                #:csrf-token)
  (:export #:page
           #:link
           #:input
           #:form
           #:form-submit-row
           #:textarea))

(in-package :reseptit/ui)

(defmacro link (href text &body body)
  `(spinneret:with-html
    (:a :href ,href :hx-select "main" :hx-target "main" :hx-swap "outerHTML" ,@body ,text)))

(defun input (name value text &key (type "text") )
  (spinneret:with-html
  (:p
   (:label :for name text)
   (:input :id name :name name :value value :type type))))

(defun form-submit-row (cancel-uri)
  (spinneret:with-html
    (:section.tool-bar
     (:button :type "button" :hx-push-url "true" :hx-get cancel-uri :hx-select "main" :hx-target "main" :hx-swap "outerHTML" "Cancel")
     (:button :type "submit" "Submit"))))

(defmacro form (title &body body)
  `(spinneret:with-html
    (:figure
     (:figcaption ,title)
     (:form.table.rows :hx-target "main" :hx-select "main" :hx-swap "outerHTML" ,@body))))


(defun textarea (name value text )
  (spinneret:with-html
  (:p
   (:label :for name text)
   (:textarea :id name :name name value))))

(defmacro page (&body body)
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
               :hx-boost "true"
            (:header.navbar
             (:nav :aria-label "Page links"
               (:ul :role "list"
                (:li (link "/" "Home")))))
            (:main
                ,@body))))))
