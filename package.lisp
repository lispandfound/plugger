;;;; package.lisp

(defpackage #:plugger
  (:use #:cl #:cl-fad)
  (:export load-plugins reset-plugins defplugfun defplugmac defplugvar))

(defpackage #:plugger-user
  (:use #:cl #:plugger #:lisp-unit))
(defpackage #:plugger-test
  (:use #:cl #:plugger #:plugger-user #:lisp-unit))
