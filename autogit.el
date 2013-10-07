;; autogit-mode for GNU Emacs
;;
;; Version: alpha - 0.1 (not a true mode yet)
;; Copyright: Heikki Virtanen (2013)
;; License: GPL
;; Homepage: https://github.com/hessuvi/autogit-mode
;; 
;; Purpose: Keep working repository (and opened files) in sync with its
;;          upstream automatically.
;; 
;; Architecture:
;;   - Global mode. All open buffers visiting file in git repository are
;;     tracked by autogit. (Note: Autogit works in local mode, if current
;;     branch have no upstream set.)
;; 
;;   - Each repository is tracked separately.
;; 
;; Setting up:
;;   + Ones:
;;     - git config --global merge.conflictstyle diff3
;;     - git config --global push.default upstream
;; 
;;   + For each repository and branch, which are intended to be synced
;;     automatically:
;;     - git branch --set-upstream ...
;; 
;; Usage:
;;   - emacs --load <path to autogit.el>
;;   - autogit works seamlessly in background and no explicit actions are
;;     needed.
;; 
;; Hints:
;;   - Be careful with sensitive data! Setup your .gitignore in advance,
;;     if you do not have any other choice than keeping sensitive data
;;     within the repository.
;;   - If git merge --squash is used for integration, new session branch have
;;     to be created and have to be based on the tip of the integration branch.
;;   - Magit (http://magit.github.io/magit/) is still useful. This is not
;;     replacement of any Emacs' VC package.
;;   - GPG agent can be used as ssh-agent replacement. Advance is that
;;     private keys are decrypted only when needed.
;;
(defvar autogit-current-state nil)
(defvar autogit-open-buffers nil)
(defvar autogit-active nil)

(defun autogit-current-repository ()
  (let* ((tmp-name " command output")
         (tmp-buff (progn (if (get-buffer tmp-name) (kill-buffer tmp-name))
  			(get-buffer-create tmp-name)))
         (retcode (call-process "git" nil tmp-buff nil "rev-parse" "--git-dir"))
         (retval (if (eq 0 retcode)
  		   (with-current-buffer tmp-buff
  		     (buffer-substring-no-properties (point-min) (- (point-max) 1)))
  		 nil)))
    (if retval (file-truename retval) nil))
  )

(defun autogit-get-create-repo-obj ()
  (let* ((buff-name (autogit-current-repository))
	 (repo-buff (if buff-name (get-buffer buff-name) nil)))
    (if (not buff-name) nil
      (if repo-buff repo-buff
	(get-buffer-create buff-name)
	(with-current-buffer buff-name
	  (make-local-variable 'autogit-current-state)
	  (setq autogit-current-state autogit-init-state)
	  (make-local-variable 'autogit-open-buffers)
	  (setq autogit-open-buffers ())
          (autogit-travel-path 'init " command output")
	  (goto-char (point-min))
	  )
	(get-buffer buff-name)))))
(defvar autogit-repo-transition-table ()
  "Autogit repository transitions table")
(defvar autogit-init-state nil)
(setq autogit-repo-transition-table
  (progn (setq autogit-init-state "st_6")
  '(
    ("st_6" autogit-skip (("waiting_input"
        ( revert . "st_7")
        ( kill . "st_15")
        ( save . "st_10")
        ( open . "st_23")
       )  nil ) )
    ("st_23" autogit-append (  "st_5" "st_5" ) )
    ("st_5" autogit-unsaved-changes ( "st_6" "st_3" ) )
    ("st_3" autogit-do-pull ( "st_1" "st_21" ) )
    ("st_21" autogit-revert-all (  "st_19" "st_19" ) )
    ("st_19" autogit-skip (("waiting_input"
        ( revert . "st_16")
        ( kill . "st_14")
        ( save . "st_12")
        ( open . "st_20")
       )  nil ) )
    ("st_20" autogit-append (  "st_19" "st_19" ) )
    ("st_12" autogit-append (  "st_11" "st_11" ) )
    ("st_11" autogit-do-add ( "st_16" "st_16" ) )
    ("st_16" autogit-unsaved-changes ( "st_19" "st_25" ) )
    ("st_25" autogit-do-commit ( "st_3" "st_19" ) )
    ("st_14" autogit-remove (  "st_16" "st_16" ) )
    ("st_1" autogit-do-push ( "st_17" "st_3" ) )
    ("st_17" autogit-revert-all (  "st_6" "st_6" ) )
    ("st_10" autogit-append (  "st_9" "st_9" ) )
    ("st_9" autogit-do-add ( "st_7" "st_7" ) )
    ("st_7" autogit-unsaved-changes ( "st_6" "st_26" ) )
    ("st_26" autogit-do-commit ( "st_3" "st_3" ) )
    ("st_15" autogit-remove (  "st_7" "st_7" ) )
  ))
  )
(defun autogit-skip (buff)
  (insert "-------------------------\n")
  't)

(defun autogit-travel-path (msg real-buffer)
  (if (cdr-safe autogit-current-state)
      (setq autogit-current-state
	    (cdr-safe (assoc msg autogit-current-state))))
  (if (not autogit-current-state)
      (insert "Internal error: State machine broken: no source state.\n"))
  (while (and autogit-current-state (not (cdr-safe autogit-current-state)))
    (let* ((tr (assoc autogit-current-state autogit-repo-transition-table))
	   (func (if tr (nth 1 tr) (insert "Internal error: State machine broken: state undefined\n") nil))
	   (next-sts (if tr (nth 2 tr) (insert "Internal error: State machine broken: state undefined\n") nil)))
      (setq autogit-current-state
	    (if (funcall func (get-buffer real-buffer))
		(car next-sts)
	      (car (cdr next-sts))))))
  autogit-current-state
  )
(defun autogit-unsaved-changes (buff)
  (insert "Is there unsaved buffers in " (buffer-name) "?\n")
  (let ((buffs autogit-open-buffers)
	(stop nil))
    (while (progn
	     (if buffs
		 (let* ((cub (car buffs))
			(modified (buffer-modified-p cub))
			(visits (buffer-file-name cub)))
		   (setq stop (or stop (and modified visits)))
		   (if (and stop visits)
		       (insert (concat visits " is under modification.\n"))
		     (setq buffs (cdr buffs)))))
	     (and (not stop) buffs)))
    stop))

(defun autogit-append (buff)
  (insert (concat "Tracking file: " (buffer-file-name buff) "\n"))
  (if (not (buffer-file-name buff)) 't
    (or (member buff autogit-open-buffers)
	(setq autogit-open-buffers (cons buff autogit-open-buffers)))
    't))

(defun autogit-remove (buff)
  (insert (concat "Releasing file: " (buffer-file-name buff) "\n"))
  (setq autogit-open-buffers (delete buff autogit-open-buffers))
  't)

(defun autogit-revert-all (buff)
  (insert (concat "Reverting files of the repository " (buffer-name) "\n"))
  (let ((buffs autogit-open-buffers))
    (while buffs
      (let* ((buffa (car buffs))
	     (rest-buffs (cdr buffs))
	     (visits (buffer-file-name buffa))
	     (modified (buffer-modified-p buffa))
	     (may-revert (and visits (not modified))))
	(if may-revert
	    (with-current-buffer buffa
	      (condition-case EDATA
		  (revert-buffer 't 't 't)
		(error (message "Revert problem: %s - %s"
				(car EDATA) (cdr EDATA )))
		)))
	(setq buffs rest-buffs))))
  't)

(defun autogit-do-pull (buff)
  (insert (concat "git pull in " (buffer-name) "\n"))
  (equal 0 (call-process "git" nil nil nil "pull" "--no-edit")))

(defun autogit-do-push (buff)
  (insert (concat "git push in " (buffer-name) "\n"))
  (equal 0 (call-process "git" nil nil nil "push")))

(defun autogit-do-add (buff)
  (insert (concat "git add " (buffer-file-name buff) "\n"))
  (equal 0 (call-process "git" nil nil nil "add" (buffer-file-name buff))))

(defun autogit-do-commit (buff)
  (insert (concat "git commit in " (buffer-name) "\n"))
  (equal 0 (call-process
	    "git" nil nil nil "commit" "-m" "... autogit-mode session")))
(defun autogit-hook-function (operation)
  (if autogit-active 't
    (message "Autogit hook: %s-%s"
	     operation
	     (if (buffer-file-name)
		 (buffer-file-name)
	       (if (buffer-name) (buffer-name)
		 "Killed buffer")))
    (setq autogit-active 't)
    (let* ((real-buffer (current-buffer))
	   (repo-obj (autogit-get-create-repo-obj))
	   )
      (if (not repo-obj) 't
	(with-current-buffer repo-obj
	  (let* ((msg (cond
		       ((equal 'read operation)
			(if (member real-buffer autogit-open-buffers)
			    'revert
			  'open))
		       ((equal 'save operation)
			operation)
		       ((member real-buffer autogit-open-buffers)
			operation)
		       (t nil))))
	    (if msg (autogit-travel-path msg real-buffer) 't)
	    (goto-char (point-min))))))
    (setq autogit-active nil)))
(defun autogit-read-hook ()
  (autogit-hook-function 'read))
(defun autogit-save-hook ()
  (autogit-hook-function 'save))
(defun autogit-kill-hook ()
  (autogit-hook-function 'kill))
; after-save-hook
(add-hook 'after-save-hook 'autogit-save-hook)
; find-file-hook
(add-hook 'find-file-hook 'autogit-read-hook)
; kill-buffer-hook is special. It have to set in open callback because it
;  may be buffer local.
(add-hook 'kill-buffer-hook 'autogit-kill-hook)
