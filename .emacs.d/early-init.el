;;; early-init.el --- Early Init File -*- lexical-binding: t -*-
;;; Commentary:
;; Emacsの初期化前に実行される設定ファイル

;;; Code:

;; package.elを無効化（elpacaを使用するため）
(setq package-enable-at-startup nil)

;; GUIコンポーネントの無効化（起動高速化）
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; ガベージコレクションの閾値を一時的に高く設定（起動高速化）
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; 初期化後にガベージコレクション設定を戻す
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold 800000
                  gc-cons-percentage 0.1)))

;;; early-init.el ends here