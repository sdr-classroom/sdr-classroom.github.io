---
title: Labo 1 - Architecture Logicielle de la solution
css:
    - "/labos/style.css"
back: "/labos/1-request-reply.html"
---

## Exigences

Nous rappelons que le but de ce labo est d'offrir les garanties suivantes :

1. Entre tous deux serveurs sans panne, aucun message ne doit être perdu, dupliqué, ou réordonné.
2. Un accusé de réception doit être reçu exactement une fois pour chaque voisin correct au sens de pannes récupérables.

Nous choisissons d'implémenter un `NetworkInterface` utilisant TCP pour offrir les garanties entre serveurs corrects (1), et implémentant, par dessus, le protocole RR pour garantir les accusés de réception (2). Nous décrivons ici l'architecture proposée pour mettre en oeuvre cette solution. La solution elle-même est fournie comme point de départ au labo 2 <!-- TODO -->.

## Architecture générale

L'architecture choisie se divise en deux modules principaux.

- Un module `RR` qui implémente le protocole de communication RR sur un réseau donné abstrait.
- Un module `TCP` qui implémente un `NetworkInterface` utilisant des connexions RR vivant sur le protocole TCP.

Le module `RR` est intégralement indépendant de `RR`, et `TCP` n'utilise que l'interface publique de `RR`. Ces modules sont décrits ci-dessous.

## RR

### Abstraction

L'abstraction à laquelle correspond `RR` satisfait les propositions suivantes :

- Une instance de `RR` prend en charge la communication avec *exactement un* voisin. Il est donc attendu d'en avoir une par voisin connu.
- Elle permet l'envoi de messages appelés "requêtes" sous forme de `[]byte`, auxquelles la réponse du destinataire peut être obtenue de manière bloquante.
- Une fonction peut être fournie à l'instance de `RR`, qui sera appelée à chaque requête reçue, et devra retourner une réponse sous forme de `[]byte`.
- À sa création, une instance de `RR` nécessite un `RRNetWrapper` représentant la communication avec un réseau arbitraire, sous forme de channels. Ceci généralise `RR` et facilite l'écriture de ses tests.

```go
type RR interface {
	// Sends a request to the remote address associated with this RR instance.
    // Returns a channel on which the response will be sent.
	SendRequest(payload []byte) (response []byte, err error)
	// Sets the handler for incoming requests. The handler should return the
    // response that should be replied to the sender.
	SetRequestHandler(handleRequest func([]byte) []byte)
	// Destroys the RR instance, cleaning up resources.
	Close()
}

type RRNetWrapper struct {
	Outgoing chan<- []byte
	Incoming <-chan []byte
}

func NewRR(logger *logging.Logger, remoteAddr transport.Address,
           network RRNetWrapper) RR { /* ... */ }
```

### Protocole de communication

Les messages utilisés par la couche RR sont une simple struct contenant le type de message (request ou reply), un sequence number et le payload.

```go
const (
	reqMsg msgType = iota
	rspMsg
)

type message struct {
	Type    msgType
	Seqnum  seqnum
	Payload []byte
}
```

Le sequence number est une composition d'un identifiant unique de cette instance de RR, et d'un identifiant unique de la requête parmi toutes celles envoyées par cette instance de RR.

```go
type seqnum struct {
	InstId uint64
	MsgId  uint32
}
```

Ceci permet une unicité globale de l'identifiant du message, à travers les instances de RR.

### Mise en oeuvre

`RR` se divise en trois goroutines.

- Une goroutine d'envoi `handleSendRequests`, responsable du protocole RR coté envoyeur. Elle maintient donc l'id du prochain envoi, et réagit aux événements suivants.
  - Demandes d'envoi, reçues sur la channel `sendRequests chan struct{[]byte, chan []byte}`, où la `chan []byte` correspond à la channel sur laquelle devra être envoyée la réponse du destinataire, une fois reçue. Tout envoi demandé est transmis sur le réseau à travers l'attribut `Outgoing` du `RRNetWrapper`.
  - Réception de messages depuis le réseau, reçus sur le channel `receivedResponses chan *message`, qui sont utilisées pour faire progresser le protocole RR.
- Une goroutine de gestion des requêtes reçues du réseau, `handleReceivedRequests`. Les messages reçus sont obtenus sur la channel `receivedRequests chan *message`. Est alors appelé le request-handler fourni à la création du `RR`, dont la réponse est envoyée sur le réseau via `Outgoing` de `RRNetWrapper`.
- Une goroutine de répartition des messages reçus par le réseau à travers la channel `Incoming` du `RRNetWrapper`. Elle envoie les messages de type réponse à `handleSendRequests` et ceux de type requête à `handleReceivedRequests`, via des channels dédiés partagés via la struct implémentant `RR`.

Nous omettons également la clôture qui suit l'approche suivante :

- La méthode `Close()` ferme une channel `closeChan` ainsi que les channels écrites par des méthodes publiques.
- La clôture de la channel `closeChan` est détectée par toute goroutine indépendante des méthodes publiques (ici, le dispatcher uniquement).
- Cette goroutine clôture à son tour toute goroutine qu'elle écrit pour communiquer avec d'autres goroutines, leur signalant par là qu'elles doivent également terminer (ici, `handleSendRequests` et `handleReceivedRequests` à travers les channels utilisés pour leur envoyer les requêtes et réponses).

Cette approche est généralement suffisante et efficace dans les cas où il n'existe qu'un envoyeur pour chaque channel.

### Schéma

Toute l'architecture de la couche `RR` est résumée dans le schéma ci-dessous.

<img src="/labos/imgs/1-RR.png"/>

## TCP

La couche TCP sert presque exclusivement de wrapper autour d'un autre objet que nous appelons un "Gestionnaire de voisins", ou "Remotes Handler". Ce dernier est motivé par le protocole de mise en place de connexion entre voisins que nous avons choisis. Nous commençons donc par décrire ce protocole.

### Protocole de connexion

Nous souhaitons satisfaire les deux contraintes techniques suivantes que nous nous imposons dans un but d'optimisation et d'élégance. Il aurait bien sûr existé des manières moins strictes et plus simples d'implémenter ceci.

- Entre tous deux voisins, une seule connexion TCP doit exister.
- Les connexions aux voisins sont créées de manière lazy au moment de l'envoi, afin que l'utilisateur n'ait pas besoin de gérer les connexions.

Afin de satisfaire la première exigence, nous imposons comme invariant le fait qu'une connexion valide entre deux serveurs ne peut avoir été instaurée que par un serveur dont l'adresse IP est plus petite que celle de son correspondant. Ceci dans le but de résoudre le problème de deux serveurs tentant de se connecter l'un à l'autre au même moment.

Le protocole de connexion est donc le suivant :

- Lorsqu'une connexion doit être établie avec un voisin (e.g. lors d'une demande d'envoi à un nouveau voisin), une connexion TCP avec ce voisin est établie.
- Un message de présentation est envoyé par l'instaurateur de la connexion, incluant l'adresse IP sur laquelle ce dernier accepte de nouvelles connexions TCP. Cela sert à informer le destinataire de son identité, qu'il ne pourrait sans cela pas connaitre.
- Si la connexion est valide (i.e. l'adresse du destinataire est supérieure à celle de l'instaurateur de la connexion), elle peut être utilisée par l'instaurateur immédiatement, et par le destinataire dès réception du message de présentation.
- Si la connexion est invalide, le destinataire clos immédiatement la connexion et en déclenche une nouvelle. L'instaurateur, lui, attend que la connexion soit fermée par le destinataire. Il est alors garanti qu'une connexion à ce destinataire sera créée sous peu, par ce dernier.

De plus, dans le cas où une connexion est perdue en cours d'exécution (par exemple si le voisin tombe en panne), cela ne doit pas être visible par l'utilisateur de la couche de gestion des voisins. Aussi, le protocole RR doit garantir que tout message perdu finira par arriver lorsque la connexion sera à nouveau établie.

### L'abstraction

Le gestionnaire de voisins est responsable d'abstraire cette complexité. Il n'offre qu'une méthode permettant l'envoi d'un message à un voisin donné par une adresse IP. Cette méthode bloquera jusqu'à ce que le message soit reçu et traité par le voisin. La gestion des connexions, leur mise en place et leur maintient, ne font pas partie de l'abstraction.

Le gestionnaire, lors de sa création, demande aussi une channel sur laquelle il écrira tout message reçu, `receivedMessages`.

L'interface de ce gestionnaire peut être résumée en l'interface suivante :

```go
type RemoteHandler interface {
    // Request sending a message to the given remote. Will block until the
    // message was acknowledged to be received and treated by the remote.
    SendToRemote(dest Address, payload []byte)
    // Closes all resources used by the remote handler
    Close()
}

func NewRemoteHandler(self Address, logger *logging.Logger,
                      receivedMessages chan<- Message) RemoteHandler { /* ... */ }
```

### La mise en oeuvre

#### L'objet remote

Un `remote` représente un voisin, avec lequel il n'existe peut-être pas encore de connexion. Il regroupe une instance de `RR` qui sera utilisée pour communiquer avec ce voisin, un `RRNetWrapper` pour abstraire le moyen de communication effectif (ici, une connexion TCP), et une channel `sendRequests` de type `BufferedChan` (fournie dans le package `utils`) dans laquelle seront transmis tous les messages à envoyer à ce voisin.

#### Goroutines centrales

Nous commençons par décrire la goroutine principale, `handleRemotes`, responsable de la gestion d'une grande partie de l'état, c'est à dire la liste des objets `remote` connus et les connexions ouvertes. Elle répond aux événements suivants.

- Demande d'envoi via la channel `sendRequests` (sur laquelle la méthode publique `SendToRemote` écrit). Si le voisin demandé n'est pas connu ou qu'il n'a pas de connexion associée, une goroutine est lancée pour démarrer le protocole de connexion. Un objet remote est alors créé (ou réutilisé si déjà existant), et l'envoi est fait via sa channel `sendRequests`.
- Demande de création d'un nouveau remote via la channel `newRemoteRequest`. L'action est identique à la demande d'envoi, à la différence que rien n'est envoyé sur la connexion.
- Notification de l'existence d'une nouvelle connexion. La liste des connexions est alors mise à jour, et une goroutine de gestion de cette connexion est lancée.
- Notification de clôture d'une connexion. La connexion en question est retirée de la collection.

La goroutine responsable de démarrer le protocole de connexion est `tryConnect`. Elle ne fait qu'instaurer une connexion TCP au voisin demandé et lui envoyer son adresse IP, suivant le protocole décrit plus tôt. Si la connexion est valide, elle notifie alors la goroutine principale d'une nouvelle connexion ; sinon elle attend que le voisin clôture la connexion puis termine simplement (le voisin sera chargé d'instaurer une connexion de son coté).

Enfin, une goroutine est responsable d'accepter de nouvelles connexions TCP. Lorsqu'elle en reçoit une, elle attend le message de présentation contenant l'adresse du voisin. Si la connexion est valide, elle notifie la goroutine principale d'une nouvelle connexion ; sinon elle la clôture immédiatement et envoie une demande de nouveau remote à la goroutine principale (qui causera donc le lancement d'une goroutine `tryConnect` pour instaurer une connexion dans le sens valide).

#### Goroutines par voisin

Nous décrivons maintenant les goroutines dont il existe une instance par voisin connu.

- Une goroutine correspondant à une simple file d'attente pour les messages destinés à être envoyés à travers l'instance de `RR`. Elle est lancée par la goroutine principale dès la création d'un nouveau `remote`. Elle réagit aux demandes d'envoi sur sa channel `sendRequests`, et transfère le message via la méthode `SendRequest()` de son instance `RR`. Notez que ceci peut arriver avant même qu'une connexion ne soit établie, mais ne risque pas de causer de deadlock car `sendRequests` est une `BufferedChan`, d'où l'idée que cette goroutine serve de "file d'attente".
- Une paire de goroutines responsables du `RRNetWrapper` fourni à l'instance de `RR`. Pour rappel, il s'agit d'une paire de channels que `RR` utilisera pour communiquer avec le voisin indépendamment du protocole exact (ici, TCP). Bien que les channels sont créés en même temps que le `remote`, les goroutines ne sont lancées qu'une fois que la connexion est établie.
  - La première écoute les réceptions sur cette connexion et les transmet au `RR` via `RRNetWrapper.Incoming`. Si la connexion est clôturée par le voisin, elle notifie la goroutine principale de la clôture d'une connexion puis termine.
  - La seconde écoute les demandes d'envoi que fait `RR` via `RRNetWrapper.Outgoing` et les transmet sur la connexion. C'est ici que `RR` bloquera tant que la connexion ne sera pas établie et que cette paire de goroutines ne sera pas lancée.

#### Schéma

Toute l'architecture du gestionnaire de voisins est résumée dans le schéma suivant.

<img src="/labos/imgs/1-Remotes.png"/>

### La couche TCP

Enfin, l'abstraction de gestionnaire de voisins est utilisée pour implémenter l'abstraction d'une `NetworkInterface`.

Une unique nouvelle goroutine sert à maintenir la liste des souscriptions à la réception de messages, et à propager aux souscrits tout message reçu via la channel `receivedMessages`.

Cette partie est résumée dans le schéma suivant.

<img src="/labos/imgs/1-tcp.png"/>

