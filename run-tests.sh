#!/bin/sh
set -eu

EMACS=${EMACS:-emacs}

# Control whether AUCTeX tests run:
#   with_auctex            -> require AUCTeX, error if not found
#   without_auctex             -> don’t load AUCTeX (AUCTeX tests skip)
#   auto (default) -> use AUCTeX if found else skip its tests
WITH_AUCTEX=${WITH_AUCTEX:-auto}

get_package_dir() {
  emacs --batch --eval \
    "(progn
       (require (quote package))
       (package-initialize)
       (when-let ((pkg-struct (car (alist-get (quote $1) package-alist))))
         (princ (package-desc-dir pkg-struct))))"
}

AUCTEX_DIR=${AUCTEX_DIR:-$(get_package_dir auctex)}
COMPAT_DIR=${COMPAT_DIR:-$(get_package_dir compat)}

is_auctex_dir() {
    [ -d "$AUCTEX_DIR" ]
}

run_tests() {
  exec "$EMACS" --batch -L . \
    ${COMPAT_DIR:+-L "$COMPAT_DIR"} \
    "$@" -l test/auto-capitalize-tests.el \
    -f ert-run-tests-batch-and-exit
}

case "$WITH_AUCTEX" in
  with_auctex)
    if ! is_auctex_dir; then
      echo "run-tests: WITH_AUCTEX=with_auctex but no AUCTeX installation found" >&2
      exit 1
    fi
    echo "run-tests: running with AUCTeX at $AUCTEX_DIR"
    run_tests -L "$AUCTEX_DIR" --eval "(require 'tex)"
    ;;
  without_auctex)
    echo "run-tests: running without AUCTeX"
    run_tests
    ;;
  auto)
    if is_auctex_dir; then
      echo "run-tests: running with AUCTeX at $AUCTEX_DIR"
      run_tests -L "$AUCTEX_DIR" --eval "(require 'tex)"
    else
      echo "run-tests: running without AUCTeX"
      run_tests
    fi
    ;;
  *)
    echo "run-tests: unknown WITH_AUCTEX='$WITH_AUCTEX' (expected with_auctex, without_auctex or auto)" >&2
    exit 1
    ;;
esac
