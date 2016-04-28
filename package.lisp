;;;; package.lisp

(defpackage #:plugger
  (:use #:cl #:cl-fad)
  (:export load-plugins reset-plugins))
(defpackage #:plugger-test
  (:use #:cl #:plugger #:lisp-unit))
