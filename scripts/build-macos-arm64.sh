#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/putty-src"
PREPARE_ONLY=0
CLI_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --prepare-only) PREPARE_ONLY=1 ;;
    --cli-only) CLI_ONLY=1 ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Usage: $0 [--prepare-only] [--cli-only]" >&2
      exit 1
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only." >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "Warning: detected architecture $(uname -m). Building for host architecture, not Apple Silicon." >&2
fi

if ! command -v perl >/dev/null 2>&1; then
  echo "perl is required." >&2
  exit 1
fi

if ! command -v make >/dev/null 2>&1; then
  echo "make is required." >&2
  exit 1
fi

tmp_recipe="$(mktemp -t putty-recipe.XXXXXX)"
trap 'rm -f "$tmp_recipe"' EXIT

awk '
BEGIN { skip_osx_block = 0; skip_mx = 0 }
skip_osx_block {
  if ($0 ~ /^!end[[:space:]]*$/) {
    skip_osx_block = 0
  }
  next
}
$0 ~ /^!begin[[:space:]]+osx([[:space:]]|$)/ { skip_osx_block = 1; next }
$0 ~ /^!makefile[[:space:]]+osx[[:space:]]/ { next }
$0 ~ /^PuTTY[[:space:]]*:[[:space:]]*\[MX\]/ { skip_mx = 1; next }
skip_mx && $0 ~ /^[[:space:]]+\+/ { next }
skip_mx { skip_mx = 0 }
{ print }
' "$SRC_DIR/Recipe" > "$tmp_recipe"

(
  cd "$SRC_DIR"
  env LC_ALL=C LANG=C PUTTY_RECIPE="$tmp_recipe" perl ./mkfiles.pl
)

# Old PuTTY codebase is noisy on modern clang; avoid failing on warnings.
env LC_ALL=C LANG=C perl -pi -e 's/ -Werror / /g' "$SRC_DIR/unix/Makefile.gtk" "$SRC_DIR/unix/Makefile.ux"

if [[ "$PREPARE_ONLY" -eq 1 ]]; then
  echo "Generated Makefiles:"
  echo "  $SRC_DIR/unix/Makefile.gtk"
  echo "  $SRC_DIR/unix/Makefile.ux"
  exit 0
fi

if [[ "$CLI_ONLY" -eq 1 ]]; then
  (
    cd "$SRC_DIR/unix"
    make -f Makefile.ux "CC=clang -arch arm64" "LDFLAGS=-arch arm64" plink pscp psftp puttygen
  )
  echo "Built CLI tools in: $SRC_DIR/unix"
  exit 0
fi

if ! command -v pkg-config >/dev/null 2>&1; then
  echo "pkg-config is required for GUI build. Install with: brew install pkg-config gtk+3" >&2
  exit 1
fi

if ! pkg-config --exists gtk+-2.0; then
  echo "gtk+2 development files are required. Install with: brew install gtk+" >&2
  exit 1
fi

(
  cd "$SRC_DIR/unix"
  make -f Makefile.gtk \
    "CC=clang -arch arm64" \
    "LDFLAGS=-arch arm64" \
    "GTK_CONFIG=pkg-config gtk+-2.0 x11" \
    putty plink pscp psftp puttygen
)

echo "Build completed. Binaries are in: $SRC_DIR/unix"
