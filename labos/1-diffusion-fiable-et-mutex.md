---
title: Labo 1 - Diffusion fiable et exclusion mutuelle
css:
    - "/labos/style.css"
back: "/"
---

## Informations Générales
- [**Lien vers votre repo**](TODO)
- **Groupes de deux** : si vous êtes seul.e, venez vers nous.
- **Langage** : libre. Boilerplate fournis en Python, Java, Go et C++, mais tout autre langage capable de lire et écrire des lignes sur `stdin`/`stdout` convient aussi.
- **Prérequis** : Installation de **Rust** (`rustup`), pour les outils d'évaluation.
- **Plagiat** : lors de l'évaluation de vos rendus, nous utiliserons des outils de détection de plagiat (entre groupes, mais aussi avec les rendus des années précédentes et la solution officielle).
  En cas de suspicion, vous y serez confronté.e.s, et l'incident pourra être rapporté au responsable
  de la filière, avec un risque d'échec immédiat au cours.
- **IA générative** : **le moyen d'arriver au rendu est entièrement libre.** En revanche, nous attendons un ownership complet de votre rendu. Vous devez posséder et savoir défendre tous les choix architecturaux et
  algorithmiques de votre solution (pourquoi ces choix, pourquoi pas d'autres), ainsi que réfléchir sur la base de votre solution (comment vous approcheriez telle ou telle nouvelle contrainte).
  
  Dans cette optique, chaque fin de labo sera suivie d'un *quiz individuel* qui testera précisément cette contrainte.

Notez enfin que l'objectif étant pour vous d'apprendre, vous serez toujours légitimes et
bienvenu.e.s à nous poser des questions : sur la théorie, sur vos idées, sur vos blocages. Si vous
vous sentez perdu.e.s ou coincé.e.s, c'est qu'il faut nous demander.

## Le fil rouge du semestre

D'ici la fin du semestre, vous aurez atteint (et vaincu) le boss final du monde distribué : le **consensus**. Une fois que le consensus est disponible, tout devient possible à faible cout algorithmique.

Nous y parviendrons en quatre étapes :

1. Permettre une communication robuste entre processus, et l'exclusion mutuelle dans un monde sans panne. Le consensus est facile par dessus l'exclusion mutuelle, mais nous voulons *tolérer les pannes*. Ce n'est donc que le début.
2. Permettre l'élection d'un leader dans un monde où les pannes sont possibles.
3. Utiliser le leader pour synchroniser les processus.
4. Tirer profit de la synchronisation pour atteindre le consensus.

Ce labo correspond à la première étape. Il se divise en deux parties : (A) Reliable Broadcast avec pannes, et (B) Exclusion Mutuelle sans pannes.

---

## Les suppositions

- **Messages** : aucune perte, duplication ou réordonnancement.
- **Processus** : leur nombre est variable, et le code que nous vous fournissons vous y donne accès. Si vous utilisez un langage pour lequel nous ne proposons pas de code de départ, référez-vous à `LAYERS.md`, dans le repo qu'on vous remet.
- **Pannes** :
  - **_Partie A_** *(Reliable Broadcast)* : **Pannes permanentes autorisées** ; un processus peut échouer et ne redémarre alors jamais.
  - **_Partie B_** *(Mutex)* : **Aucune panne possible**.
- **Réseau partiellement synchrone** : Une borne sur la durée de transit des messages existe mais vous est inconnue.

---

## Partie A — Diffusion fiable

Tout au long du semestre, il arrivera souvent de devoir diffuser (broadcast) un message, c'est à dire l'envoyer à tous les autres processus du système.

Or, comme nous l'avons vu en cours, envoyer simplement à tous ne suffit pas : si l'émetteur tombe en panne au milieu de ses envois, seule une partie des processus l'auront reçu. Difficile d'imaginer du consensus dans ce contexte.

Vous implémenterez donc une couche de diffusion fiable (reliable broadcast), qui devra garantir les propriétés suivantes :

- **Accord** — si un processus correct délivre `m`, alors **tous** les processus corrects
  délivrent `m`.
- **Validité** — si un processus correct diffuse `m`, alors il finit par délivrer `m`.
- **Non-duplication** — chaque message est délivré **au plus une fois** par processus.
- **Non-création** — un processus ne délivre que des messages réellement diffusés.

---

## Partie B — Exclusion mutuelle de Lamport

L'algorithme est celui du cours, et suppose qu'aucune panne n'arrivera jamais.

Votre implémentation doit donc garantir les propriétés suivantes :

- **Exclusion mutuelle** — jamais deux processus en section critique en même temps.
- **Progrès** — tout processus correct qui demande la section critique finit par
  l'obtenir.

---

## L'interface avec l'outillage

Votre programme correspond au comportement du module d'*un* processus du système. Il lit sur `stdin` les événements qu'il doit traiter (e.g. réception d'un message, demande d'entrée en section critique), et écrit sur `stdout` les événements qu'il déclenche (e.g. envoyer un message, sortir de section critique).

Un outil, `cuelight`, est ensuite chargé de lancer votre programme pour chaque processus du système, et lire et écrire sur `stdin` et `stdout` pour simuler le réseau entre les processus, et déclencher les événements qu'ils ont à traiter.

Afin de vous permettre de vous concentrer sur l'algorithmique, nous vous fournissons des squelettes qui gèrent `stdin` et `stdout` pour vous, et cachent cette complexité derrière des interfaces clairement définies. Si vous choisissez de ne pas utiliser un de ces squelettes, le README de votre repo contient les informations pour créer le vôtre de zéro.

Si vous utilisez nos squelettes, vous n'aurez donc que les points suivants à implémenter dans ce labo.

- Pour la diffusion fiable :
  - `broadcast(payload)` doit diffuser,
  - `subscribe(fn)` doit enregistrer un abonné, appelé à chaque délivrance ;
- Pour l'exclusion mutuelle :
  - `request(on_enter)` doit demander la section critique et s'assurer que `on_enter` sera appelé lorsqu'elle sera obtenue,
  - `release()` doit quitter la section critique.

---

## Une contrainte technique

Ces labos sont conçus de manière à ce que chaque couche que vous implémentez soit utilisable dans le labo suivant.

Afin d'évaluer chaque labo, nous pourrons remplacer les couches implémentées aux labos précédents par nos propres implémentations instrumentées pour tester une suffisamment grande variété de scénarios. Deux conséquences en découlent :

1. **Votre nœud doit être une fonction pure des événements.** Pas d'horloge système, pas de threads, pas d'aléatoire non initialisé. C'est ce qui rend une exécution rejouable, et c'est vérifié avant tout le reste : si votre code ne se rejoue pas à l'identique, rien d'autre n'est évalué.
2. **Aucune opération n'est autorisée à bloquer en attendant une réponse.** Votre processus est un gestionnaire d'événements mono-thread, et le temps logique n'avance qu'une fois que l'événement est traité. Si une de vos fonctions bloque, alors le temps arrête d'avancer.

En particulier, cela implique que tout est unidirectionnel : un événement en entrée ne peut pas répondre, sauf en générant un événement en sortie.  Concrètement : `broadcast(payload)` ne retourne rien, et la délivrance arrive par abonnement. Un autre exemple est `request(on_enter)` de l'exclusion mutuelle. `request` *ne bloque pas* en attendant la section critique : elle envoit ses messages et stocke `on_enter` pour pouvoir retourner sans attendre. Ce n'est que plus tard, lorsqu'un autre événement déclenchera son entrée en section critique, qu'elle appellera `on_enter`.


## Évaluation

Nous vous fournissons le vérificateur `lab1-check`, que vous construisez vous-même et qui exécute tous les tests fournis avec le code. Ces tests sont des scénarios décrivant une séquence d'événements, de ralentissements, de pannes, etc. Ceux-ci sont de deux types :

- **Quatre scénarios écrits à la main**: `rb-crash-midsend.json`, `deadlock.json`,
  `mutex-tie.json` et `mutex-late-peer.json`, qui visent chacun une difficulté précise.
- **Quatre scénarios paramétriques**, deux par partie. Un scénario paramétrique est un scénario dont les paramètres sont variables, et dont l'exécution dépend d'une graine (seed). Pour chaque graine, l'exécution sera légèrement différente. Cela permet de tester une plus grande variété de scénarios. `lab1-check` exécute les 200 premières graines de chacun des quatre ; nous en exécuterons d'autres lors de l'évaluation de votre rendu.

Référez-vous au README de votre repo pour plus de détails sur la construction et l'exécution de `lab1-check`.

Votre rendu sera évalué sur ces tests, ainsi que sur un quiz individuel juste après le rendu. L'objectif sera de vérifier que vous possédez les choix architecturaux, logiques et algorithmiques de votre solution, et que vous avez compris leurs enjeux.
