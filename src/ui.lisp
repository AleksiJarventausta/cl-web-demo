
(in-package :cl-user)
(uiop:define-package :reseptit/ui
  (:use :cl)
  (:import-from :snooze
                #:*clack-request-env*)
  (:import-from :reseptit/ui-utils
                #:get-css)
  (:import-from :lack.middleware.csrf
                #:csrf-token)
  (:export #:page))
(in-package :reseptit/ui)


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
               (:main
                ,@body))))))
