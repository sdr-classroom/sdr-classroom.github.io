---
title: Labo 4 - Routing
css:
    - "/labos/style.css"
back: "/"
---

<!-- 
## Changelog

| Date  | Changement                                            |
| ----- | ----------------------------------------------------- |
-->

## Informations Générales

- [**Lien vers votre repo**](https://classroom.github.com/a/bGrCBxMI)
- **Groupes** : à réaliser par groupes de deux, potentiellement différents de ceux du labo précédent.
- **Plagiat** : nous intégrerons au processus d'évaluation des outils de détection de plagiat (entre groupe, mais aussi avec les rendus des années précédentes et la solution officielle).
  En cas de suspicion, vous y serez confronté.e.s, et l'incident pourra être rapporté au responsable de la filière, avec un risque d'échec immédiat au cours.
- **IA Générative** : Nous ferons les suppositions suivantes.
    - Vous avez des objectifs qui vous sont clairs (que nous espérons être d'acquérir des compétences d'ingénieur.e).
    - Vous avez conscience que les compétences d'un.e ingénieur.e incluent une capacité de compréhension, d'évaluation et de créativité technique, qui sont aussi celles recherchées et valorisées dans l'industrie *(lire : vous visez des jobs inatteignables par des vibe-coders autodidactes)*.
    - Vous êtes des personnes responsables et adultes, capables d'agir intentionnellement, dans l'intérêt de vos objectifs.

  Par conséquent, nous supposerons que vous agirez de manière réfléchie, et avec conscience des implications de vos choix. Par ailleurs et à titre d'information, nous avons pu constater que les meilleurs outils en date ne sont pas encore capables d'atteindre nos exigences sur ces labos, qui sont suffisamment complexes pour contenir des subtilités qui leur échappent encore.

Notez enfin que l'objectif étant pour vous d'apprendre, vous serez toujours légitimes et bienvenu.e.s à nous poser des questions, sur Go, la théorie, vos idées, vos blocages. Si vous vous sentez perdu.e.s ou coincé.e.s, c'est qu'il faut nous demander.

## Introduction

Ce labo a pour objectif de permettre à l'application ChatsApp de fonctionner sur un réseau incomplet, dans lequel chaque server ne communique donc directement qu'avec un sous-ensemble des autres serveurs du système.

Pour ce faire, deux modules doivent être implémentés : le `Pulsar`, et le `Router`. Ils doivent ensuite être intégrés au `Dispatcher`, afin que l'incomplétude du réseau soit invisible aux modules utilisateurs, tels que la mutex ou le mainteneur d'anneau.

Vous aurez accès, comme point de départ, à la solution du labo 3 ainsi qu'aux interfaces des abstractions à implémenter.

## Modifications attendues

### Pulsar

Le premier module à implémenter est le Pulsar, qui offre le comportement de sondes et échos générique tel que présenté en cours. Son unique méthode, `StartPulse`, déclenche une sonde, puis bloque jusqu'à réception de tous les échos, dont l'agrégation est alors retournée.

Le Pulsar est notamment défini, à sa construction, par les objets suivants.

- Un `PulseHandler`, qui est la fonction que le Pulsar appelle à la réception d'une nouvelle sonde. Elle prend en arguments la sonde reçue, son identifiant, et l'adresse du processus voisin envoyeur. Elle retourne une nouvelle sonde, celle qui sera propagée aux autres voisins, s'il en existe.
- Un `EchoHandler`, qui est la fonction que le Pulsar appelle lorsque tous les échos associés à une sonde sont reçus, afin d'en obtenir l'agrégation à envoyer au parent de cette sonde. Elle prend en arguments tous les échos reçus, la sonde correspondante, et son identifiant, et retourne l'écho qui devra être envoyé au parent.
- Un `NetSender`, qui est la channel sur laquelle le Pulsar écrira les messages à envoyer sur le réseau, accompagnés de leur destinataire.
- Un `NetReceiver`, qui est la channel sur laquelle le Pulsar lira les messages reçus lui étant destinés, accompagnés de leur envoyeur.

Notez bien que

- Le `PulseHandler` n'est appelé **que lors de la réception d'une sonde** : il sera donc exécuté exactement une fois sur tous les processus, feuilles comprises, excepté la racine (source de la sonde), qui ne l'exécutera pas.
- Le `EchoHandler` est appelé lorsque tous les échos sont reçus, **même s'il n'y en a aucun à recevoir** : il est donc appelé exactement une fois par chaque processus, racine et feuilles comprises (ces dernières l'appelant alors avec une slice vide).

### Router

Le Router est le seul utilisateur du Pulsar, dans deux buts : broadcasting et construction d'une table de routage. Il offre trois méthodes.

- `Broadcast` prend un message en argument et garantit son envoi à tous les processus du système (et non seulement ses voisins directs). Elle retourne une slice contenant tous les processus ayant reçu le message.
- `Send` s'assure de l'envoi du message donné, au destinataire donné. Pour ce faire, elle utilise une table de routage construite en interne par le Router à l'aide de messages d'explorations dont nous reparlons plus bas.
- `ReceivedMessageChan` retourne la channel sur laquelle le routeur écrira tout message destiné à ce processus, reçu suite à un appel approprié à `Broadcast` ou `Send` par un autre processus.

Son constructeur prend deux channels, similaires aux `NetSender` et `NetReceiver` du Pulsar, permettant de rendre le routeur indépendant du dispatcher.

La table de routage que le Router utilise est construite comme suit :

- Initialement, seuls les voisins directs sont connus.
- Si un destinataire ne se trouve pas dans la table de routage lors d'un appel à `Send`, une sonde de type *exploration* est lancée, permettant de construire une table de routage.
- Si un processus participe à une sonde d'exploration (sans en être à l'origine), alors il met à jour sa table de routage avec les données récoltées par les échos qu'il agrège durant la phase de contraction.
- Pour tout message n'ayant pas pu être servi du fait d'une table de routage incomplète, le message est envoyé à la prochaine mise à jour de cette dernière permettant son envoi, **tout en maintenant l'ordre des demandes d'envoi**, afin d'éviter de briser la garantie d'absence de réordonnancement offerte par le réseau.

Le Router utilise trois types de messages pour fonctionner :

- `BroadcastRequest` et `BroadcastResponse` sont les types d'une sonde et d'un écho conçus pour propager un message destiné à tous les processus du réseau.
- `ExplorationRequest` et `ExplorationResponse` sont les types d'une sonde et d'un écho utilisés pour construire une table de routage.
- `RoutedMessage` est un message accompagné d'une source *et d'une destination*. Les messages de ce type sont utilisés pour envoyer un message à travers le réseau de Routers, sur la base des tables de routage de chacun d'eux.

## Intégration

L'intégration du Router et du Pulsar se fait dans le Dispatcher, qui gagne donc une nouvelle méthode, `Broadcast`. Toute demande d'envoi par `Broadcast` ou par `Send` **doit donc passer par le Router**.

Les modules utilisateurs du dispatcher ont déjà été modifiés pour appeler `Broadcast` lorsque pertinent. Ils n'ont donc pas connaissance du fait que le réseau est maintenant incomplet, et doivent continuer de fonctionner inchangés.

## Tests

Des tests sont fournis pour vérifier le bon fonctionnement de votre Pulsar et de votre Router, ainsi que leur intégration dans le reste du programme.

Comme au labo 3, nous n'avons pas fourni tous les tests utilisés pour évaluer votre rendu. Nous attendons de votre part que vous implémentiez des tests additionnels, pour vérifier notamment les propriétés suivantes, et possiblement d'autres (sachant que nous nous permettrons d'exécuter des tests couvrant plus de propriétés que celles listées ci-dessous, lors de l'évaluation) :

- Pour le Pulsar, le comportement correct lors d'une réception de sonde, et la bonne agrégation des échos associés.
- Pour le Router, le comportement correct de `Broadcast`.

Votre note dépendra en grande partie des résultats des tests (les votres, ceux que nous n'avons pas fournis, et ceux fournis, y inclus ceux des autres modules pour détecter toute régression). La qualité de vos tests sera également prise en compte dans l'évaluation.

Tous les tests devront passer sans *et avec* le [data race detector](https://go.dev/doc/articles/race_detector) de Go (`go test -race`).

## Document d'architecture logicielle et Contraintes

Les mêmes exigences que [pour le labo 1](/labos/1-request-reply.html#document-darchitecture) s'appliquent ici concernant le document d'architecture logicielle, et les contraintes.

## Timeline et indications

Durant la première semaine, il est attendu que vous réfléchissiez à l'approche que vous souhaitez adopter pour implémenter ce labo. Il vous faudra notamment réfléchir à la manière de résoudre les problèmes suivants.

- De combien de Goroutines aurez-vous besoin au minimum pour garantir l'absence de deadlocks, et quelles seront leurs responsabilités ?
- Comment les sondes seront-elles maintenues, sans problèmes de concurrence ?
- Comment garantirez-vous que la méthode `StartPulse` du Pulsar bloquera jusqu'à la fin de la sonde correspondante ?
- Comment garantirez-vous que les demandes d'envoi via le Router seront traitées en parallèle de sondes en cours ?
- Comment garantirez-vous que les demandes d'envoi nécessitant une exploration seront mises en attente jusqu'à mise à jour de la table de routage, sans bloquer les autres opérations du Router ?

Après cette semaine, la séance de labo sera votre dernière occasion de valider auprès de nous votre proposition de solution. Une fois ce délai passé, il sera attendu que vous ayez une vision claire de votre solution, dont vous pourrez aussitôt commencer l'implémentation.

Le rendu aura lieu à la fin de la dernière séance de labo du semestre. Vous aurez donc quatre semaines (vacances exclues).
