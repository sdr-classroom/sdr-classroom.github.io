---
title: Labo 3 - Gestionnaire de dettes distribué avec distribution de charge
css:
    - "/labos/style.css"
---

## Changelog

| Date  | Changement                                            |
| ----- | ----------------------------------------------------- |
| 27.11 | Nécessité d'envoyer un ACK dans le mainteneur d'anneau, [ici](#change_ack_necessary) |
| 12.12 | Deadline changée au 08 janvier ; **néanmoins, il est recommandé de commencer le labo 4 avant** |

## Informations Générales
- **Date du rendu** : Lundi 08 janvier, 23:59 CEST.
- **Groupes** : à réaliser seul ou à deux. Vous pouvez réutiliser les groupes du précédent labo.
- **Plagiat** : en cas de copie manifeste, vous y serez confrontés, vous obtiendrez la note de 1, et l'incident sera reporté au responsable de la filière, avec un risque d'échec critique immédiat au cours. Ne trichez pas. *(Notez que les IAs génératives se trouvent aujourd'hui dans une zone qui est encore juridiquement floue pour ce qui est du plagiat, mais des arguments se valent à en considérer l'utilisation comme tel. Quoiqu'il en soit, nous vous proposons une autre vision sur la question : votre ambition est d'apprendre et d'acquérir des compétences, et votre utilisation éventuelle de cet outil doit refléter ceci. Tout comme Stackoverflow peut être à la fois un outil d'enrichissement et une banque de copy-paste, faites un choix intentionnel et réfléchi, vos propres intérêts en tête, de l'outil que vous ferez de l'IA générative)*

# Introduction

Dans ce labo, nous vous demandons d'implémenter l'algorithme d'élection de Chang et Roberts avec gestion des pannes vu en cours pour permettre une distribution dynamique de la charge entre les serveurs formant le système distribué.

Vous devez repartir de votre code du labo 2. Si vous avez formé une nouvelle team, utilisez le code de l'un ou l'une des deux membres de la nouvelle team. Si la team à laquelle appartenait ce code contenait deux membres, et que l'autre membre réutilise aussi ce même code dans sa nouvelle équipe **ceci doit être précisé explicitement dans votre README, afin que cela n'apparaisse pas comme du plagiat.**

Puisque ce labo construit sur les précédents, toutes les indications des précédents énoncés qui ne sont pas rendues obsolètes par celui-ci restent valables et doivent donc continuer d'être vérifiées par votre solution à ce labo-ci.

# Distribution de charge

Dans le précédent labo, le client était celui responsable de choisir le processus auquel il se connecte. Ceci peut poser problème dans un contexte où un grand nombre de clients se connectent au service à travers le même processus, qui sera alors surchargé par rapport aux autres. Dans ce labo, vous utiliserez l'algorithme d'élection de Chang et Roberts pour trouver le processus actuellement le moins chargé (en terme de nombre de clients lui étant connectés), à chaque fois qu'un nouveau client souhaite se connecter au service.

# Suppositions

Dans ce labo, nous continuerons de supposer qu'aucun serveur ne peut tomber en panne durant une section critique, afin que vous n'ayez pas à modifier cette partie-là de la logique.

En revanche, nous supposerons qu'il est possible qu'un serveur tombe en panne durant une élection, ainsi que durant les "temps morts", c'est à dire les moments où aucun serveur n'est en train d'executer une quelconque action.

Ces pannes ne seront pas nécessairement définitives, ce qui signifie qu'un processus tombé en panne peut à nouveau rejoindre le système plus tard. En revanche, nous supposerons qu'un processus étant tombé en panne ne gardera pas son étant d'avant-panne. Par exemple, si un processus était sur le point d'envoyer un message (par exemple un `ACK`) avant de tomber en panne, cet envoi ne sera pas repris et terminé une fois le processus rétabli de sa panne.

Nous ferons aussi la (forte) supposition que tout message sera reçu en moins de 5 secondes, et que les temps de traitement seront comparativement négligeables. Cela signifie qu'un message restant sans réponse durant plus de 10 secondes implique que son destinataire est tombé en panne.

<span id="change_ack_necessary"></span>

## Remarques sur le mainteneur d'anneau

Dans le cours, le mainteneur d'anneau utilise des ACKs pour détecter la panne d'un voisin. Vous aurez peut-être noté que le fait d'utiliser TCP dans ce labo vous offre, en supplément gratuit, un détecteur de panne : si le serveur suivant est en panne, alors sa connection sera fermée, et elle pourra être détectée rapidement, et probablement avant qu'ait lieu un timeout dû à une non-réception d'un ACK.

Toutefois, notez que ce ACK reste nécessaire. En d'autres termes, le fait d'avoir un détecteur de pannes dans le mainteneur d'anneau ne suffit à supprimer les ACKs. En effet, si un processus $A$ détecte une panne chez son prochain $B$ juste après lui avoir envoyé un message, rien ne lui permet de savoir si $B$ est tombé en panne avant ou après avoir reçu, ou même traité, son message.

Il reste donc nécessaire que le recepteur d'un message envoie un ACK après avoir reçu *et traité* le message, afin de permettre à son envoyeur de le renvoyer au suivant si le message n'a pas été traité avec certitude. Notez aussi que cela autorise un serveur à tomber en panne après avoir traité un message mais *avant* d'avoir pû envoyer le ACK ; ce message aura donc été traité deux fois au total, chez les deux successeurs de l'envoyeur initial. Ceci n'est pas un problème pour l'algorithme Chang et Roberts, qui est capable de se remettre d'un tel scénario.

# Serveur

Nous vous proposons l'approche suivante pour permettre la distribution de charge. Vous êtes libres de choisir une autre solution, mais il vous faudra dans tous les cas respecter l'expérience utilisateur que notre proposition implique, et utiliser l'algoritthme d'élection Chang et Roberts avec gestion des pannes.

Au moment où un nouveau client tente de se connecter à un processus pour créer une session, deux cas de figure peuvent se présenter.

- Si le processus contacté est l'élu, alors il peut directement commencer à le servir (par exemple à travers la connection déjà en place, ou bien une nouvelle, c'est à vous de décider en fonction de votre implémentation).
- Si le processus contacté n'est pas l'élu, alors il répondra avec l'adresse de l'élu, et ne servira donc pas ce client lui-même.

Une fois que l'élu a pris en charge un nouveau client, il doit immédiatement arrêter de se considérer élu, et demander une nouvelle élection.

Vous êtes libres de choisir quel processus est initialement l'élu, et quelle règle est utilisée pour départager de manière uniforme les cas d'égalité d'aptitudes. La seule contrainte est évidemment qu'il n'y ait toujours qu'un seul élu à la fois.

Si une requête de la part d'un client arrive en cours d'élection, alors celle-ci pourra être mise en attente jusqu'à ce que l'élu soit connu.

## Récupération de panne

Lorsqu'un processus tombe en panne puis est relancé, son état a été perdu. En particulier, le graphe de dettes sera de nouveau à l'état initial donné par le fichier de configuration.

Pour remédier à cela, nous pourrions persister l'état dans une base de données par exemple. Cependant, nous vous proposons une autre approche. Lorsqu'un serveur se lance et met en place une connection aux autres processus du système, ces derniers lui partagent l'état actuel de leur graphe de dettes. Le processus nouvellement connecté mettra ainsi à jour son état local pour qu'il coïncide avec ceux reçus de la part des autres serveurs du système.

Notez que ceci ne posera pas de problème grâce à notre supposition d'absence de panne lors d'interractions sur le graphe de dettes.

Nous avons préféré cette approche-ci à d'autres consistant à persister les données pour plusieurs raisons. Tout d'abord, le cout d'implémentation sera probablement plus faible ici. Ensuite, cela met en avant une considération importante des systèmes distribués : nous supposons ici qu'aucune panne n'a lieu durant une mutation de l'état global, mais ceci n'est pas réaliste. Dans un vrai système distribué, des algorithmes plus complexes que celui de Lamport sont utilisés, autorisant ainsi les pannes, et permettant au système de continuer d'évoluer pendant qu'un processus n'est plus en ligne. Lorsque ce dernier se reconnecte au système, son état persisté sera certes utile, mais il lui faudra ensuite échanger avec ses voisins pour se mettre à jour sur les évenements qu'il aura raté le temps de son absence. Vous implémentez donc ici une version relativement simplifiée d'une telle phase de remise à jour.

## Fichier de configuration

Le fichier de configuration du serveur ne prend aucune modification syntaxique. En revanche, la liste des serveurs spécifiée dans la propriété `servers` est maintenant ordonnancée de manière à ce que deux processus consécutifs dans cette liste sont voisins dans l'anneau utilisé par l'algorithme de Chang et Roberts, et de même pour le dernier et le premier, voisins également dans l'anneau.

# Client

Du point de vue de l'utilisateur•rice, aucun changement ne doit être visible, si ce n'est un léger délai au moment de lancer le client, le temps qu'il trouve le bon serveur auquel se connecter. En particulier, **le client ne doit rien afficher pendant qu'il attend de pouvoir se connecter à l'élu**.

Au lancement du client, celui-ci entre donc dans la boucle suivante pour obtenir l'adresse d'un serveur acceptant de le prendre en charge :

1. Il contacte le processus dont l'adreesse lui est donnée en argument (comme il le fait déjà dans le labo précédent), pour lui demander s'il est prêt à le prendre en charge (en d'autres termes, s'il est l'élu)
2. Ce processus peut répondre de deux manières différentes :
    - soit il accepte de le prendre en charge (il est donc l'élu), et le client peut donc communiquer avec ce processus pour le reste de la session ;
    - soit il n'accepte pas, et lui communique l'adresse d'un autre serveur moins chargé (l'élu). Le client doit alors recommencer à l'étape 1 avec ce nouveau processus.

La raison pour laquelle le client ne peut pas simplement commencer à interragir immédiatement avec l'élu lorsqu'on lui en donne l'adresse est qu'il est possible que deux clients tentent de se connecter simultanément, et soient donc redirigés vers le même processus ; or celui-ci n'acceptera que le premier, et devra déterminer le nouvel élu avant de répondre au second.

Afin de pouvoir tester ceci, nous vous demandons d'ajouter une nouvelle commande au client, `server`, qui ne communique pas avec le serveur, mais affiche simplement l'adresse complète (nom de domaine et port) du processus auquel il est connecté, sur une nouvelle ligne. Ceci casse légèrement la volonté de rendre opaque le fait que le client n'est pas connecté au processus spécifié à son lancement, mais cela facilitera les tests.

Notez qu'une fois le client connecté, il ne changera plus de serveur. On pourrait imaginer une optimisation future déclenchant une redistribution des clients en cas de déséquilibre, mais ceci n'est pas demandé dans ce labo.

# Tests

Nous utiliserons des tests automatisés pour vérifier que, lors de la connection simultanée de beaucoup de clients sur différents serveurs, le résultat sera toujours le plus équilibré possible.

Nous vérifierons aussi bien sûr que le reste du gestionnaire de dettes fonctionne toujours comme décrit dans les deux précédents labos.

Nous ne testerons cependant pas de scénarios dans lesquels les serveurs tombent en panne, ou sont en panne, durant des commandes `pay`, `get` ou `clear` des clients, puisque cela sort du scope de ce labo.

Nous évaluerons aussi la qualité de votre code et de votre solution manuellement, afin de pénaliser l'utilisation de locks, ou de découvrir des risques de race conditions non-découverts par nos tests.

Vous êtes par ailleurs libres, et il vous est même recommandé, d'implémenter des tests supplémentaires, que ce soit end-to-end en utilisant par exemple le framework que nous avons mis en place pour les tests que nous vous avons fourni au labo 2, ou unitaires pour les nouvelles fonctionnalités de ce labo-ci.

# Rendu

Les éléments à rendre sont les mêmes que pour le labo précédent, notamment les fichiers executables.

Aussi, nous vous demandons à nouveau de décrire l'architecture logicielle de votre solution dans le README de votre repo. Vous devez décrire les différents modules et principales goroutines, leurs responsabilités et leurs moyens d'interaction avec le reste du système. Toute décision non-triviale doit être justifiée, mais inutile de rentrer dans chaque détail, le but étant de décrire la "big picture" de votre solution. Ceci nous servira à mieux appréhender votre code lorsque nous en évaluerons la qualité manuellement, et à juger de la pertinence de vos choix d'architecture et d'implémentation. Voyez aussi cela comme un exercice simplifié d'écriture de Design Specification.

# Contraintes supplémentaires

Les contraintes du labo précédent s'appliquent également à celui-ci.