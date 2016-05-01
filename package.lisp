;;;; package.lisp

(defpackage #:plugger
  (:use #:cl #:cl-fad)
  (:export load-plugins reset-plugins defplugfun defplugmac defplugvar *plugger-hooks* *plugin-package* defplughook with-plug-hook trigger-hook remove-hook functions-for-hook hook-for-function remove-hook-func defapifun defapimac defapivar))

(defpackage #:plugger-plugin-user)
(defpackage #:plugger-plugins
  (:use #:cl #:plugger #:lisp-unit))
(defpackage #:plugger-test
  (:use #:cl #:plugger #:plugger-plugins #:lisp-unit #:plugger-plugin-user))
