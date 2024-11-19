---
title: Labo 3 - Load balancing
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

Ce labo a pour objectif de compléter l'application ChatsApp pour permettre à des clients de s'y connecter sans surcharger un serveur en particulier.

Vous aurez accès, comme point de départ, à la solution au labo 2 ainsi qu'à un client et aux interfaces des abstractions à implémenter.

### Informations Générales
- **Groupes** : à réaliser par groupes de deux.
- **Plagiat** : en cas de copie manifeste, vous y serez confrontés, vous obtiendrez la note de 1, et l'incident sera reporté au responsable de la filière, avec un risque d'échec critique immédiat au cours. Ne trichez pas. <span class="remark">(Notez que les IAs génératives se trouvent aujourd'hui dans une zone qui est encore juridiquement floue pour ce qui est du plagiat, mais des arguments se valent à en considérer l'utilisation comme tel. Quoiqu'il en soit, nous vous proposons une autre vision sur la question : votre ambition est d'apprendre et d'acquérir des compétences, et votre utilisation éventuelle de cet outil doit refléter cela. Tout comme StackOverflow peut être autant un outil d'enrichissement qu'une banque de copy-paste, faites un choix intentionnel et réfléchi, vos propres intérêts en tête, de l'outil que vous ferez de l'IA générative)</span>

### Liens utiles

- [Repo GitHub de la phase 3](#TODO)

## Client

Dans le code de départ de ce labo, l'utilisateur ne communique plus directement avec l'exécutable du serveur, mais à travers un client. Les modifications que nous vous fournissons par rapport au labo 2 sont les suivantes :

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

Le but de ce labo est d'implémenter un algorithme d'élection utilisé par les serveurs pour élire celui ayant le moins de clients connectés. Lorsqu'un client envoie un `ConnRequestMessage`, le serveur doit alors répondre par un `ConnResponseMessage` contenant l'adresse de cet élu.

Pour ce faire, vous devrez implémenter :

- Un mainteneur d'anneau dont l'interface est fournie dans `ringManager.go`. Cette abstraction est définie par
  - la méthode `SendToNext(msg dispatcher.Message)`, qui envoie un message au prochain processus valide dans l'anneau de manière non bloquante,
  - la méthode `ReceiveFromPrev() dispatcher.Message`, qui bloque jusqu'à la réception d'un message du processus valide précédent dans l'anneau,
  - le constructeur prenant en arguments, notamment, le dispatcher, l'adresse `self`, et une liste d'adresses `ring`, qui doit contenir `self` et être dans l'ordre de l'anneau.
- L'algorithme d'élection de Chang et Roberts, dont l'interface est fournie dans `crElector.go`. Cette abstraction est définie par
  - la méthode `GetLeader() transport.Address`, qui bloque si une élection est en cours, puis retourne l'adresse de l'élu,
  - la méthode `UpdateAbility(ability int)`, qui met à jour l'aptitude du processus et déclenche une nouvelle élection,
  - le constructeur prenant en arguments, notamment, le dispatcher, l'adresse `self`, et une liste d'adresses `ring` définie comme pour le mainteneur d'anneau.

Le `crElector` créera donc et utilisera un mainteneur d'anneau pour implémenter l'algorithme d'élection de Chang et Roberts. Il devra déclencher une nouvelle élection à chaque changement d'aptitude, *et non au moment d'un appel à `GetLeader`* (sauf si aucun leader n'a encore été déterminé). L'électeur sera ensuite utilisé par le `clientsManager` pour répondre correctement aux demandes de connexion des clients.

## Validation de votre solution

Vous êtes encouragés à réfléchir à votre approche avant de commencer le développement. Durant la première semaine, vous pourrez me partager votre idée de solution pour obtenir un retour.

## Rendu

Votre rendu doit contenir les modifications listées ci-dessus. Notez également que :

- Les tests fournis ne doivent pas être modifiés, mais vous êtes encouragés à en ajouter.
- Tous les tests doivent passer sans *et avec* le [data race detector](https://go.dev/doc/articles/race_detector) de Go (`go test -race`).
- Vous ne devez en aucun cas utiliser les abstractions fournies par le package `sync` de Go. Toute gestion de la concurrence doit être gérée par des goroutines et des channels.

Enfin, votre rendu doit contenir un document d'architecture logicielle décrivant votre solution. Celui-ci devra couvrir les points suivants :

- Toute abstraction supplémentaire créée, s'il y en a, auquel cas
  - ses responsabilités (que fait-elle, que délègue-t-elle, que sait-elle, que ne sait-elle pas),
  - son API exact (constructeur, méthodes). N'hésitez pas à en donner des exemples d'utilisation.
- Toute goroutine nécessaire, ainsi que
  - l'état dont elle est responsable, et
  - quand et par qui elle est créée.
- Pour toute channel nécessaire à la communication entre goroutines,
  - où elle est stockée, et
  - quelle goroutine y écrit ou y lit.
- Tout changement à `clientsManager.go` permettant de répartir la charge entre serveurs.

Votre rendu doit être intégralement compris dans le commit le plus récent avant la deadline. Cela inclue non seulement le code, mais également le document d'architecture logicielle décrivant votre travail.