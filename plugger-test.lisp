(in-package #:plugger-test)

(define-test included-plugins-test
  (multiple-value-bind (success loaded) (load-plugins "test_plugins/load" :included-plugins nil)
    (reset-plugins)
    (assert-equal 0 success)
    (assert-equal nil loaded)))
(define-test excluded-plugins-test
  (multiple-value-bind (success loaded) (load-plugins "test_plugins/load" :excluded-plugins '("plugin"))
    (reset-plugins)
    (assert-equal 0 success )
    (assert-equal nil loaded )))
(define-test basic-load-test
  (multiple-value-bind (success loaded) (load-plugins "test_plugins/load")
    (reset-plugins)
    (assert-equal 1 success )
    (assert-equal '(("plugin" . :success)) loaded ) ))
(define-test error-test
  (multiple-value-bind (success loaded) (load-plugins "test_plugins/load-failure")
    (reset-plugins)
    (assert-equal 0 success)
    (assert-equal '(("plugin" . :error)) loaded )))
(define-test load-order-test
  (multiple-value-bind (success loaded) (load-plugins "test_plugins/load-order" :load-order-test #'string>)
    (reset-plugins)
    (assert-equal 2 success )
    (assert-equal '(("b" . :success)
                    ("a" . :success)) loaded )))
(define-test plugin-import-test
  (load-plugins "test_plugins/import-test" :die-on-error t))
(define-test error-test-and-die
  (reset-plugins)
  (assert-error 'error (load-plugins "test_plugins/load-failure" :die-on-error t)))
