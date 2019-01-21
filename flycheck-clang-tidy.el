;;; flycheck-clang-tidy.el --- Flycheck syntax checker using clang-tidy

;; Author: Sebastian Nagel<sebastian.nagel@ncoding.at>
;; URL: https://github.com/ch1bo/flycheck-clang-tidy
;; Keywords: convenience languages tools
;; Package-Version: 0.0.1
;; Package-Requires: ((flycheck "0.30"))

;; This file is NOT part of GNU Emacs.
;; See LICENSE

;;; Commentary:

;; Adds a Flycheck syntax checker for C/C++ based on clang-tidy.

;;; Usage:

;;     (eval-after-load 'flycheck
;;       '(add-hook 'flycheck-mode-hook #'flycheck-clang-tidy-setup))


;;; Code:

(require 'flycheck)
(require 'json)

(flycheck-def-config-file-var flycheck-clang-tidy c/c++-clang-tidy ".clang-tidy"
  :safe #'stringp)

(flycheck-def-option-var flycheck-clang-tidy-build-path "build" c/c++-clang-tidy
  "Build path to read a compile command database.

For example, it can be a CMake build directory in which a file named
compile_commands.json exists (use -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
CMake option to get this output)."
  :safe #'stringp)

(defun flycheck-clang-tidy-find-default-directory (checker)
  (let ((config_file_location (flycheck-locate-config-file flycheck-clang-tidy checker)))
    (when config_file_location
        (file-name-directory config_file_location))))

(defun flycheck-clang-tidy-compdb ()
  "Generate the option for the compilation database file."
  (let ((database (concat (file-name-as-directory flycheck-clang-tidy-build-path) "compile_commands.json")))
    (when (file-exists-p database)
      database)))

(defun flycheck-clang-tidy-buffer-is-header ()
  "Determine if current buffer is a header file."
  (when (buffer-file-name)
    (let ((extension (file-name-extension (buffer-file-name))))
      ;; capture .h, .hpp, .hxx etc - all start with h
      (string-equal "h" (substring extension 0 1)))))

(defun flycheck-clang-tidy-verify (checker)
  "Verify CHECKER."
  (let ((database (flycheck-clang-tidy-compdb)))
    (list (flycheck-verification-result-new
           :label "Compile Database"
           :message (format "%s" (if database
                                     (format "Found at %s"  database)
                                   (format "No compilation database found in: %s" flycheck-clang-tidy-build-path)))
           :face (if database 'success '(bold error))
           ))))

(flycheck-define-checker c/c++-clang-tidy
  "A C/C++ syntax checker using clang-tidy.

See URL `https://github.com/ch1bo/flycheck-clang-tidy'."
  :command ("clang-tidy" "-quiet" (eval (format "-p=%s" (flycheck-clang-tidy-compdb))) source-original)
  :error-patterns
  ((error line-start (file-name) ":" line ":" column ": error: " (message) line-end)
   (warning line-start (file-name) ":" line ":" column ": warning: " (message) line-end))
  :predicate (lambda () (and (flycheck-clang-tidy-compdb)
                        (flycheck-buffer-saved-p)))
  :enabled (lambda () (not (flycheck-clang-tidy-buffer-is-header)))
  :verify flycheck-clang-tidy-verify
  :modes (c-mode c++-mode)
  :working-directory flycheck-clang-tidy-find-default-directory)

;;;###autoload
(defun flycheck-clang-tidy-setup ()
  "Setup Flycheck clang-tidy."
  (add-to-list 'flycheck-checkers 'c/c++-clang-tidy))

(provide 'flycheck-clang-tidy)
;;; flycheck-clang-tidy.el ends here
