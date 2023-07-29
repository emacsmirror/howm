;;; gfunc.el --- support for generic function
;;; Copyright (C) 2005-2022
;;;   HIRAOKA Kazuyuki <kakkokakko@gmail.com>
;;;
;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 1, or (at your option)
;;; any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; The GNU General Public License is available by anonymouse ftp from
;;; prep.ai.mit.edu in pub/gnu/COPYING.  Alternately, you can write to
;;; the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139,
;;; USA.
;;;--------------------------------------------------------------------

;; sample
;; 
;; (defun less-than:num (x y)
;;   (< x y))
;; (defun less-than:str (x y)
;;   (string< x y))
;; (defun type-of (x y)
;;   (cond ((numberp x) ':num)
;;         ((stringp x) ':str)))
;; (defvar disp-list (list #'type-of))
;; (gfunc-define-function less-than (x y) disp-list)  ;; --- <*>
;; (less-than 3 8)          ;; (less-than:num 3 8)         ==> t
;; (less-than "xyz" "abc")  ;; (less-than:str "xyz" "abc") ==> nil
;; (pp (macroexpand '(gfunc-def less-than (x y) disp-list)))
;; 
;; ;; This is equivalent to above <*>.
;; (gfunc-with disp-list
;;   (gfunc-def less-than (x y))
;;   ;; You can insert more methods here. For example...
;;   ;; (less-or-equal (x y))
;;   ;; (more-than (x y))
;;   )

(defvar *gfunc-dispatchers-var* nil
  "For internal use")
(put '*gfunc-dispatchers-var* 'risky-local-variable t)

;; loop version
(defun gfunc-call (base-name dispatchers args)
  (let (type)
    (catch 'done
      (while dispatchers
        (setq type (apply (car dispatchers) args))
        (if type
            (throw 'done
                   (apply (intern-soft (format "%s%s" base-name type))
                          args))
          (setq dispatchers (cdr dispatchers))))
      (error "Can't detect type of %s for %s." args base-name))))

;; (defun gfunc-call (base-name dispatchers args)
;;   (if (null dispatchers)
;;       (error "Can't detect type of %s for %s." args base-name)
;;     (let ((type (apply (car dispatchers) args)))
;;       (if (null type)
;;           (gfunc-call base-name (cdr dispatchers) args)
;;         (let ((f (intern-soft (format "%s%s" base-name type))))
;;           (apply f args))))))

;; (put 'gfunc-def 'lisp-indent-hook 2)
(defmacro gfunc-define-function (base-name args-declaration dispatchers-var
                                           &optional description)
  "Define generic function.
BASE-NAME is name of generic function.
ARGS-DECLARATION has no effect; it is merely note for programmers.
DISPATCHERS-VAR is name of variable whose value is list of type-detectors.
Type-detector receives arguments to the function BASE-NAME, and returns
its 'type' symbol.
Then, BASE-NAME + type is the name of real function.
Type detector must return nil if it cannot determine the type, so that
the task is chained to next detector."
  (let ((desc-str (format "%s

ARGS = %s

Internally, %s___ is called according to the type of ARGS.
The type part ___ is determined by functions in the list `%s'.
This function is generated by `gfunc-define-function'."
                          (or description "Generic function.")
                          args-declaration
                          base-name
                          dispatchers-var)))
    `(defun ,base-name (&rest args)
       ,desc-str
       (gfunc-call (quote ,base-name) ,dispatchers-var args))))

(defmacro gfunc-def (base-name args-declaration &optional description)
  "Define generic function like `gfunc-define-function'.
The only difference is omission of dispatchers; it must be specified
by `gfunc-with' outside."
  (declare (indent 2))
  `(gfunc-define-function ,base-name ,args-declaration ,*gfunc-dispatchers-var*
                          ,description))

(defmacro gfunc-with (dispatchers-var &rest body)
  "With the defalut DISPATCHERS-VAR, execute BODY.
BODY is typically a set of `gfunc-def', and DISPATCHERS-VAR is used
as their dispatchers.
This macro cannot be nested."
  (declare (indent 1))
  ;; Be careful to etc/NEWS in Emacs 24.3 or
  ;; http://www.masteringemacs.org/articles/2013/03/11/whats-new-emacs-24-3/
  ;; "Emacs tries to macroexpand interpreted (non-compiled) files during load."
  (setq *gfunc-dispatchers-var* dispatchers-var)
  `(eval-and-compile
     ,@body))

(provide 'gfunc)

;;; gfunc.el ends here
