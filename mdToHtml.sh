#! /bin/sh

# This script converts markdown files to html files using pandoc
# See https://medium.com/craftycode/how-to-create-a-simple-web-page-using-markdown-95e462e43e01
#
#   ./mdToHtml.sh                  every .md under labos/
#   ./mdToHtml.sh labos/2-election.md ...   only these (used by the pre-commit hook)

convert() {
    file="$1"
    # Get filename without extension
    filename=$(basename -- "$file")
    dst="$(dirname "$file")/${filename%.*}.html"

    pandoc --toc "$file" -f markdown -t html -s -o "$dst" --template labos/pandoc-template.html --highlight-style zenburn --css=/labos/style.css
}

if [ $# -gt 0 ]; then
    for file in "$@"; do convert "$file"; done
else
    # For every md file in dir "labos"
    find labos -name "*.md" -type f | while read -r file; do convert "$file"; done
fi
