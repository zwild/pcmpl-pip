;;; pcmpl-pip.el --- pcomplete for pip

;; Copyright (C) 2014 Wei Zhao
;; Author: Wei Zhao <kaihaosw@gmail.com>
;; Git: https://github.com/kaihaosw/pcmpl-pip.git
;; Version: 0.1
;; Created: 2014-09-10
;; Keywords: pcomplete, pip, python, tools

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Pcomplete for pip.

;;; Code:
(require 'pcomplete)

(defgroup pcmpl-pip nil
  "Pcomplete for pip"
  :group 'pcomplete)

(defcustom pcmpl-pip-cache-file "~/.pip/pip-cache"
  "Location of pip cache file."
  :group 'pcmpl-pip
  :type 'string)

(defconst pcmpl-pip-index-url "https://pypi.python.org/simple/")

;;;###autoload
(defun pcmpl-pip-clean-cache ()
  "Clean the pip cache file."
  (interactive)
  (shell-command-to-string (concat "rm " pcmpl-pip-cache-file)))

;; https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/pip/pip.plugin.zsh
(defun pcmpl-pip-create-index ()
  "Create the pip indexes file."
  (let* ((temp "/tmp/pip-cache")
         (dir (file-name-directory pcmpl-pip-cache-file)))
    (message "caching pip package index...")
    (unless (file-exists-p dir)
      (make-directory dir))
    (shell-command-to-string (concat "curl " pcmpl-pip-index-url
                                     " | sed -n '/<a href/ s/.*>\\([^<]\\{1,\\}\\).*/\\1/p'"
                                     " >> " temp))
    (shell-command-to-string (concat "sort " temp
                                     " | uniq | tr '\n' ' ' > "
                                     pcmpl-pip-cache-file))
    (shell-command-to-string (concat "rm " temp))))

;;;###autoload
(defun pcmpl-pip-update-index ()
  "Update the current pip cache file."
  (interactive)
  (pcmpl-pip-clean-cache)
  (pcmpl-pip-create-index))

(defconst pcmpl-pip-commands
  '("install" "uninstall" "freeze" "list" "show"
    "search" "wheel" "zip" "unzip" "bundle" "help"))

(defconst pcmpl-pip-general-options
  '("-h" "--help" "-v" "--verbose" "-V" "--version"
    "-q" "--quiet" "--log-file" "--log" "--proxy"
    "--timeout" "--exists-action" "--cert"))

(defconst pcmpl-pip-global-commands
  '("install" "search"))

(defconst pcmpl-pip-local-commands
  '("uninstall" "show"))

;; TODO command options

(defun pcmpl-pip-all ()
  "All packages."
  (with-temp-buffer
    (insert-file-contents pcmpl-pip-cache-file)
    (split-string (buffer-string))))

(defun pcmpl-pip-installed ()
  "All installed packages."
  (split-string (shell-command-to-string "pip freeze | cut -d '=' -f 1")))

;;;###autoload
(defun pcomplete/pip ()
  (let ((cmd (nth 1 pcomplete-args)))
    (unless (file-exists-p pcmpl-pip-cache-file)
      (pcmpl-pip-create-index))
    (pcomplete-here* pcmpl-pip-commands)
    (while (pcomplete-match "^-" 0)
      (pcomplete-here* pcmpl-pip-general-options))
    (cond
     ((member cmd pcmpl-pip-local-commands)
      (while (pcomplete-here (pcmpl-pip-installed))))
     ((member cmd pcmpl-pip-global-commands)
      (while (pcomplete-here (pcmpl-pip-all))))
     (t (while (pcomplete-here (pcomplete-entries)))))))

(provide 'pcmpl-pip)

;;; pcmpl-pip.el ends here
