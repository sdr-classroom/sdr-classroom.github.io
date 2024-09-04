---
title: Labo 1 - Architecture Logicielle de la donnée
css:
    - "/labos/style.css"
back: "/labos/1-request-reply.html"
---

## Structure générale

Respectueusement des conventions en Go, la structure du projet se divise en un package `cmd` ne faisant qu'utiliser les packages définis dans `internal`.

- `/cmd/` contient les main packages, actuellement uniquement `server`
- `/internal/` contient les packages utilisés par l'exécutable `server`.
  - `/internal/transport/` abstrait la couche réseau en un API simple
  - `/internal/server/` est responsable de la partie applicative, indépendante du réseau -- écoute d'entrées sur stdin et affichage des messages reçus.
  - `/internal/logging/` offre une structure simplifiant la création de logs.
  - `/internal/utils/` contient des structures d'aide variées.

## Architecture en couches

Dans un soucis de séparation des préoccupations, ainsi que pour faciliter l'extension dans le futur, nous choisissons une architecture en couches, dont il en existe pour l'instant deux : Transport et Server.

### Transport

La couche **transport** occulte la complexité du réseau derrière une abstraction qui prend la forme d'une interface `NetworkInterface`, définie dans `networkInterface.go`. Cela permettra un changement de protocole de communication sans effets pour les couches utilisatrices du réseau.

#### Abstraction

L'interface `NetworkInterface` définit tout objet capable d'envoyer et recevoir des octets de la part de processus identifiés par une adresse IP. L'utilisation d'octets pour rendre cette couche indépendante de son contexte d'utilisation.

La `NetworkInterface` utilise un modèle de souscription pour la réception de messages. Elle définit pour cela une interface `MessageHandler` décrivant tout objet offrant une méthode `HandleNetworkMessage(*Message) (wasHanlded bool)` qui retourne un booléen ssi le message reçu a été traité. La `NetworkInterface` est alors responsable de partager chaque message reçu à tous les souscrits à travers cette méthode, jusqu'à ce que l'un d'eux affirme l'avoir traité. Elle peut donc supposer que tout message n'appartient qu'à un seul souscrit.

Les méthodes d'une `NetworkInterface` sont les suivantes :

  - `Send(addr Address, payload []byte) error`.
  - `RegisterHandler(MessageHandler) HandlerId` pour souscrire un `MessageHandler`.
  - `UnregisterHandler(HandlerId)` pour résilier une souscription à l'aide de l'identifiant obtenu à la souscription.
  - `Close()` pour fermer toute connexion et goroutine en cours.

Nous n'offrons pour l'instant qu'une seul implémentation de cette interface, `UDP`, que nous décrivons dans la suite de cette section.

#### État interne

L'état interne d'une instance de `UDP`, c'est à dire toute donnée dont dépend le comportement de l'instance et qui peut changer au cours de l'exécution, se réduit aux valeurs suivantes.

- La connexion UDP d'écoute de messages reçus.
- La liste des souscrits à la réception des messages.
- La liste des voisins connus et leur connexion associée.

Il est important de déterminer ces états puisque, par leur variabilité à travers le temps, il est nécessaire d'en prévenir tout accès concurrent. Cela est garanti par le choix des goroutines.

#### Goroutines principales

Nous analysons ici les contraintes techniques auxquelles nous faisons face, et les goroutines permettant de les satisfaire.

Les événements auxquels cette couche doit répondre sont les suivants, associés aux états auxquels elles doivent avoir accès

- Réception de message - accès à la liste des souscrits.
- Demande de souscription ou résiliation aux réceptions - modification de la liste des souscrits
- Demande d'envoi de message - accès à la liste des voisins connus, et modification potentielle si le voisin demandé n'est pas encore connu.
- Demande de clôture de l'interface réseau - accès à la liste des voisins connus et leur connexion associée, ainsi que la connexion d'écoute de messages reçus.

Étant donné qu'aucune paire de ces événements ne doit pouvoir être exécutée en parallèle, nous optons pour la solution simple de regrouper leur gestion en une seule goroutine, `handleState`. Ainsi, tous les événements seront traités séquentiellement, évitant donc tout risque d'accès concurrent aux variables d'état. Afin d'éviter toute erreur lors de l'implémentation, ces variables d'état seront des variables locales à la goroutine, et non des attributs de la struct `UDP`.

La gestion de la clôture de l'interface réseau se fait à l'aide d'une unique channel, `closeChan`, qui sera clôturée au moment d'une demande de clôture. Elle pourra ainsi être surveillée par toutes les goroutines pour détecter leur nécessité de s'interrompre.

Une seconde goroutine, `listenIncomingMessages`, est responsable d'écouter les messages reçus sur UDP, et les transmettre à `handleState` pour envoi aux souscrits. Celle-ci génère une petite goroutine écoutant simplement `closeChan` et clôturant la connexion UDP d'écoute, permettant de notifier la goroutine principale en faisant échouer l'écoute.

Enfin, afin d'éviter de recréer une connexion au même voisin à chaque envoi, la goroutine `handleState` crée une goroutine pour chaque voisin auquel une demande d'envoi a été faite. Cette dernière est responsable de la connexion avec ce voisin, et une channel créée et maintenue par `handleState` lui est fournie. Cette channel sera utilisée par `handleState` pour informer la goroutine du message à envoyer, puis clôturée pour indiquer la fin de programme.

<img src="/labos/imgs/1-udp.png"/>

<details>
<summary>
Pour le détail des goroutines et leurs moyens de communication...
</summary>

Il existe donc trois goroutines principales communiquant par channels.

- `handleSends` est responsable d'envoyer des messages à une connexion donnée. Une nouvelle est donc créée pour chaque nouvelle connexion. Elles réagissent aux événements suivants :
  - Demandes d'envoi sur la connexion correspondante (reçues sur `sendChan chan []byte`).
  - Clôture de la channel `sendChan` comme un signal de fin d'exécution de la goroutine.
- `handleState` est la goroutine principale et maintient la liste des souscrits et des voisins connus. Elle réagit aux événements suivants :
  - Demande d'envoi de bytes à un voisin donné (reçues sur `sendRequests chan struct{Address, []byte}`). Crée alors une instance de `handleSends` associée à ce voisin, et lui transmet la demande.
  - Demande de souscription d'un handler (reçues sur `registrations chan struct{HandlerId, MessageHandler}`, où `HandlerId` est un alias d'`uint32` et `MessageHandler` est tel que défini plus tôt).
  - Demande de résiliation d'un handler (reçues sur `unregistrations chan HandlerId`)
  - Notification de réception de message (reçues sur `receivedMessages chan Message`). Transmet alors le message reçu aux handlers souscrits.
  - Demande de fin d'exécution de la goroutine (reçue par la clôture d'une channel `closeChan`). Transmet alors la clôture à toutes les goroutines `handleSends` en clôturant leur channel `sendChan`.
- `listenIncomingMessages` est responsable de la réception de messages. Elle réagit aux événements suivants :
  - Réception de messages par la connexion UDP, qu'elle transmet ensuite à `handleState` par la channel `receivedMessages`
  - Clôture de la channel `closeChan` pour clôturer la connexion UDP et donc la réception de messages.


</details>

### Serveur

Le serveur est responsable uniquement de l'écoute d'entrée sur stdin, et l'affichage des messages reçus. Aucun état modifiable majeur n'existe dans cette couche.

Le serveur est une struct offrant deux méthodes.

- `Start` déclenche l'écoute de stdin et du réseau. Son constructeur, `NewServer`, prend comme argument une instance de `ServerConfig` décrivant sa configuration (voir ci-après).
- `Close` déclenche la fermeture du serveur et de l'interface réseau qu'il utilise. Cela se fait à nouveau à l'aide d'une goroutine, `closeChan`, dont la fermeture est détectée par toutes les autres goroutines.

#### Goroutines principales

Il existe une seule goroutine centrale au serveur. Celle-ci est responsable d'écouter et envoyer sur le réseau les entrées de l'utilisateur.ice. Elle crée également une goroutine secondaire responsable uniquement de traduire l'appel bloquant à la lecture IO en une transmission sur channel, afin de permettre l'utilisation du `select` de Go.

La gestion des réceptions se fait par une souscription au `NetworkInterface` lors de la construction de la structure. Aucune goroutine n'est donc nécessaire ici.

#### Structures additionnelles

Quelques structures supplémentaires permettent de séparer les préoccupations.

- `ServerConfig` peut être créé à l'aide de `NewServerConfig`, qui est responsable de lire le fichier de configuration et peupler une instance de `ServerConfig`.
- `messages.go` offre une interface `Message` définissant les types de messages qui peuvent être encodés avec `gob`. `ChatMessage` est une implémentation de cette interface définissant un message de chat.

## Modules complémentaires

Quelques autres modules d'aide sont fournis.

- `Logger` est une structure permettant de logger des messages de différents niveaux d'importance (`INFO`, `WARN`, `ERR`), qui seront affichés dans la console ainsi que, optionellement, dans un fichier.
- `IOStream` est une interface qui abstrait l'écriture et la lecture sur un stream IO. Elle offre les méthodes `ReadLine()`, `Println()` et `Print()`. Elle est implémentée par les structs `stdStream` pour l'abstraction de stdin/stdout, et `mockStream` pour une simulation de stream utilisable par les tests.
- Le package `utils` propose quelques outils pratiques
  - `Option[T any]` implémente l'abstraction [Optional](https://www.codeproject.com/Articles/17607/The-Option-Pattern).
  - `BufferedChan` implémente une abstraction de channel à taille variable.
  - `UIDGenerator` implémente un générateur d'identifiants uniques.