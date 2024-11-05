---
title: Labo 2 - Ordre total des messages
css:
    - "/labos/style.css"
back: "/labos/labos.html"
---

## Changelog

| Date  | Changement                                            |
| ----- | ----------------------------------------------------- |
| 29.10 | [Lien et précisions sur phase 2.](#phase-2-implémentation)                       |
| 05.11 | [Nécessité de passer le tests au race detector](#change_05_11)  |

## Introduction

Ce labo a pour objectif de compléter l'application ChatsApp pour garantir un ordre total des messages.

Vous aurez accès, comme point de départ à l'implémentation, à la solution au labo 1.

## Informations Générales
- **Groupes** : à réaliser par groupes de deux.
- **Plagiat** : en cas de copie manifeste, vous y serez confrontés, vous obtiendrez la note de 1, et l'incident sera reporté au responsable de la filière, avec un risque d'échec critique immédiat au cours. Ne trichez pas. <span class="remark">(Notez que les IAs génératives se trouvent aujourd'hui dans une zone qui est encore juridiquement floue pour ce qui est du plagiat, mais des arguments se valent à en considérer l'utilisation comme tel. Quoiqu'il en soit, nous vous proposons une autre vision sur la question : votre ambition est d'apprendre et d'acquérir des compétences, et votre utilisation éventuelle de cet outil doit refléter cela. Tout comme StackOverflow peut être autant un outil d'enrichissement qu'une banque de copy-paste, faites un choix intentionnel et réfléchi, vos propres intérêts en tête, de l'outil que vous ferez de l'IA générative)</span>

## Liens utiles

- [Repo GitHub de la phase 1](https://classroom.github.com/a/rK7JoECZ)
- [Repo GitHub de la phase 2](https://classroom.github.com/a/vQc2DytO)
- [Protocole de rendu des labos de SDR](/labos/labos.html#chronologie-de-chaque-labo)
- [Document d'Architecture Logicielle de la solution au labo 1](/labos/design-specs/1-tcp-rr.html)

## Ordre global des messages

Le but de ce labo est de compléter l'application distribuée ChatsApp avec la garantie que l'ordre des messages est le même pour tous les serveurs. Cela signifie que, pour tous deux messages `m1` et `m2`, peu importe leur source, si un serveur `A` affiche `m1` avant `m2`, alors tous les autres serveurs afficheront `m1` avant `m2`.

## Phase 1 : Conception

Vous trouverez, dans le repo [GitHub Classroom](https://classroom.github.com/a/rK7JoECZ) de la phase 1, le document d'architecture logicielle à compléter avec votre proposition de solution. Le format attendu est le même qu'au labo 1. L'évaluation de ce document se basera sur les questions ci-dessous ; il faudra (1) que votre document contienne les informations nécessaires pour répondre à ces questions, et (2) que ces réponses forment une solution correcte au problème posé.

- Quelle(s) abstraction(s) devront être créée(s) ?
  - Quelles sont leurs responsabilités (que font-elles, que délèguent-elles, que savent-elles, que ne savent-elles pas) ?
  - Quel est leur API exact (constructeur, méthodes) ? N'hésitez pas à donner des exemples d'utilisation de vos abstractions.
- Quelles sont les goroutines nécessaires ?
  - De quel état sont-elles responsables ?
  - Quand et par qui sont-elles créées ?
- Pour tout channel nécessaire à la communication entre goroutines,
  - Où sont-ils stockés ?
  - Quelle(s) goroutine(s) y écrivent, et lesquelles y lisent ?
- Quels changements à `server.go` permettront de garantir l'ordre total des messages ?
  
<span class="remark">Pour les groupes de trois : comment garantissez-vous une complexité asymptotique de calcul de $o(n)$ pour chaque message envoyé, où $n$ est le nombre de processus et $o(\cdot)$ est la [notation petit-o](https://en.wikipedia.org/wiki/Big_O_notation#Little-o_notation) ? </span>

## Phase 2 : Implémentation

Une fois la phase 1 terminée, vous trouverez [ici](https://classroom.github.com/a/vQc2DytO) le repo sur lequel vous devrez implémenter la solution. Celui-ci contiendra la solution du labo 1 ainsi qu'un point de départ pour la partie 2. Ce point de départ imposera des abstractions et APIs, mais vous laissera libre d'implémenter le fonctionnement interne que vous aurez proposé.

Le code fourni introduit également un `Dispatcher`, responsable de faciliter les échanges avec le réseau : (1) en gérant la traduction entre `[]byte` et `Message`, et (2) en répartissant les messages venant du réseau en fonction du type de message reçu. L'extrait suivant illustre l'utilisation de ce dispatcher.

```go
// dispatcher étant une instance de Dispatcher.

// Enregistrement d'un handler pour les messages de type ChatMessage
dispatcher.Register(ChatMessage{}, func(m Message, source Address) {
    chatMessage := m.(ChatMessage) // Conversion on ChatMessage
    fmt.Printf("Message %v reçu de la part de %v.\n", chatMessage, source)
})

// Enregistrement d'un handler pour les messages de type Mutex
dispatcher.Register(mutex.Message{}, func(m Message, source Address) {
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

Notez également que :

- Il vous faudra implémenter une Mutex de Lamport.
- Les tests fournis supposent que cette Mutex ne s'envoie jamais de message à elle-même à travers le réseau.
- Vous ne devez en aucun cas utiliser les abstractions fournies par le package `sync` de Go. Toute gestion de la concurrence doit être gérée par des goroutines et des channels.
- Vous êtes libres d'ajouter des tests, mais ne devez pas modifier ceux fournis.
- <span id="change_05_11"></span>Tous les tests doivent passer sans *et avec* le [data race detector](https://go.dev/doc/articles/race_detector) de Go (`go test -race`).

### Rendu

Votre rendu doit être intégralement compris dans le commit le plus récent avant la deadline. Cela inclue non seulement le code, mais également le document d'architecture logicielle décrivant votre travail. Celui-ci n'aura besoin de couvrir que vos ajouts ; nul besoin de décrire le code fourni. Il doit satisfaire les mêmes exigences que celles exprimées pour le rendu de la phase 1.