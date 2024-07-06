
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
           #:select
           #:form
           #:form-submit-row
           #:textarea))

(in-package :reseptit/ui)

(defmacro link (href text &body body)
  `(spinneret:with-html
     (:a :href ,href :hx-select "main" :hx-target "main" :hx-swap "outerHTML" ,@body ,text)))

(spinneret:deftag input (default attrs  &key name label (type "text") )
  (alexandria:once-only (name)
    `(progn (:p
             (:label :for ,name ,label)
             (:input :id ,name :name ,name :type ,type
               ,@attrs
               :value (progn ,@default))))))

(spinneret:deftag select (default attrs &key name label)
  (alexandria:once-only (name)
    `(progn
       (:p
        (:label :for ,name ,label)
        (:select :id ,name :name ,name ,@attrs (progn ,@default)))
       )
    )
  )

(spinneret:deftag form (default attrs &key caption id (cancel-action "/"))
  (alexandria:once-only (id)
    `(progn
       (:figure
        (:figcaption.<h2> ,caption)
        (:form.table.rows :id ,id :hx-target "main" :hx-select "main" :hx-swap "outerHTML"
                          ,@attrs
                          (progn ,@default))
        (:section.tool-bar
         (:a.<button> :hx-push-url "true" :hx-get ,cancel-action :hx-select "main" :hx-target "main" :hx-swap "outerHTML" "Cancel")
         (:strong
          (:button :form ,id :type "submit" "Submit")))))))


(spinneret:deftag textarea (default attrs &key name label (rows 4) )
  (alexandria:once-only (name)
    `(progn
       (:p
        (:label :for ,name ,label)
        (:textarea :id ,name :name ,name :rows ,rows ,@attrs (progn ,@default))))))

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
