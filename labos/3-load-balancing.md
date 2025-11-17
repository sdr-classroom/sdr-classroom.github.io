---
title: Labo 3 - Load balancing
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

- [**Lien vers votre repo**](#TODO)
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

Ce labo a pour objectif de compléter l'application ChatsApp pour permettre à des clients de s'y connecter sans surcharger un serveur en particulier.

Vous aurez accès, comme point de départ, à la solution au labo 2 ainsi qu'à un client et aux interfaces des abstractions à implémenter.

## État actuel

Dans le code de départ de ce labo, l'utilisateur.ice ne communique plus directement avec l'exécutable du serveur, mais à travers un client. Les modifications que nous vous fournissons par rapport au labo 2 sont les suivantes :

- Un package `/internal/client` implémente un client qui se connecte à un serveur donné, écoute la ligne de commande, envoie les entrées de l'utilisateur au serveur, et affiche les messages reçus de la part du serveur. Il est utilisé par le package exécutable `cmd/client`, qui prend en arguments le nom d'utilisateur, l'adresse du client, et l'adresse du serveur auquel se connecter.
- Le serveur, au lieu d'échanger avec la ligne de commande, utilise maintenant un `clientsManager`, responsable de
    - écouter et répondre aux demandes de connexion des clients,
    - transmettre les messages reçus de la part des clients connectés au serveur,
    - transmettre les messages reçus par le serveur aux clients connectés.

Afin de gérer la connexion des clients, le protocole de communication client-serveur suivant est mis en place :

- À son lancement, le client envoie un `ConnRequestMessage` au serveur dont l'adresse lui a été fournie en argument.
- Le serveur répond au client par un `ConnResponseMessage`, contenant l'adresse du serveur auquel le client a été assigné. S'il s'agit de ce serveur, alors le client peut commencer à envoyer des messages.
- Le client envoie ensuite des `ChatMessage` au serveur.
- Lorsque le client se déconnecte, il envoie un `ConnClose` au serveur.

_**Notez que, pour des raisons de simplicité, un seul client par nom d'utilisateur n'est autorisé à se connecter au système à la fois. Si plusieurs clients se connectent au nom du même utilisateur, le comportement n'est pas défini.**_

## Modifications attendues

Actuellement, le serveur répond à tout `ConnRequestMessage` par un `ConnResponseMessage` contenant sa propre adresse. En d'autres termes, il accepte toute demande de connexion, sans condition.

Le but de ce labo est d'implémenter un algorithme d'élection utilisé par les serveurs pour élire celui ayant le moins de clients connectés. Lorsqu'un client envoie un `ConnRequestMessage`, le serveur doit répondre par un `ConnResponseMessage` contenant l'adresse de cet élu.

Pour ce faire, vous devrez implémenter :

- Un mainteneur d'anneau dont l'interface est fournie dans `election/ring/maintainer.go`. Cette abstraction est définie par
    - la méthode `SendToNext(msg dispatcher.Message)`, qui envoie un message au prochain processus valide dans l'anneau de manière non bloquante,
    - la méthode `ReceiveFromPrev() dispatcher.Message`, qui bloque jusqu'à la réception d'un message du processus valide précédent dans l'anneau,
    - le constructeur prenant en arguments, notamment, le dispatcher, l'adresse `self`, et une liste d'adresses `ring`, qui doit contenir `self` et être dans l'ordre de l'anneau.
- L'algorithme d'élection de Chang et Roberts, dont l'interface est fournie dans `election/crElector.go`. Cette abstraction est définie par
    - la méthode `GetLeader() transport.Address`, qui bloque si une élection est en cours, puis retourne l'adresse de l'élu,
    - la méthode `UpdateAbility(ability int)`, qui met à jour l'aptitude du processus et déclenche une nouvelle élection,
    - le constructeur prenant en arguments, notamment, le dispatcher, l'adresse `self`, et une liste d'adresses `ring` définie comme pour le mainteneur d'anneau.

Le `crElector` créera donc et utilisera un mainteneur d'anneau pour implémenter l'algorithme d'élection de Chang et Roberts. Il devra déclencher une nouvelle élection à chaque changement d'aptitude, *et non au moment d'un appel à `GetLeader`* (sauf si aucun leader n'a encore été déterminé). L'électeur sera ensuite utilisé par le `clientsManager` pour répondre correctement aux demandes de connexion des clients.

## Tests

Des tests sont fournis pour vérifier le bon fonctionnement de votre `maintainer`, `crElector`, et `clientsManager`.

Comme au labo 2, nous n'avons pas fourni tous les tests utilisés pour évaluer votre rendu. Nous attendons de votre part que vous implémentiez des tests additionnels, pour vérifier notamment les propriétés suivantes, et possiblement d'autres (sachant que nous nous permettrons d'exécuter des tests couvrant plus de propriétés que celles listées ci-dessous, lors de l'évaluation) :

- Pour le mainteneur d'anneau,
  - Lorsqu'un envoi ne reçoit pas de réponse avant le timeout, le prochain processus dans l'anneau est essayé.
  - À chaque nouvelle demande d'envoi de message via `SendToNext`, le prochain processus dans l'anneau est à nouveau essayé, même s'il n'avait pas répondu pour un message précédent.
- Pour l'électeur,
  - Le comportement respecte l'algorithme de Chang et Roberts lorsque le résultat d'une élection est reçu.
  - Lorsque l'aptitude est mise à jour *durant une élection*, une nouvelle élection est déclenchée après la fin de la première.

Votre note dépendra en grande partie des résultats des tests (les votres, ceux que nous n'avons pas fournis, et ceux fournis, y inclus ceux des autres modules pour détecter toute régression). La qualité de vos tests sera également prise en compte dans l'évaluation.

Tous les tests devront passer sans *et avec* le [data race detector](https://go.dev/doc/articles/race_detector) de Go (`go test -race`).

## Document d'architecture logicielle et Contraintes

Les mêmes exigences que [pour le labo 1](/labos/1-request-reply.html#document-darchitecture) s'appliquent ici concernant le document d'architecture logicielle, et les contraintes.

## Timeline et indications

Durant la première semaine, il est attendu que vous réfléchissiez à l'approche que vous souhaitez adopter pour implémenter ce labo. Il vous faudra notamment réfléchir à la manière de résoudre les problèmes suivants.

- De combien de Goroutines aurez-vous besoin au minimum pour garantir l'absence de deadlocks, et quelles seront leurs responsabilités ?
- Comment garantirez-vous qu'aucun état ne sera accédé concurremment par plusieurs goroutines ?
- Comment utiliser l'abstraction d'électeur pour permettre une répartition de charge entre serveurs ?

Après cette semaine, la séance de labo sera votre dernière occasion de valider auprès de nous votre proposition de solution. Une fois ce délai passé, il sera attendu que vous ayez une vision claire de votre solution, dont vous pourrez aussitôt commencer l'implémentation.

Le rendu aura lieu une minute avant le début du labo 4. Vous aurez donc quatre semaines (vacances exclues).
