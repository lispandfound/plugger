;;;; plugger.lisp

(in-package #:plugger)
(defparameter *plugger-hooks* nil)
(defun reset-plugins ()
  (setf asdf:*central-registry* '(#P"/home/jake/quicklisp/quicklisp/")))
;;; "plugger" goes here. Hacks and glory await!
(defun system-for-directory (directory)
  (car (last (pathname-directory directory))))
(defun defplughook (hook-name)
  "Define a plugin hook"
  (pushnew (list hook-name) *plugger-hooks*))
(defmacro trigger-hook (hook-name (&rest args) &key (excludes-functions nil) (includes-functions :all) die-on-error)
  `(let ((results (mapcar (lambda (r) (handler-case (funcall (cdr r) ,@args)
                                   (error (&rest vars)  (if ,die-on-error
                                                            (error (type-of (car vars)) :text "Error Occurred" )
                                                            (list (car r) :error nil)))
                                        (:no-error (&rest return-values) (list (car r) :success return-values)))) (remove-if
                                                                                                                   (lambda (function)
                                                                                                                     (cond
                                                                                                                       ((null ,includes-functions) t)
                                                                                                                       ((and (null ,excludes-functions) (equal ,includes-functions :all)) nil)
                                                                                                                       ((and (not (null ,includes-functions)) (not (equal ,includes-functions :all))) (not (member function ,includes-functions)))
                                                                                                                       (t (member function ,excludes-functions))
                                                                                                                       ))
                                                                                                                   (cdr (assoc ,hook-name *plugger-hooks*)) :key #'car))))
     (values (length (remove-if (lambda (k) (eql k :error)) results :key #'cadr)) results)))
(defun load-plugins (directory &key (included-plugins 'all) excluded-plugins (load-order-test #'string<) die-on-error (plugger-namespace 'none) use-quicklisp detailed-error)
  (when (not (equal plugger-namespace 'none))
    (set-plugin-package plugger-namespace))
  (defplughook :unload)
  (defplughook :load)
  (let ((dir (pathname directory)))
    (let ((loaded-plugins (mapcar (lambda (path)
                                    (when (cl-fad:directory-pathname-p path)
                                      (when (null (member path asdf:*central-registry* :test #'equal))
                                        (pushnew path asdf:*central-registry*))
                                      (let* ((system (system-for-directory path)))
                                        (when (and (null (member system excluded-plugins :test #'equal)) (or (equal included-plugins 'all) (member system included-plugins :test #'equal)))
                                          (handler-case (if use-quicklisp
                                                            (ql:quickload system)
                                                            (asdf:operate 'asdf:load-op system))
                                            (error (&rest vars)  (if die-on-error
                                                                     (progn
                                                                       (error (type-of (car vars)) :text "load error"))
                                                                     (cons system (if detailed-error
                                                                                      (car vars)
                                                                                      :error))))
                                            (:no-error (&rest vars) (declare (ignore vars)) (cons system :success)))))))
                                  (sort (cl-fad:list-directory dir) load-order-test :key #'system-for-directory))))

      (values (length (remove-if (lambda (pl) (or (eql (cdr pl) :error) (null pl)) ) loaded-plugins)) (remove-if #'null loaded-plugins) (trigger-hook :load () :die-on-error die-on-error)))))
(defmacro shadow-import-export (name package)
  `(progn
     (shadowing-import ',name ,package)
     (export ',name ,package)))
(defmacro defun-for-package (package name args &body body)
  `(progn
     (defun ,name ,args
       ,@body)
     (shadow-import-export ,name ,package)))
(defmacro defmacro-for-package (package name args &body body)
  `(progn
     (defmacro ,name ,args
       ,@body)
     (shadow-import-export ,name ,package)))
(defmacro defvar-for-package (package name value)
  `(progn
     (defparameter ,name ,value)
     (shadow-import-export ,package ,name)))

(defmacro set-plugin-package (package)
  `(defvar-for-package :plugger *plugin-package* ,package))
(defmacro set-api-package (package)
  `(defvar-for-package :plugger *api-package* ,package))
(defmacro defplugfun (name args &body body)
  `(defun-for-package ,*plugin-package* ,name ,args ,@body))

(defmacro defplugmac (name args &body body)
  `(defmacro-for-package ,*plugin-package* ,name ,args ,@body))
(defmacro defplugvar (name value)
  `(defvar-for-package ,*plugin-package* ,name ,value))
(defmacro defapifun (name args &body body)
  `(defun-for-package ,*api-package* ,name ,args ,@body))
(defmacro defapimac (name args &body body)
  `(defmacro-for-package ,*api-package* ,name ,args ,@body))
(defmacro defapivar (name value)
  `(defvar-for-package ,*api-package* ,name ,value))


(defun with-plug-hook (name hook function)
  (push (cons name function) (cdr (assoc hook *plugger-hooks*))))

(defun remove-hook (&rest hooks)
  (setf *plugger-hooks* (reduce (lambda (acc hook-name)
                                  (remove-if (lambda (hook) (eql hook hook-name)) acc :key #'car)) hooks :initial-value *plugger-hooks*)))
(defun functions-for-hook (hook-name)
  (cdr (assoc hook-name *plugger-hooks*)))
(defun hook-for-function (function-name)
  (mapcar #'car (remove-if (lambda (functions) (null (member function-name functions :key #'car))) *plugger-hooks* :key #'cdr)))
(defun remove-hook-func (hook-name &rest funcs)
  (setf (cdr (assoc hook-name *plugger-hooks*)) (remove-if (lambda (func) (member func funcs)) (cdr (assoc hook-name *plugger-hooks*)) :key #'car) ))
