;;;; plugger.lisp

(in-package #:plugger)
(defparameter *plugger-hooks* nil)
(defparameter *plugin-package* :plugger-plugins)
(defun reset-plugins ()
  (setf asdf:*central-registry* '(#P"/home/jake/quicklisp/quicklisp/")))
;;; "plugger" goes here. Hacks and glory await!
(defun system-for-directory (directory)
  (car (last (pathname-directory directory))))
(defun load-plugins (directory &key (included-plugins 'all) excluded-plugins (load-order-test #'string<) die-on-error (plugger-namespace :plugger-plugins))
  (setf *plugin-package* plugger-namespace)
  (let ((dir (pathname directory)))
    (let ((loaded-plugins (mapcar (lambda (path)
                                    (when (cl-fad:directory-pathname-p path)
                                      (when (null (member path asdf:*central-registry* :test #'equal))
                                        (pushnew path asdf:*central-registry*))
                                      (let* ((system (system-for-directory path)))
                                        (when (and (null (member system excluded-plugins :test #'equal)) (or (equal included-plugins 'all) (member system included-plugins :test #'equal)))
                                          (handler-case (asdf:operate 'asdf:load-op system)
                                            (error (&rest vars) (declare (ignore vars)) (if die-on-error
                                                                                            (error 'error :text "load error")
                                                                                            (cons system :error)))
                                            (:no-error (&rest vars) (declare (ignore vars)) (cons system :success)))))))
                                  (sort (cl-fad:list-directory dir) load-order-test :key #'system-for-directory))))
      (values (length (remove-if (lambda (pl) (or (eql (cdr pl) :error) (null pl)) ) loaded-plugins)) (remove-if #'null loaded-plugins)))))
(defmacro defplugfun (name args &body body)
  `(progn
     (defun ,name ,args
       ,@body)
     (shadowing-import ',name ,*plugin-package*)
     (export ',name ,*plugin-package*)))

(defmacro defplugmac (name args &body body)
  `(progn
     (defmacro ,name ,args
       ,@body)
     (shadowing-import ',name ,*plugin-package*)
     (export ',name ,*plugin-package*)))

(defmacro defplugvar (name value)
  `(progn
     (defparameter ,name ,value)
     (shadowing-import ',name ,*plugin-package*)
     (export ',name ,*plugin-package*)))
(defun defplughook (hook-name)
  "Define a plugin hook"
  (pushnew (list hook-name) *plugger-hooks*))

(defun with-plug-hook (name hook function)
  (push (cons name function) (cdr (assoc hook *plugger-hooks*))))
(defmacro trigger-hook (hook-name (&rest args) &key excludes-functions includes-functions die-on-error)
  `(let ((results (mapcar (lambda (r) (handler-case (funcall (cdr r) ,@args)
                                        (error (&rest vars) (declare (ignore vars)) (list (car r) :error nil))
                                        (:no-error (&rest return-values) (list (car r) :success return-values)))) (cdr (assoc ,hook-name *plugger-hooks*)))))
     (values (length (remove-if (lambda (k) (eql k :error)) results :key #'cadr)) results)))
