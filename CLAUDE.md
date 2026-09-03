# SDR — Systèmes répartis (chantier cours)

Ce dépôt porte le **cours** : slides, site public, et l'outillage qui va avec. Il est la source de
vérité du contenu ; `sdr-classroom/sdr-classroom.github.io` en est une cible de publication.

## Deux types de travail

Le dossier parent porte **deux chantiers distincts**, qui ne partagent ni dépôt, ni board, ni
conventions de ticket. Avant d'ouvrir un ticket ou de toucher un fichier, identifier lequel est en
jeu.

| | **Cours** (slides, site) | **Labos** (harnais, templates, données) |
|---|---|---|
| Contenu | ce dépôt, `SLIDES-REVIEW.md` | `../sdr-labs/` |
| Dépôt des issues et PR | `sdr-classroom/website-private` | `sdr-classroom/sdr-labs` |
| Board | [projects/2 — Revue des slides SDR](https://github.com/orgs/sdr-classroom/projects/2) | [projects/3 — Labos SDR](https://github.com/orgs/sdr-classroom/projects/3) |
| Axe de tri | label `deck: <n>-<nom>` | labels `lab: <n>` et `area: <partie>` |
| Détail | ce fichier | **[../sdr-labs/CLAUDE.md](../sdr-labs/CLAUDE.md)** (autonome) |

**Ce qu'ils partagent** : les colonnes de statut, les labels `assigned:`, la forme des descriptions
de ticket et la boucle de collaboration. **Chaque chantier en garde sa propre copie**, dans le
`CLAUDE.md` de son dépôt, pour qu'aucun des deux ne dépende d'un fichier hors dépôt.

Un ticket qui touche les deux (rare : une slide qui décrit un labo) va sur le board du chantier
dont relève **le fichier à modifier**.

## Key documents

- **[slides-editor/](slides-editor/)** — éditeur visuel des decks et rendu headless. Voir
  [Éditer les decks](#éditer-les-decks).
- **[SLIDES-REVIEW.md](SLIDES-REVIEW.md)** — revue des slides du site public : liste
  d'observations (bugs de pseudocode, incohérences de modèle, trous de couverture) triée par
  importance, chacune avec une ligne `**Solution :**` à compléter. Ajouter les nouvelles
  observations ici plutôt que d'ouvrir un autre fichier.
- [../sdr-labs/docs/fiche-unite.md](../sdr-labs/docs/fiche-unite.md) — official course sheet:
  prerequisites, objectives, lecture content, lab hour budget (32h), grading.
- **[../sdr-labs/](../sdr-labs/)** — the lab redesign: harness (Rust), templates, reference
  solutions, and all design docs. Chantier séparé ; il a son propre CLAUDE.md.
- Ce dépôt publie le **site public du cours** : slides, labos en vigueur, planning.

## Workflow labos

**Tout ce qui concerne les labos est dans [../sdr-labs/CLAUDE.md](../sdr-labs/CLAUDE.md), qui se
suffit à lui-même** — board, conventions de ticket, règles de conception. Ne rien mettre ici dont le
travail sur les labos dépende : les deux dépôts sont indépendants.

En deux lignes : dépôt `sdr-classroom/sdr-labs`, board
[projects/3 — Labos SDR](https://github.com/orgs/sdr-classroom/projects/3), tri par `lab: <n>` et
`area: <partie>`.

## Dépôts et publication

**Le dépôt privé est la source de vérité.** `sdr-classroom/website-private` porte le contenu, les
issues et les PR. `sdr-classroom/sdr-classroom.github.io` est une **cible de publication** : on y
pousse quand le contenu doit sortir.

- Pas de fork possible : un fork de dépôt privé est toujours privé. Et le dépôt public doit rester
  public — l'org est sur le plan **free**, où GitHub Pages n'est servi que depuis un dépôt public
  (Pages : branche `main`, racine).
- Les deux dépôts partagent leur historique : publier = `git push public main`. Ni subtree ni miroir.
- Remotes du clone local : `origin` = **website-private** (donc le `git push` par défaut va au
  privé), `public` = le dépôt public. `main` suit `origin/main`.
- Les corrigés de labo vivent dans `../sdr-labs/` (privé), plus dans ce dépôt. La branche
  `website-private/private` qui les portait en 2024 a été supprimée, après archivage dans le tag
  `archive/private-2024` — elle contenait le seul exemplaire de
  `labos/design-specs/1-tcp-rr.md` (corrigé du labo 1, absent de `main` et de `sdr-labs`).

## Suivi du travail — board et tickets

Board : [projects/2 — Revue des slides SDR](https://github.com/orgs/sdr-classroom/projects/2).
Issues et PR **du chantier cours** uniquement sur `website-private` — celles des labos vont
ailleurs, voir [../sdr-labs/CLAUDE.md](../sdr-labs/CLAUDE.md).

**Axe de tri propre à ce board : le label `deck: <n>-<nom>`** = *quel deck* est touché, pour trier
et attaquer dans l'ordre du cours. La numérotation est **normalisée** (`0.0-intro`, `0.1-pannes`,
`1.0-go`, … `7.1-raft`) pour que le tri alphabétique soit l'ordre du cours ; la description du
label donne le dossier réel. Un ticket peut en porter plusieurs. Les tickets transverses (qui
touchent tous les decks, ou aucun encore) n'en portent aucun. Tout nouveau ticket visant un deck
doit recevoir le sien.

Le reste — colonnes, `assigned:`, forme des descriptions, boucle de collaboration — est dans
[Conventions de ticket](#conventions-de-ticket).

## Éditer les decks

- Les decks sont des exports slides.com en HTML **positionné en absolu**. Toute édition doit
  **préserver le rendu visuel** — vérifier la slide après chaque modification.
- **[slides-editor/](slides-editor/)** — éditeur visuel local des decks (`npm run edit`) et rendu
  headless d'une slide en PNG (`npm run render -- <deck> <slide>`), à utiliser pour voir le
  résultat d'une modification. Son [FORMAT.md](slides-editor/FORMAT.md) documente le format
  d'export slides.com (blocs, groupes, fragments, géométrie des lignes, notes dans `SLConfig`) :
  **le lire avant d'éditer un deck à la main**, plutôt que de redécouvrir le format.
- **Deux numérotations coexistent** : le renderer indexe **à plat et à partir de 0** (index 0 =
  slide de titre, 38 index pour `2-2-mutex-lamport`), alors que les tickets et `SLIDES-REVIEW.md`
  utilisent `S<n>.<k>` = n-ième slide horizontale, k-ième étape verticale. Donner les deux en
  référençant une slide, pour qu'Olivier rende exactement la même.
- Corollaire : le dépôt a dérivé de slides.com et en est désormais la source de vérité.
  Ré-exporter un deck écraserait les correctifs — éditer via `slides-editor`, y compris pour
  créer du contenu.
- Un nouveau deck exporté se complète avec `python3 FixSlidesExportToHtml.py slides/<fichier>`,
  **une seule fois**.

## Éditeur : worktree, serveur, tests

- **Le serveur d'édition appartient à Olivier.** Il le lance lui-même depuis son worktree principal :
  `cd slides-editor && npm run edit` (port 5174, relancer après un rebase). Claude ne le démarre ni
  ne le tue — pas de `pkill -f "tsx src/server.ts"`. La suite de tests démarre son propre serveur
  et glisse de port si 5174 est pris.
- **Claude travaille sur l'éditeur dans le worktree `../wt/editor`, sur la branche
  `claude/editor`.** `main` reste **libre pour le dépôt principal** : git refuse la même branche
  dans deux worktrees, donc tant que Claude la tient, Olivier ne peut pas s'y mettre.
- **Publier depuis ce worktree ne demande pas de sortir de sa branche** : Claude commit sur
  `claude/editor`, puis `git push origin claude/editor:main` (fast-forward). Inutile — et
  impossible — de mettre `main` à jour en local pendant qu'elle est sortie ailleurs. Olivier
  récupère par un `git pull`. Claude **signale chaque fois que `main` bouge**.
  Le `slides-editor/node_modules` du worktree est un lien symbolique vers celui du principal.
- Cette liberté de pousser vaut **pour l'outillage seulement** : `slides-editor/` ne part jamais sur
  le dépôt public et sa suite de tests le couvre. Le *contenu* (slides, labos, pages) reste soumis à
  la relecture d'Olivier.

## Conventions de ticket

Pour le board slides et `website-private`. Le chantier labos applique les mêmes, mais en garde sa
propre copie dans [../sdr-labs/CLAUDE.md](../sdr-labs/CLAUDE.md), pour que chaque dépôt se suffise.

**Quatre axes indépendants.** Aucun ne pilote l'autre ; déplacer une carte ne change aucun label.

- **Colonne** = quel *type* de travail est requis. Valeur unique, égale à l'état le plus bloquant :
  `Needs thinking` → `Actionable` → `In progress` → `Reviewable by Olivier` → `Done`.
- **Labels `assigned: Olivier` / `assigned: Claude`** = *qui* travaille. Peuvent coexister ; le
  détail de la répartition se lit dans la description, où les items marqués ❓ sont pour Olivier.
- **Axe de tri thématique** = `deck: <n>-<nom>`, décrit plus haut.
- **Jalon `S<nn> — <contenu>`** = *avant quelle séance* le travail doit être fait. Les jalons
  reprennent la numérotation de la colonne `Sem` du planning (`index.html`) : `S01` à `S16`, les
  semaines sans cours ne consommant pas de numéro. **Tout ticket reçoit son jalon dès qu'un est
  pertinent** — celui de la séance qui a besoin du deck touché. Restent sans jalon les tickets
  explicitement sans échéance (« nice to have ») et ceux qui ne se rattachent à aucune séance.

**La description d'un ticket est la source de vérité.** Courte, complète, actionnable, à jour en
tout temps. Elle ne contient que des **Observations**, des **Décisions** et des **Propositions**,
chacune suivie de ses action items — jamais un journal, jamais une section de synthèse en fin de
page : chaque réponse se met **au contact du constat qu'elle concerne**. Traces de vérification,
lectures d'articles et sorties de compilateur vont en **commentaire**.

**Toute décision appartient à Olivier.** Une ligne « Décision » suppose qu'elle vient de lui, ou de
Claude *et* qu'il l'a validée. Sinon c'est une « Proposition », suivie d'un action item ❓. Piège
courant : une consigne conditionnelle (« vérifie X, et si oui applique ») ne vaut approbation que si
la condition est vérifiée — sinon la main revient à Olivier.

**La boucle de collaboration.**

1. Olivier commente un ticket et le passe en `assigned: Claude`.
2. Claude **lit les commentaires d'abord** — `assigned: Claude` veut dire « j'ai commenté ». Il les
   intègre dans la description, puis traite ce qui reste : transformer chaque menu d'options en
   **recommandation argumentée**, pour que le coût de décision tombe à oui/non.
3. Claude repasse le ticket en `assigned: Olivier`. `Needs thinking` + `assigned: Claude` n'est
   **jamais** un état de repos : Claude ne pose jamais ce label lui-même.
4. Quand un ticket n'a plus de ❓, Claude le passe en `Actionable` **et retire tout label
   d'assignation** — c'est Olivier qui place ensuite.

Script de contrôle de cohérence entre ❓, colonne et labels : `board-audit.sh` (scratchpad).

**Éditer une description : pull → assert → push → vérifier.** Un remplacement dont l'ancre ne
matche pas échoue en silence et renvoie le corps inchangé, sans erreur. Donc : repartir du corps
réel récupéré depuis GitHub, jamais d'une copie locale ; asserter chaque ancre ; envoyer ; **relire
le distant** et vérifier au `grep`. Une mise à jour n'est pas faite parce que la commande n'a pas
échoué, elle est faite quand elle a été relue.

**Ne rien modifier dans le dépôt sans demande explicite.** Olivier décide au cas par cas qui
applique chaque changement. Une décision actée dans un ticket ne vaut pas feu vert. La colonne
`Actionable` est gelée tant qu'il ne l'a pas dit.

**Le compte `gh` est celui d'Olivier** : les commentaires de Claude apparaissent sous son nom. Les
préfixer de `> 🤖 *Rédigé par Claude.*`.


## Le HTML des labos est généré, et committé

`./mdToHtml.sh` passe chaque `labos/*.md` dans pandoc et écrit le `.html` à côté ; **les deux sont
versionnés**, parce que GitHub Pages sert ce dépôt tel quel, sans étape de build. Le bloc YAML en
tête des `.md` est donc des métadonnées **pandoc**, pas du front-matter Jekyll : `title:` remplit le
`<title>` et le `<h1>`, `css:` ajoute une feuille, `back:` l'URL du lien « Back ».

Le mode de panne est silencieux : éditer un `.md`, oublier `mdToHtml.sh`, et le site publie
l'ancienne version sans que rien ne le signale. `tools/check-html-fresh.sh` le refuse.

- `tools/install-hooks.sh` — à lancer **une fois par clone** ; branche `core.hooksPath` sur
  `tools/hooks/`, ce qui active la vérification avant chaque commit.
- `tools/check-html-fresh.sh` — la vérification seule, sur tout le dossier. Sans pandoc installé,
  elle se saute au lieu d'échouer.
