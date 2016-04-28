;;;; plugger.lisp

(in-package #:plugger)

(defun reset-plugins ()
  (setf asdf:*central-registry* '(#P"/home/jake/quicklisp/quicklisp/")))
;;; "plugger" goes here. Hacks and glory await!
(defun system-for-directory (directory)
  (car (last (pathname-directory directory))))
(defun load-plugins (directory &key (included-plugins 'all) excluded-plugins (load-order-test #'string<) die-on-error)

  (let ((dir (pathname (format nil "~A~A" (truename #P".") directory))))
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
     (shadowing-import ',name :plugger-user)
     (export ',name :plugger-user)))

(defmacro defplugmac (name args &body body)
  `(progn
     (defmacro ,name ,args
       ,@body)
     (shadowing-import ',name :plugger-user)
     (export ',name :plugger-user)))

(defmacro defplugvar (name value)
  `(progn
     (defparameter ,name ,value)
     (shadowing-import ',name :plugger-user)
     (export ',name :plugger-user)))
