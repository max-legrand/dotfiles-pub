#!/usr/bin/env bash
# Strip com.apple.quarantine from the vendored plugin tree.
# macOS sets this xattr on files downloaded via Safari or extracted from
# release zips, which makes Gatekeeper prompt on every dlopen of an unsigned
# .dylib/.so. Run this once after cloning/extracting on macOS.
# Safe to run on Linux too (xattr is a no-op there).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$NVIM_DIR/pack/vendor/start"

if [[ ! -d "$VENDOR_DIR" ]]; then
	echo "vendor dir not found: $VENDOR_DIR" >&2
	exit 1
fi

if [[ "$(uname)" != "Darwin" ]]; then
	echo "not macOS, nothing to do"
	exit 0
fi

if ! command -v xattr >/dev/null; then
	echo "xattr not found in PATH" >&2
	exit 1
fi

xattr -dr com.apple.quarantine "$VENDOR_DIR"
touch "$VENDOR_DIR/.quarantine-cleared"
echo "stripped com.apple.quarantine from $VENDOR_DIR"
