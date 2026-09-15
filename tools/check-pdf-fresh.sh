#!/bin/sh
# Refuse un slides/<deck>/index.html dont le PDF n'a pas été régénéré.
#
# Les PDF sont committés — GitHub Pages sert ce dépôt tel quel, sans étape de build, et un PDF
# fabriqué par le navigateur du lecteur dépendait de son navigateur, de son format de papier et
# d'un CDN au moment du clic. Le mode de panne que ça achète est silencieux : modifier un deck,
# oublier `npm run pdf`, et le site publie le PDF de la semaine dernière sans que rien ne le
# signale. Ceci le rend bruyant.
#
#   tools/check-pdf-fresh.sh          vérifie tous les decks
#   tools/check-pdf-fresh.sh --staged vérifie seulement ce qui est indexé (hook pre-commit)
#
# La référence est slides/pdf.manifest, au format `shasum -a 256` : la vérification est faite par
# shasum lui-même, il n'y a donc pas d'analyseur maison à se tromper, et n'importe qui peut la
# refaire à la main.
set -eu
cd "$(git rev-parse --show-toplevel)"

manifest="slides/pdf.manifest"

if ! command -v shasum >/dev/null 2>&1; then
    echo "check-pdf-fresh: shasum introuvable, vérification sautée" >&2
    exit 0
fi

if [ "${1:-}" = "--staged" ]; then
    files=$(git diff --cached --name-only --diff-filter=ACM -- 'slides/*/index.html')
else
    files=$(find slides -mindepth 2 -maxdepth 2 -name index.html -type f | sort)
fi
[ -n "$files" ] || exit 0

if [ ! -f "$manifest" ]; then
    echo "" >&2
    echo "Aucun $manifest : les PDF n'ont jamais été générés." >&2
    echo "  cd slides-editor && npm run pdf" >&2
    exit 1
fi

stale=""
for src in $files; do
    deck=$(dirname "$src")
    pdf="$deck/slides.pdf"
    if [ ! -f "$pdf" ]; then
        stale="$stale $pdf(absent)"
        continue
    fi
    recorded=$(grep -F "  $src" "$manifest" | cut -d' ' -f1 || true)
    if [ -z "$recorded" ]; then
        stale="$stale $pdf(non inscrit au manifeste)"
        continue
    fi
    actual=$(shasum -a 256 "$src" | cut -d' ' -f1)
    [ "$recorded" = "$actual" ] || stale="$stale $pdf"
done

if [ -n "$stale" ]; then
    echo "" >&2
    echo "Les PDF ne sont pas à jour :" >&2
    for f in $stale; do echo "  $f" >&2; done
    echo "" >&2
    echo "Régénérer, puis indexer le résultat :" >&2
    echo "  cd slides-editor && npm run pdf" >&2
    echo "  git add slides/*/slides.pdf slides/pdf.manifest" >&2
    echo "" >&2
    exit 1
fi
