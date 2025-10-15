---
title: Labo 2 - Ordre total des messages
css:
    - "/labos/style.css"
back: "/"
---

## Informations Générales

- [**Lien vers votre repo**](#todo)
- **Groupes** : à réaliser par groupes de deux, potentiellement différents de ceux du labo 1.
- **Plagiat** : nous intégrerons au processus d'évaluation des outils de détection de plagiat (entre groupe, mais aussi avec les rendus des années précédentes et la solution officielle).
  En cas de suspicion, vous y serez confronté.e.s, et l'incident pourra être rapporté au responsable de la filière, avec un risque d'échec immédiat au cours.
- **IA Générative** : Nous ferons les suppositions suivantes.
    - Vous avez des objectifs qui vous sont clairs (que nous espérons être d'acquérir des compétences d'ingénieur.e).
    - Vous avez conscience que les compétences d'un.e ingénieur.e incluent une capacité de compréhension, d'évaluation et de créativité technique, qui sont aussi celles recherchées et valorisées dans l'industrie *(lire : vous visez des jobs inatteignables par des vibe-coders autodidactes)*.
    - Vous êtes des personnes responsables et adultes, capables d'agir intentionnellement, dans l'intérêt de vos objectifs.

  Par conséquent, nous supposerons que vous agirez de manière réfléchie, et avec conscience des implications de vos choix. Par ailleurs et à titre d'information, nous avons pu constater que les meilleurs outils en date ne sont pas encore capables d'atteindre nos exigences sur ces labos, qui sont suffisamment complexes pour contenir des subtilités qui leur échappent encore.

Notez enfin que l'objectif étant pour vous d'apprendre, vous serez toujours légitimes et bienvenu.e.s à nous poser des questions, sur Go, la théorie, vos idées, vos blocages. Si vous vous sentez perdu.e.s ou coincé.e.s, c'est qu'il faut nous demander.

## Introduction

Ce labo a pour objectif de compléter l'application ChatsApp pour garantir un ordre total des messages.

Vous aurez accès, comme point de départ à l'implémentation, à la solution au labo 1, qui inclut aussi un document d'architecture logicielle tel qu'il était attendu de votre part.

## Objectif : Ordre global des messages

Le but de ce labo est de compléter l'application distribuée ChatsApp avec la garantie que l'ordre des messages est le même pour tous les serveurs. Cela signifie que, pour tous deux messages `m1` et `m2`, peu importe leur source, si un serveur `A` affiche `m1` avant `m2`, alors tous les autres serveurs afficheront `m1` avant `m2`.

Il vous faudra pour cela implémenter et intégrer dans le code actuel une Mutex distribuée de Lamport, telle que présentée en cours. L'unique différence est que votre Mutex ne doit jamais s'envoyer de message à elle-même à travers le réseau.

## État actuel

Le code fourni introduit un `Dispatcher`, responsable de faciliter les échanges avec le réseau : (1) en gérant la traduction entre `[]byte` et `Message`, et (2) en répartissant les messages venant du réseau en fonction du type de message reçu. L'extrait suivant illustre l'utilisation de ce dispatcher.

```go
// dispatcher étant une instance de Dispatcher.

// Enregistrement d'un handler pour les messages de type ChatMessage
dispatcher.Register(ChatMessage{}, func(m Message, source Address) {
    // Code exécuté à la réception d'un ChatMessage
    chatMessage := m.(ChatMessage) // Conversion en ChatMessage
    fmt.Printf("Message %v reçu de la part de %v.\n", chatMessage, source)
})

// Enregistrement d'un handler pour les messages de type Mutex
dispatcher.Register(mutex.Message{}, func(m Message, source Address) {
    // Code exécuté à la réception d'un mutex.Message
    mutex := m.(mutex.Message) // Conversion en mutex.Message
    fmt.Printf("Message de type mutex %v reçu de la part de %v.\n", mutex, source)
})

// Envoi de messages
chatMsg := ChatMessage{Content: "Hello, world!"}
dispatcher.Send(chatMsg, dstAddr)

mtxMsg = mutex.Message{Type: mutex.Request, TS: ts}
dispatcher.Send(mtxMsg, dstAddr)
```

Le serveur initialise et met en place un dispatcher auprès duquel vous ne devriez avoir qu'à enregistrer vos nouveaux types de messages.

## Tests

Des tests sont fournis pour vérifier le bon fonctionnement de votre Mutex, ainsi que l'ordre total des messages dans l'application ChatsApp.

Contrairement au labo 1, nous n'avons pas fourni tous les tests utilisés pour évaluer votre rendu. Nous attendons de votre part que vous implémentiez des tests additionnels, pour vérifier au moins les propriétés suivantes (mais plus si vous le souhaitez) :

- Lorsqu'un processus qui n'est pas en SC et qui ne souhaite pas y entrer reçoit une requête, il doit répondre avec un `ACK`, au processus demandeur uniquement.
- Lorsqu'un processus est en SC et reçoit une requête, il doit envoyer son `ACK` immédiatement, puis un `REL` au moment de sortir de SC.

Votre note dépendra en grande partie des résultats des tests (les votres, ceux que nous n'avons pas fournis, et ceux fournis, y inclus ceux des autres modules pour détecter toute régression). La qualité de vos tests sera également prise en compte dans l'évaluation.

Tous les tests devront passer sans *et avec* le [data race detector](https://go.dev/doc/articles/race_detector) de Go (`go test -race`).

## Document d'architecture logicielle et Contraintes

Les mêmes exigences que [pour le labo 1](/labos/1-request-reply.html#document-darchitecture) s'appliquent ici concernant le document d'architecture logicielle, et les contraintes.

## Timeline et indications

Durant la première semaine, il est attendu que vous réfléchissiez à l'approche que vous souhaitez adopter pour implémenter ce labo. Il vous faudra notamment réfléchir à la manière de résoudre les problèmes suivants.

- De combien de Goroutines aurez-vous besoin au minimum pour garantir l'absence de deadlocks, et quelles seront leurs responsabilités ?
- Comment garantirez-vous qu'aucun état ne sera accédé concurremment par plusieurs goroutines ?
- Comment utiliser l'abstraction de Mutex pour permettre un ordre total des messages dans l'application ChatsApp ?
- Comment la méthode `Request` pourra-t-elle bloquer jusqu'à l'entrée en section critique ?

Après cette semaine, la séance de labo sera votre dernière occasion de valider auprès de nous votre proposition de solution. Une fois ce délai passé, il sera attendu que vous ayez une vision claire de votre solution, dont vous pourrez aussitôt commencer l'implémentation.

Le rendu aura lieu une minute avant le début du labo 3. Vous aurez donc quatre semaines (vacances exclues).
