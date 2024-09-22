---
title: Labo 1 - Résilience face aux pannes
css:
    - "/labos/style.css"
back: "/labos/labos.html"
---

<!---
## Changelog

| Date  | Changement                                            |
| ----- | ----------------------------------------------------- |
-->

## Introduction

Ce labo a les objectifs suivants.

- Prise en main de Go et ses paradigmes de programmation concurrente
- Implémentation de communication entre serveurs à travers TCP
- Implémentation d'un protocole de communication RR (Request-Reply)

## Informations Générales
- **Groupes** : à réaliser par groupes de deux.
- **Plagiat** : en cas de copie manifeste, vous y serez confrontés, vous obtiendrez la note de 1, et l'incident sera reporté au responsable de la filière, avec un risque d'échec critique immédiat au cours. Ne trichez pas. <span class="remark">(Notez que les IAs génératives se trouvent aujourd'hui dans une zone qui est encore juridiquement floue pour ce qui est du plagiat, mais des arguments se valent à en considérer l'utilisation comme tel. Quoiqu'il en soit, nous vous proposons une autre vision sur la question : votre ambition est d'apprendre et d'acquérir des compétences, et votre utilisation éventuelle de cet outil doit refléter cela. Tout comme StackOverflow peut être autant un outil d'enrichissement qu'une banque de copy-paste, faites un choix intentionnel et réfléchi, vos propres intérêts en tête, de l'outil que vous ferez de l'IA générative)</span>

## Liens utiles

- [Votre repo GitHub](https://classroom.github.com/a/A3qqFHHt)
- [Protocole de rendu des labos de SDR](/labos/labos.html#chronologie-de-chaque-labo)
- [Document d'Architecture Logicielle de la donnée](/labos/design-specs/1-udp.html)

## Spécifications fonctionnelles

Nous décrivons ici les spécifications fonctionnelles de l'application ChatsApp telle qu'elle doit être rendue à la fin de ce premier labo. Notez que nous vous fournissons une version simple communiquant à travers UDP et dont il manque la garantie offerte par le protocole RR. Le reste ne nécessitera pas de modifications majeure de votre part.

### Lancement de l'application

ChatsApp est une application distribuée. Chaque utilisateur.ice lance l'exécutable du serveur et lui fournit sa configuration. Durant le développement, la commande `go run` peut être utilisée.

```sh
go run ./cmd/server/main.go <local_address> <config_file_path>
```

- `<local_address>` est l'adresse IP sur laquelle ce serveur recevra les connexions d'autres serveurs,
- `<config_file_path>` est le chemin d'accès au fichier de configuration de ce serveur.

Ce fichier de configuration est au format JSON, et inclut les champs suivants :

- `Username` - pseudonyme au nom duquel ce serveur enverra les messages aux autres serveurs
- `Neighbors` - tableau de chaines de caractères listant les adresses IP des voisins de ce serveur sur le réseau
- `PrintReadAck` - booléen indiquant si le serveur doit afficher un accusé de réception suite à l'envoi de chaque message
- `Debug` - booléen indiquant si les logs doivent être affichées sur stdout
- `LogPath` - chemin d'accès à un répertoire dans lequel sera créé un fichier contenant les logs
- `SlowdownMs` - en millisecondes, ralentissement artificiel du serveur après chaque réception et envoi de message

Une fois lancé, un serveur attend un qu'un message soit entré sur la ligne de commande pour l'envoyer à tous ses voisins. Ces derniers l'afficheront dans la console sous le format `<user>: <message>`, suivit d'un saut de ligne.

Si `PrintReadAck` est configuré à `true`, l'envoyeur affichera un message de la forme `[<neighbor_address> received: <message>]` dès que le voisin d'adresse IP `<neighbor_address>` l'informe avoir reçu et traité ce message.

### Garanties

ChatsApp doit offrir les garanties suivantes :

1. Entre tous deux serveurs sans panne, aucun message ne doit être perdu, dupliqué, ou réordonnancé.
2. Un accusé de réception doit être reçu exactement une fois pour chaque voisin correct au sens de pannes récupérables.

### Fonctionnalités manquantes

Tel que fourni, ChatsApp n'offre pas la fonctionnalité d'accusés de réception, ni les garanties ci-dessus.

En effet, le serveur n'a actuellement aucun moyen d'obtenir un accusé de réception. Aussi, il utilise UDP, qui n'offre pas les garanties 1, et n'implémente aucun protocole supplémentaire satisfaisant la garantie 2.

Il vous revient, dans ce labo, d'implémenter ces fonctionnalités manquantes.

## Phase 1 : Conception

Vous trouverez dans votre repo [GitHub Classroom](https://classroom.github.com/a/A3qqFHHt) l'implémentation de cette première version de ChatsApp. Vous trouverez également sur [cette page](/labos/design-specs/1-udp.html) un document d'architecture logicielle décrivant le code fourni, dans les grandes lignes.

Nous vous demandons de compléter ce code afin d'offrir les garanties demandées et la fonctionnalité d'accusé de réception.

### Rendu

Nous attendons de votre part un document markdown ou pdf constituant un document d'architecture logicielle détaillant comment implémenter ce labo. Imaginez être architecte logiciel responsable de cette nouvelle fonctionnalité. Votre document sera destiné aux équipes de développement, qui devront pouvoir le suivre sans rencontrer d'inconnue majeure. Nous l'évaluerons comme le ferait un collègue responsable de valider votre proposition avant de la transmettre aux développeur.euses.

Il nous faudra être capable de répondre aux questions suivantes après lecture de votre document (et avec un minimum de jugeote de notre part). Notez qu'elles n'ont pas besoin d'apparaitre explicitement dans votre document ; elles sont ici pour guider vos réflexions et vérifier l'exhaustivité de votre document. Celui-ci doit donc simplement contenir les informations suffisantes pour y répondre.

- Quelles abstractions doivent être créées, et quelles sont leurs responsabilités et leurs APIs ?
- Comment et où ces abstractions seront-elles utilisées par le code existant ?
- Quelles goroutines tourneront (en continu ou temporairement) et quelles seront leurs responsabilités ?
- Comment ces goroutines communiqueront-elles entre elles, et/ou avec les événements extérieurs tels que la réception d'un message, ou le souhait d'en envoyer un à quelqu'un ?
- Comment sera gérée la multiplicité des voisins et l'état associé à chacun d'eux (e.g. l'id du dernier message envoyé) ?
- Quel mécanisme permettra d'attendre la réponse à un message envoyé, sans bloquer la réception d'autres messages ?
- Comment sera garantie l'absence d'accès concurrent à tout état variable, s'il en existe ?

Dans ce document, tentez d'être brefs bien que complet. Il s'agit en quelque sorte d'augmenter l'entropie de votre document ; chaque phrase doit servir à quelque chose.

## Phase 2 : Implémentation

Une fois la phase 1 terminée, vous aurez accès au code de départ, complété avec les abstractions que nous avons choisies pour répondre aux besoins de ce labo. Il vous faudra les implémenter et les intégrer dans le code existant d'ici la deadline.

### Rendu

Votre rendu doit être intégralement compris dans le commit le plus récent avant la deadline. Cela inclue non seulement le code, mais également le document d'architecture logicielle décrivant votre travail. Celui-ci n'aura besoin de couvrir que vos ajouts ; nul besoin de décrire le code fourni. Il doit satisfaire les mêmes exigences que celles exprimées pour le rendu de la phase 1.