;;;; plugin.asd
(asdf:defsystem #:plugin
  :description "Describe plugin here"
  :author "Your Name <your.name@example.com>"
  :license "Specify license here"
  :serial t
  :depends-on (#:vecto)
  :components ((:file "package")
               (:file "plugin")))
