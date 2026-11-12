#!/bin/sh
# Refuse a labos/*.md whose labos/*.html was not regenerated.
#
# The generated .html is committed — GitHub Pages serves this repo as-is, with no build step. The
# failure mode that buys is silent: edit a .md, forget ./mdToHtml.sh, and the site keeps publishing
# the previous version with nothing to indicate it. This turns that into a loud one.
#
#   tools/check-html-fresh.sh          check every labos/*.md
#   tools/check-html-fresh.sh --staged check only what is staged (used by the pre-commit hook)
set -eu
cd "$(git rev-parse --show-toplevel)"

if ! command -v pandoc >/dev/null 2>&1; then
    echo "check-html-fresh: pandoc introuvable, vérification sautée" >&2
    exit 0
fi

if [ "${1:-}" = "--staged" ]; then
    files=$(git diff --cached --name-only --diff-filter=ACM -- 'labos/*.md')
else
    files=$(find labos -maxdepth 1 -name '*.md' -type f)
fi
[ -n "$files" ] || exit 0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
stale=""

for md in $files; do
    html="${md%.md}.html"
    [ -f "$html" ] || { stale="$stale $html(absent)"; continue; }
    pandoc --toc "$md" -f markdown -t html -s -o "$tmp/out.html" \
        --template labos/pandoc-template.html --highlight-style zenburn --css=/labos/style.css 2>/dev/null
    cmp -s "$tmp/out.html" "$html" || stale="$stale $html"
done

if [ -n "$stale" ]; then
    echo "" >&2
    echo "Le HTML généré n'est pas à jour :" >&2
    for f in $stale; do echo "  $f" >&2; done
    echo "" >&2
    echo "  ./mdToHtml.sh && git add labos/*.html" >&2
    echo "" >&2
    exit 1
fi
