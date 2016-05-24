(in-package #:plugger-test)

(define-test included-plugins-test
  (multiple-value-bind (success loaded) (load-plugins "./test_plugins/load" :included-plugins nil)
    (assert-equal 0 success)
    (assert-equal nil loaded)))
(define-test excluded-plugins-test
  (multiple-value-bind (success loaded) (load-plugins "./test_plugins/load" :excluded-plugins '("plugin"))
    (assert-equal 0 success )
    (assert-equal nil loaded )))
(define-test basic-load-test
  (multiple-value-bind (success loaded) (load-plugins "./test_plugins/load")
    (assert-equal 1 success )
    (assert-equal '(("plugin" . :success)) loaded ) ))
(define-test error-test
  (multiple-value-bind (success loaded) (load-plugins "./test_plugins/load-failure")
    (assert-equal 0 success)
    (assert-equal '(("plugin" . :error)) loaded )))
(define-test load-order-test
  (multiple-value-bind (success loaded) (load-plugins "./test_plugins/load-order" :load-order-test #'string>)
    (assert-equal 2 success )
    (assert-equal '(("b" . :success)
                    ("a" . :success)) loaded )))
(define-test plugin-defhook-test
  (setf *plugger-hooks* nil)
  (assert-equal (defplughook :test) '((:test))))
(define-test remove-functions-from-hook-test
  (setf *plugger-hooks* nil)
  (defplughook :test)
  (defun rm-hook-test () 0)
  (with-plug-hook 'test :test #'rm-hook-test)
  (remove-hook-func :test 'test)
  (assert-equal '((:test)) *plugger-hooks*))
(define-test plugin-with-hook-test
  (setf *plugger-hooks* nil)
  (defplughook :test)
  (defun hook-test () 0)
  (with-plug-hook 'test :test #'hook-test)
  (assert-equal `((:test (test . ,#'hook-test))) *plugger-hooks*))
(define-test plugin-hook-test
  (setq *plugger-hooks* nil)
  (defplughook :test)
  (with-plug-hook 'test :test (lambda () 0))
  (multiple-value-bind (success results) (trigger-hook :test ())
    (assert-equal success 1)
    (assert-equal results '((test :success (0))))))
(define-test plugin-hook-include-test
  (setq *plugger-hooks* nil)
  (defplughook :test)
  (with-plug-hook 'test :test (lambda () 0))
  (with-plug-hook 'foo :test (lambda () 0))
  (multiple-value-bind (success results) (trigger-hook :test () :includes-functions '(foo))
    (assert-equal success 1)
    (assert-equal results '((foo :success (0))))))
(define-test plugin-hook-exclude-test
  (setq *plugger-hooks* nil)
  (defplughook :test)
  (with-plug-hook 'test :test (lambda () 0))
  (multiple-value-bind (success results) (trigger-hook :test () :excludes-functions '(test))
    (assert-equal success 0)
    (assert-equal results nil)))
(define-test plugin-hook-removal-test
  (setq *plugger-hooks* nil)
  (defplughook :test)
  (with-plug-hook 'test :test (lambda () 0))
  (remove-hook :test)
  (assert-equal *plugger-hooks* '()))
(define-test plugin-functions-for-hook-test
  (setq *plugger-hooks* nil)
  (defplughook :test)
  (defun test-hook-function () 0)
  (with-plug-hook 'test :test #'test-hook-function)
  (assert-equal `((test . ,#'test-hook-function)) (functions-for-hook :test)))
(define-test plugin-hook-for-functions-test
  (setq *plugger-hooks* nil)
  (defplughook :test)
  (defun test-hook-function () 0)
  (with-plug-hook 'test :test #'test-hook-function)
  (assert-equal '(:test) (hook-for-function 'test)))
(define-test plugin-import-test
  (load-plugins "./test_plugins/import-test" :die-on-error t))
(define-test error-test-and-die
  (assert-error 'asdf/find-system:load-system-definition-error (load-plugins "./test_plugins/load-failure" :die-on-error t)))
(define-test hook-test-and-die
  (setq *plugger-hooks* nil)
  (defplughook :test)
  (with-plug-hook 'test :test (lambda (n) (/ 1 n)))
  (assert-error 'division-by-zero (trigger-hook :test (0) :die-on-error t)))
(define-test hook-test-error-inspection
  (setq *plugger-hooks* nil)
  (defplughook :test)
  (with-plug-hook 'test :test (lambda (n) (/ 1 n)))
  (multiple-value-bind (success loaded) (trigger-hook :test (0) :detailed-error t)
    (declare (ignore success))
    (assert-equal 'division-by-zero (type-of (cadr (car loaded))))))
(define-test quicklisp-test
  (multiple-value-bind (success loaded) (load-plugins "./test_plugins/quicklisp-test" :use-quicklisp t)
    (assert-equal 1 success )
    (assert-equal '(("plugin" . :success)) loaded )))
(define-test detailed-error-test
  (multiple-value-bind (success loaded) (load-plugins "./test_plugins/load-failure" :detailed-error t)
    (assert-equal 1 success )
    (assert-equal 'asdf/find-system:load-system-definition-error (type-of (cdar loaded)))))
