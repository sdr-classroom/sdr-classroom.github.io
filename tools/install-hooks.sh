#!/bin/sh
# Point git at the versioned hooks in tools/hooks/. Run once per clone.
set -eu
cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath tools/hooks
echo "core.hooksPath -> tools/hooks"
