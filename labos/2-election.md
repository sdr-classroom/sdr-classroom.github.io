---
title: Labo 2 - Élection du processus le plus apte
css:
    - "/labos/style.css"
back: "/"
---

## Informations Générales
- **Lien vers votre repo** : communiqué en séance.
- **Groupes de deux**, que vous êtes libres de changer par rapport au labo 1 : si vous êtes seul.e, venez vers nous.
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

Rappelez-vous le [fil rouge du semestre](https://sdr-classroom.github.io/labos/1-diffusion-fiable-et-mutex.html#le-fil-rouge-du-semestre). Au labo 1, vous avez implémenté une mutex intolérante aux pannes. Nous commençons maintenant, avec ce labo 2, le travail qui nous amènera d'ici la fin du semestre à un algorithme de consensus.

**Ce labo ne dépend pas du précédent.** Vous n'avez besoin d'aucune ligne de votre labo 1, ni de votre diffusion fiable ni de votre exclusion mutuelle : vous partez d'un nouveau repo, qui contient tout ce qu'il faut.

---

## Les suppositions

- **Messages** : aucune perte, duplication ou réordonnancement.
- **Processus** : leur nombre est variable, et le code que nous vous fournissons vous y donne accès. Si vous utilisez un langage pour lequel nous ne proposons pas de code de départ, référez-vous à `LAYERS.md`, dans le repo qu'on vous remet.
- **Pannes** : **permanentes ou récupérables, sans amnésie.** Souvenez-vous qu'un processus est dit *correct* en terme de pannes récupérables s'il est tel qu'à partir d'un certain instant inconnu il ne tombera plus jamais en panne.
- **Réseau partiellement synchrone** : une borne sur la durée de transit des messages existe mais vous est inconnue.
- **Scission** : le réseau peut être temporairement scindé, mais finira toujours par se reconnecter.

---

## L'élection

Chaque processus a une **aptitude** : un nombre, qui vaut 0 au départ et peut changer à tout moment. Ce n'est pas vous qui la choisissez ; elle vous est communiquée, et elle peut monter comme descendre.

Vous implémenterez une couche d'élection : à tout instant, chaque processus *nomme* un élu. Si les aptitudes cessent de changer, votre couche doit garantir les propriétés suivantes :

- **Progrès** — un jour, tout processus correct nomme un élu et n'en change plus.
- **Sûreté** — un jour, tous les processus corrects nomment le même élu.
- **Validité** — cet élu est le processus correct de plus grande aptitude.

À aptitude égale, c'est le processus de plus petit identifiant qui l'emporte.

Notez que parce que ces propriétés sont « un jour », il est possible d'avoir temporairement deux élus en même temps, notamment durant une scission. C'est seulement une fois que le réseau s'est stabilisé que ces propriétés doivent tenir.

---

## Contraintes sur votre solution

Les propriétés ci-dessus disent ce qu'est une élection correcte. Elles ne suffisent pas pour que votre solution soit acceptée : nous exigeons en plus les deux contraintes suivantes.

**Les algorithmes vus en cours ne les respectent pas.** L'objectif de ce labo est que vous en conceviez un autre, en vous servant de ce que le cours vous a appris.

1. **Quand un processus devient le plus apte**, sur un réseau sans ralentissements, sans panne, et sans autre changement d'aptitude, tous les processus doivent le nommer élu en **au plus deux allers-retours**, c'est-à-dire quatre fois la durée de transit d'un message, et **au plus `4n` messages** doivent avoir été envoyés entre-temps, `n` étant le nombre de processus.
2. **Une fois que l'élu est connu de tous, les non-élus n'envoient plus de message.**

Enfin, si votre solution utilise des délais d'attente, **leur valeur initiale ne doit pas dépasser 400 unités de temps.**

Pour votre information, un ordre de grandeur : sur un réseau calme et rapide, un message met **une vingtaine d'unités de temps** à arriver. D'autres réseaux peuvent être plus lents, ou connaitre des pics de délai. La borne sur la durée de transit reste, quoi qu'il arrive, inconnue.

Notez aussi qu'un processus ne remet pas tous ses messages au réseau au même instant : ils partent l'un après l'autre, et écrire à tous les autres peut prendre jusqu'à une centaine d'unités de temps. Un processus qui écrit plus vite que ses messages ne partent accumule du retard, et ce retard continue de s'écouler bien après qu'il a cessé d'écrire.

Un indice, pour la première contrainte : quand un processus devient le plus apte, sans panne, au plus lui et l'élu précédent envoient des messages jusqu'à ce que tous le nomment.

---

## L'interface avec l'outillage

L'outillage est celui du labo 1 : votre programme est le comportement d'*un* processus, il lit ses événements sur `stdin` et écrit les siens sur `stdout`, et `cuelight` simule le réseau entre les processus.

Si vous utilisez notre squelette, vous n'aurez que les points suivants à implémenter :

- le constructeur de la couche est appelé une fois, au démarrage du processus, et reçoit `on_leader_change` ;
- `leader()` doit retourner l'identifiant du processus actuellement nommé élu ;
- `set_ability(v)` est appelée chaque fois que l'aptitude de ce processus change, et vaut désormais `v` ;
- `on_leader_change` est une fonction sans argument qui vous est fournie, et que **vous** devez appeler chaque fois que `leader()` se met à retourner un autre processus. Ne l'appelez pas depuis le constructeur : à ce moment-là, celui qui construit votre couche ne la tient pas encore.

C'est par ce dernier appel que nous apprenons qui vous nommez élu, et à quel instant : un changement que vous n'annoncez pas n'est jamais vu.

---

## Une contrainte technique

Elle est la même qu'au labo 1, et pour la même raison : au labo suivant, nous pourrons remplacer cette couche par notre propre implémentation.

1. **Votre nœud doit être une fonction pure des événements.** Pas d'horloge système, pas de threads, pas d'aléatoire non initialisé. C'est ce qui rend une exécution rejouable, et c'est vérifié avant tout le reste : si votre code ne se rejoue pas à l'identique, rien d'autre n'est évalué.
2. **Aucune opération n'est autorisée à bloquer en attendant une réponse.** Votre processus est un gestionnaire d'événements mono-thread, et le temps logique n'avance qu'une fois que l'événement est traité. Si une de vos fonctions bloque, alors le temps arrête d'avancer.

Concrètement : `leader()` répond tout de suite, à partir de ce que le processus sait déjà. Elle n'interroge personne. Et attendre « pendant une durée limitée » ne veut pas dire bloquer : cela veut dire armer un minuteur, retourner, et décider de la suite lorsqu'il se déclenche.

## Évaluation

Nous vous fournissons le vérificateur `lab2-check`, que vous construisez vous-même et qui exécute tous les tests fournis avec le code. Ces tests sont des scénarios décrivant une séquence de pannes, de ralentissements et de changements d'aptitude. Ceux-ci sont de deux types :

- **Un scénario écrit à la main**, `late-crash.json`, qui vise une difficulté précise.
- **Six scénarios paramétriques.** Leur exécution dépend d'une graine (seed) : pour chaque graine, les pannes, les délais et les changements d'aptitude sont différents. `lab2-check` exécute les 200 premières graines de chacun ; nous en exécuterons d'autres lors de l'évaluation de votre rendu.

Référez-vous au README de votre repo pour plus de détails sur la construction et l'exécution de `lab2-check`.

Votre rendu sera évalué sur ces tests, ainsi que sur un quiz individuel juste après le rendu. L'objectif sera de vérifier que vous possédez les choix architecturaux, logiques et algorithmiques de votre solution, et que vous avez compris leurs enjeux. Le quiz sera donné sur Opendidac, d'une durée de 30 minutes max et sans accès à votre code.

Votre note finale sera égale à `min(labo, quiz + 1)`, où `labo` et `quiz` sont votre note sur 6 au labo et au quiz, respectivement.
