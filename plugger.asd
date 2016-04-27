;;;; plugger.asd

(asdf:defsystem #:plugger
  :description "Describe plugger here"
  :author "Your Name <your.name@example.com>"
  :license "Specify license here"
  :serial t
  :depends-on (#:lisp-unit #:cl-fad)
  :components ((:file "package")
               (:file "plugger-test")
               (:file "plugger")))
