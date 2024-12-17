---
title: Labo 4 - Routing
css:
    - "/labos/style.css"
back: "/labos/labos.html"
---
<!-- 
## Changelog

| Date  | Changement                                            |
| ----- | ----------------------------------------------------- |
-->

## Introduction

Ce labo a pour objectif de permettre à l'application ChatsApp de fonctionner sur un réseau incomplet, dans lequel chaque server ne communique donc directement qu'avec un sous-ensemble des autres serveurs du système.

Pour ce faire, deux modules doivent être implémentés : le `Pulsar`, et le `Router`. Ils doivent ensuite être intégrés au `Dispatcher`, afin que l'incomplétude du réseau soit invisible aux modules utilisateurs, tels que la mutex ou le mainteneur d'anneau.

Vous aurez accès, comme point de départ, à la solution au labo 3 ainsi qu'aux interfaces des abstractions à implémenter.

### Informations Générales
- **Groupes** : à réaliser par groupes de deux.
- **Plagiat** : en cas de copie manifeste, vous y serez confrontés, vous obtiendrez la note de 1, et l'incident sera reporté au responsable de la filière, avec un risque d'échec critique immédiat au cours. Ne trichez pas. <span class="remark">(Notez que les IAs génératives se trouvent aujourd'hui dans une zone qui est encore juridiquement floue pour ce qui est du plagiat, mais des arguments se valent à en considérer l'utilisation comme tel. Quoiqu'il en soit, nous vous proposons une autre vision sur la question : votre ambition est d'apprendre et d'acquérir des compétences, et votre utilisation éventuelle de cet outil doit refléter cela. Tout comme StackOverflow peut être autant un outil d'enrichissement qu'une banque de copy-paste, faites un choix intentionnel et réfléchi, vos propres intérêts en tête, de l'outil que vous ferez de l'IA générative)</span>

### Liens utiles

- [Repo GitHub de la phase 4](https://classroom.github.com/a/N2dTrFgo)

## Pulsar

Le premier module à implémenter est le Pulsar, qui offre le comportement de sondes et échos générique tel que présenté en cours. Son unique méthode, `StartPulse`, déclenche une sonde, puis bloque jusqu'à réception de tous les échos, dont l'agrégation est alors retournée.

Le Pulsar est notamment défini, à sa construction, par les objets suivants.

- Un `PulseHandler`, qui est la fonction que le Pulsar appelle à la réception d'une nouvelle sonde. Elle prend en arguments la sonde reçue, son identifiant, et l'adresse du processus voisin envoyeur. Elle retourne une nouvelle sonde, celle qui sera propagée aux autres voisins, s'il en existe.
- Un `EchoHandler`, qui est la fonction que le Pulsar appelle lorsque tous les échos associés à une sonde sont reçus, afin d'en obtenir l'agrégation à envoyer au parent de cette sonde. Elle prend en arguments tous les échos reçus, la sonde correspondante, et son identifiant, et retourne l'écho qui devra être envoyé au parent.
- Un `NetSender`, qui est la channel sur laquelle le Pulsar écrira les messages à envoyer sur le réseau, accompagnés de leur destinataire.
- Un `NetReceiver`, qui est la channel sur laquelle le Pulsar lira les messages reçus lui étant destinés, accompagnés de leur envoyeur.

Notez bien que

- Le `PulseHandler` n'est appelé **que lors de la réception d'une sonde** : il sera donc exécuté exactement une fois sur tous les processus, feuilles comprises, excepté la racine (source de la sonde), qui ne l'exécutera pas.
- Le `EchoHandler` est appelé lorsque tous les échos sont reçus, **même s'il n'y en a aucun à recevoir** : il est donc appelé exactement une fois par chaque processus, feuilles comprises (ces dernières l'appelant alors avec une slice vide).

## Router

Le Router est le seul utilisateur du Pulsar, dans deux buts : broadcasting et construction d'une table de routage. Il offre trois méthodes.

- `Broadcast` prend un message en arguments et garantit son envoi à tous les processus du système (et non seulement ses voisins directs). Elle retourne une slice contenant tous les processus ayant reçu le message.
- `Send` s'assure de l'envoi du message donné au destinataire donné. Pour ce faire, elle utilise une table de routage construite en interne par le Router à l'aide de messages d'explorations dont nous reparlons plus bas.
- `ReceivedMessageChan` retourne la channel sur laquelle le routeur écrira tout message destiné à ce processus, reçu suite à un appel approprié à `Broadcast` ou `Send` par un autre processus.

Son constructeur prend deux channels, similaires aux `NetSender` et `NetReceiver` du Pulsar, permettant de rendre le routeur indépendant du dispatcher.

La table de routage que le Router utilise est construite comme suit :

- Initialement, seuls les voisins directs sont connus.
- Si un destinataire ne se trouve pas dans la table de routage lors d'un appel à `Send`, une sonde de type *exploration* est lancée, permettant de construire une table de routage.
- Si un processus participe à une sonde d'exploration (sans en être à l'origine), alors il met à jour sa table de routage avec les données récoltées par les échos qu'il agrège durant la phase de contraction.
- Pour tout message n'ayant pas pu être servi du fait d'une table de routage incomplète, le message est envoyé à la prochaine mise à jour de cette dernière permettant son envoi, **tout en maintenant l'ordre des demandes d'envoi**, afin d'éviter de briser la garantie d'absence de réordonnancement offerte par le réseau.

Le Router utilise trois types de messages pour fonctionner :

- `BroadcastRequest` et `BroadcastResponse` sont les types d'une sonde et d'un écho conçus pour propager un message destiné à tous les processus du réseau.
- `ExplorationRequest` et `ExplorationResponse` sont les types d'une sonde et d'un écho utilisés pour construire une table de routage.
- `RoutedMessage` est un message accompagné d'une source *et d'une destination*. Les messages de ce type sont utilisés pour envoyer un message à travers le réseau de Routers, sur la base des tables de routage de chacun d'eux.

## Intégration

L'intégration du Router et du Pulsar se fait dans le Dispatcher, qui gagne donc une nouvelle méthode, `Broadcast`. Toute demande d'envoi par `Broadcast` ou par `Send` **doit donc passer par le Router**.

Les modules utilisateurs du dispatcher ont été modifiés pour appeler `Broadcast` lorsque pertinent. Ils n'ont donc pas connaissance du fait que le réseau est maintenant incomplet, et doivent continuer de fonctionner inchangés.

## Validation de votre solution

Vous êtes encouragés à réfléchir à votre approche avant de commencer le développement. Durant la première semaine, vous pourrez me partager votre idée de solution pour obtenir un retour.

## Rendu

Votre rendu doit contenir les modifications listées ci-dessus. Notez également que :

- Les tests fournis ne doivent pas être modifiés, mais vous êtes encouragés à en ajouter.
- Tous les tests doivent passer sans *et avec* le [data race detector](https://go.dev/doc/articles/race_detector) de Go (`go test -race`).
- Vous ne devez en aucun cas utiliser les abstractions fournies par le package `sync` de Go, excepté le `WaitGroup`. Toute autre gestion de la concurrence doit être gérée par des goroutines et des channels.

Enfin, votre rendu doit contenir un document d'architecture logicielle décrivant votre solution. Celui-ci devra décrire

- toutes les goroutines utilisées, et la responsabilité de chacune (comportement, état),
- toute channel permettant la coopération entre goroutines, *y compris celles passées aux constructeurs du Pulsar et du Routeur*.

De ce document, il devra donc être possible de comprendre la solution que vous aurez choisie pour les difficultés suivantes posées par ce labo :

- Comment les sondes en cours sont maintenues, et ce sans problèmes de concurrence,
- Comment la méthode `StartPulse` du Pulsar bloquera jusqu'à la fin de la sonde correspondante,
- Comment la méthode `Send` du Router bloquera jusqu'à mise à jour de la table de routage si cette dernière ne permet pas l'envoi immédiat,
- Comment l'appel bloquant à `StartPulse` par le Router n'empêchera pas au Router de recevoir et propager des messages, et de mettre à jour sa table de routage.

Votre rendu doit être intégralement compris dans le commit le plus récent avant la deadline. Cela inclue non seulement le code, mais également le document d'architecture logicielle décrivant votre travail.