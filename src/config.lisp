
(in-package :cl-user)
(uiop:define-package :reseptit/config
  (:use :cl )
  (:import-from :envy
                #:defconfig
                #:config-env-var)
  (:export #:config))
(in-package :reseptit/config)

(setf (config-env-var) "APP_ENV")

(defparameter *application-root*   (asdf:system-source-directory :reseptit))

(defconfig :common
  `(:application-root ,*application-root*
    :static-directory ,(merge-pathnames #P"static-files/" *application-root*)))

(defconfig |development|
  `(:debug T
    :database-config ,(list :sqlite3 :database-name (merge-pathnames #P"db/sqlite3.db" *application-root*))))


(defun config ()
  (envy:config #.(package-name *package*)))

