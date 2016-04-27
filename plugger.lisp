;;;; plugger.lisp

(in-package #:plugger)

;;; "plugger" goes here. Hacks and glory await!
(defun load-plugins (directory &key included-plugins excluded-plugins load-order-test die-on-error)
  (setf asdf:*central-registry*
        (list* '*default-pathname-defaults*
               directory
               asdf:*central-registry*))
  (let ((success 0)
        (loaded-plugins nil))
    (cl-fad:walk-directory directory
                           #'(lambda (dir)
                             (let* ((system (pathname-name dir)))
                               (handler-case (asdf:operate 'asdf:load-op (make-symbol system))
                                 (setf loaded-plugins (push `((,system . error)) loaded-plugins ))
                                   (progn
                                     (setf loaded-plugins (push `((,system . success)) loaded-plugins ))
                                     (setf success (1+ success)))))))))
