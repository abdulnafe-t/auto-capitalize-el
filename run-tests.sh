#!/bin/sh
set -eu

EMACS=${EMACS:-emacs}

# Control whether AUCTeX tests run:
#   Yes            -> require AUCTeX, error if not found
#   No             -> don’t load AUCTeX (AUCTeX tests skip)
#   Auto (default) -> use AUCTeX if found else skip its tests
WITH_AUCTEX=${WITH_AUCTEX:-auto}
AUCTEX_DIR=${AUCTEX_DIR:-$(find "$HOME" -path '*/elpa/auctex-*' -type d -prune 2>/dev/null | sort | tail -n 1 )}

is_auctex_dir() {
  [ -d "$AUCTEX_DIR" ] && [ -f "$AUCTEX_DIR/tex.el" ]
}

COMPAT_DIR=${COMPAT_DIR:-$(find "$HOME" -type d -name 'compat-*' -prune -exec test -f '{}/compat.el' \; -print 2>/dev/null | sort | tail -n 1 )}

run_tests() {
  exec "$EMACS" --batch -L . \
    ${COMPAT_DIR:+-L "$COMPAT_DIR"} \
    "$@" -l test/auto-capitalize-tests.el \
    -f ert-run-tests-batch-and-exit
}

case "$WITH_AUCTEX" in
  yes)
    if ! is_auctex_dir; then
      echo "run-tests: WITH_AUCTEX=yes but no AUCTeX installation found" >&2
      exit 1
    fi
    echo "run-tests: running with AUCTeX at $AUCTEX_DIR"
    run_tests -L "$AUCTEX_DIR" --eval "(require 'tex)"
    ;;
  no)
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
    echo "run-tests: unknown WITH_AUCTEX='$WITH_AUCTEX' (expected yes, no or auto)" >&2
    exit 1
    ;;
esac
