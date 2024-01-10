---
title: Labo 4 - Agrégation d'informations distribuées
css:
    - "/labos/style.css"
---

## Informations Générales
- **Date du rendu** : Vendredi 26 janvier, 23:59 CEST.
- **Groupes** : à réaliser seul ou à deux. Vous pouvez réutiliser les groupes du précédent labo.
- **Plagiat** : en cas de copie manifeste, vous y serez confrontés, vous obtiendrez la note de 1, et l'incident sera reporté au responsable de la filière, avec un risque d'échec critique immédiat au cours. Ne trichez pas. *(Notez que les IAs génératives se trouvent aujourd'hui dans une zone qui est encore juridiquement floue pour ce qui est du plagiat, mais des arguments se valent à en considérer l'utilisation comme tel. Quoiqu'il en soit, nous vous proposons une autre vision sur la question : votre ambition est d'apprendre et d'acquérir des compétences, et votre utilisation éventuelle de cet outil doit refléter ceci. Tout comme Stackoverflow peut être à la fois un outil d'enrichissement et une banque de copy-paste, faites un choix intentionnel et réfléchi, vos propres intérêts en tête, de l'outil que vous ferez de l'IA générative)*

# Introduction

Dans ce labo, vous allez implémenter un algorithme à sondes et échos permettant au gestionnaire de dettes implémenté jusqu'ici de présenter des informations globales sur le système aux utilisateur•rice•s.

Vous devez repartir de votre code du labo 3. Si vous avez formé une nouvelle équipe, utilisez le code de l'un ou l'une des deux membres de la nouvelle équipe. Si l'équipe à laquelle appartenait ce code contenait deux membres, et que l'autre membre réutilise aussi ce même code dans sa nouvelle équipe, **ceci doit être précisé explicitement dans votre README, afin que cela n'apparaisse pas comme du plagiat.**

Puisque ce labo construit sur les précédents, toutes les indications des précédents énoncés qui ne sont pas rendues obsolètes par celui-ci restent valables et doivent donc continuer d'être vérifiées par votre solution à ce labo-ci.

# Nouvelle commande

Vous devez implémenter une nouvelle commande, `users`, qui retourne la liste complète des utilisateur•rice•s participant au système de dettes, avec leur solde actuel total (positif si on leur doit plus qu'ils ne doivent, et négatif s'ils doivent plus qu'on ne leur doit), et le fait qu'ils soient actuellement en ligne (c'est à dire qu'un client à leur nom est actuellement connecté au système), s'ils le sont. Par exemple, si Jessie est connecté•e à un serveur et Blake à un autre, mais que Ollie n'est pas connecté•e, alors la commande `users`, exécutée par Jessie ou Blake devra retourner quelque chose comme suit, en supposant que Blake doit 10 à Jessie et 5 à Ollie.

```txt
> users
jessie: 10 (online)
ollie: 5
blake: -15 (online)
```

Nous avons donc, pour chaque personne participant au système :

- Son pseudo
- Son solde actuel
- Seulement si elle est connectée, ce statut entre parenthèses : `(online)`. Si elle n'est pas connectée, rien n'est affiché.

L'ordre dans lequel les pseudos sont affichés n'est pas important.

# Nouvelle structure du réseau

Jusqu'à maintenant, nous avons supposé que tous les processus étaient connectés à tous les autres. Afin de rendre ce labo pertinent, il nous faudrait maintenant supposer que chaque processus ne connait qu'un sous-ensemble des autres. Cependant, ceci nécessiterait des changements majeurs dans les algorithmes implémentés jusqu'ici, et afin d'éviter ce besoin, nous fournirons dans le fichier de configuration de chaque processus la liste des voisins que ce processus a le droit de contacter dans le contexte de ce labo, c'est à dire pour l'envoi et la réception de sondes et d'échos. Ce nouveau champ sera nommé `neighbors`.

Par exemple, dans un système à 5 serveurs, le fichier de configuration du serveur associé au port `3333` pourrait inclure les champs suivants, en supposant que celui-ci n'a le droit de contacter que les serveurs `3334` et `3335` pour l'envoi et la réception de sondes et d'échos :

```json
    "port": 3333,
    "servers": [
        "localhost:3333",
        "localhost:3334",
        "localhost:3335",
        "localhost:3336",
        "localhost:3337"
    ],
    "neighbors": [
        "localhost:3334",
        "localhost:3335"
    ]
```

# Algorithme à sondes et échos

La nouvelle commande `users` nécessitera de la part du processus l'ayant reçue d'intéroger tous les autres processus pour obtenir les clients actuellement connectés à ceux-ci. Pour ce faire, vous implémenterez un algorithme à sondes et échos similaire à celui vu en cours, et adapté à cette problématique.

Notez que nous autoriserons le réseau à avoir des cycles, c'est à dire à ne pas être un arbre. Il vous faudra donc implémenter une version de l'algorithme fonctionnant sur graphe arbitraire.

Par ailleurs, nous autoriserons plusieurs utilisateur•rice•s à exécuter la commande `users` de manière concurrente, sur le même processus ou sur des processus différents. Votre solution devra donc être capable de gérer plusieurs sondes et échos en parallèle.

# Tests

Nous utiliserons des tests automatisés pour vérifier que votre solution respecte les spécifications de ce document. Nous n'évaluerons cependant pas les fonctionnalités héritées des précédents labos, vous permettant ainsi de ne pas y perdre de temps sur ce labo-ci.

Nous ne testerons pas de scénario dans lesquels une panne a lieu lors de l'exécution de la commande `users`.

Une partie conséquente de votre note dépendra aussi de la qualité de votre code et de votre solution, afin de pénaliser l'utilisation de locks, ou de découvrir des risques de race conditions non-découverts par nos tests.

Vous êtes par ailleurs libres, et il vous est même recommandé, d'implémenter des tests supplémentaires, que ce soit end-to-end en utilisant par exemple le framework que nous avons mis en place pour les tests que nous vous avons fourni aux labos 2 et 3, ou unitaires pour les nouvelles fonctionnalités de ce labo-ci.

# Rendu

Les éléments à rendre sont les mêmes que pour le labo précédent, notamment les fichiers executables.

Aussi, nous vous demandons à nouveau de décrire l'architecture logicielle de votre solution dans le README de votre repo. Vous devez décrire les différents modules et principales goroutines, leurs responsabilités et leurs moyens d'interaction avec le reste du système. Toute décision non-triviale doit être justifiée, mais inutile de rentrer dans chaque détail, le but étant de décrire la "big picture" de votre solution. Ceci nous servira à mieux appréhender votre code lorsque nous en évaluerons la qualité manuellement, et à juger de la pertinence de vos choix d'architecture et d'implémentation. Voyez aussi cela comme un exercice simplifié d'écriture de Design Specification.

# Contraintes supplémentaires

Les contraintes du labo précédent s'appliquent également à celui-ci.