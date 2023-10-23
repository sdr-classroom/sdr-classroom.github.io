---
title: Labo 2 - Gestionnaire de dettes distribué
css:
    - "/labos/style.css"
---

## Changelog

| Date  | Changement                                            |
| ----- | ----------------------------------------------------- |
| |

## Informations Générales
- **Date du rendu** : Lundi 13 Novembre, 13:15 CEST.
- **Groupes** : à réaliser seul ou à deux. Vous pouvez réutiliser les groupes du précédent labo.
- **Plagiat** : en cas de copie manifeste, vous y serez confrontés, vous obtiendrez la note de 1, et l'incident sera reporté au responsable de la filière, avec un risque d'échec critique immédiat au cours. Ne trichez pas. *(Notez que les IAs génératives se trouvent aujourd'hui dans une zone qui est encore juridiquement floue pour ce qui est du plagiat, mais des arguments se valent à en considérer l'utilisation comme tel. Quoiqu'il en soit, nous vous proposons une autre vision sur la question : votre ambition est d'apprendre et d'acquérir des compétences, et votre utilisation éventuelle de cet outil doit refléter ceci. Tout comme Stackoverflow peut être à la fois un outil d'enrichissement et une banque de copy-paste, faites un choix intentionnel et réfléchi, vos propres intérêts en tête, de l'outil que vous ferez de l'IA générative)*

# Introduction

Ce labo a pour but de modifier le précédent pour le rendre non plus centralisé mais distribué. La forme de distribution que nous avons choisie est celle dans laquelle chaque serveur du système aura une réplique locale de l'état actuel des dettes entre les membres du groupe. Il faudra donc s'assurer que ces copies locales sont synchronisés en tout temps.

Vous devez repartir de votre code du labo 1. Si vous avez formé une nouvelle team, utilisez le code de l'un ou l'une des deux membres de la nouvelle team. Si la team à laquelle appartenait ce code contenait deux membres, et que l'autre membre réutilise aussi ce même code dans sa nouvelle équipe **ceci doit être précisé explicitement dans votre README, afin que cela n'apparaisse pas comme du plagiat.**

Puisque ce labo construit sur le premier, toutes les indications du premier énoncé qui ne sont pas rendues obsolètes par celui-ci restent valables et doivent donc continuer d'être vérifiées par votre solution à ce labo-ci.

# Suppositions

Dans ce labo, nous supposerons qu'aucun serveur ne peut tomber en panne fatale. Cela signifie que vous ne devez pas implémenter de gestion de crash ou de disparition d'un serveur, ou encore de serveur dont le comportement est reset (ce qui se produirait si un serveur venait à crash puis serait rebooté).

Votre solution devra, cependant, savoir gérer le cas où un serveur devient soudainement lent, ou est mis en pause pendant une durée arbitraire. Ceci ne devrait, cependant, pas nécessiter de considération particulière dans votre code.

# Serveurs

Plusieurs serveurs peuvent maintenant fonctionner ensemble pour former le système de gestion des dettes. Chaque serveur a une copie locale du graphe de dettes, et ils doivent s'assurer de toujours partager la même vue sur celui-ci. Les principales modifications et ajouts à faire dans ce but sont décrits ici.

## Fichier de configuration

Le fichier de configuration est modifié pour inclure la liste des adresses des serveurs formant le système, sous un champ "servers". Voici un exemple de fichier de configuration avec cette modification.
```json
{
	"debug": true,
	"port": 3333,
	"users": [
        {
            "username": "jessie",
            "debts": []
        },
        {
            "username": "ollie",
            "debts": [
                {
                    "username": "jessie",
                    "amount": 4
                },
            ]
        },
    ],
    "servers": [
	    "127.0.0.1:3333",
	    "127.0.0.1:3334",
	    "127.0.0.1:3335"
    ]
}

```
Le serveur peut, lorsqu'il parse ce fichier, supposer cette liste exhaustive ; nous ne testerons pas le cas d'un fichier de configuration dont la liste de serveurs ne reflette pas le système dans son entièreté.

## Modifications et synchronisation des copies locales

La synchronisation entre serveurs des copies locales se fera à l'aide de l'algorithme d'exclusion mutuelle de Lamport (et non l'une de ses optimisations que nous voyons dans les cours suivants).

Lorsqu'un serveur souhaite effectuer une modification à sa copie du graphe, il doit s'assurer que cette modification est faite sur tous les autres serveurs du système également. Il vous faudra donc mettre en place un protocole de communication permettant cet échange, et permettant au serveur à l'origine de la modification de savoir quand celle-ci a été effectuée partout.

Afin d'assurer que deux serveurs ne peuvent pas déclencher une modification du graphe au même moment et causer une potentielle desynchronisation des copies, toute modification doit être faite dans une section critique, au sens de l'exclusion mutuelle telle que vue en cours. La section critique doit donc être entrée par le serveur à l'origine de la requête avant toute modification à sa copie locale, et doit être quittée uniquement lorsque toutes les copies locales ont été modifiées correctement.

Nous vous encourageons à très clairement séparer les différents modules du serveur, notamment l'abstraction mutex et la partie applicative, ou encore la couche de gestion réseau. Chacun de ces modules a ses responsabilités et devrait pouvoir les implémenter de la manière la plus indépendante possible des autres. Réfléchissez à ces responsabilités et aux APIs nécessaires à chaque module avant de vous lancer dans l'implémentation.

# Clients

## Clear debts

Nous vous demandons d'ajouter une nouvelle commande permettant de rembourser toutes ses dettes. Cette commande ne prend aucun argument, et efface toutes les dettes de l'utilisatrice ou l'utilisateur actuel de ce client. Elle retourne `Success` si tout s'est bien passé, et un message d'erreur clair dans le cas contraire. Quelques changements seront bien sûr nécessaires dans le serveur pour permettre cette nouvelle fonctionnalité.

Voici un exemple d'utilisation de cette nouvelle commande
```sh
$ ./client jessie localhost:3333
> pay 32 for blake
Success
> get debts
blake: 32
32
> clear
Success
> get debts
0
> exit
$
```

## Autres changements

Aucune autre modification n'est nécessaire sur le client. Il continue de prendre en argument l'adresse IP du serveur sur lequel il doit se connecter, et continue de communiquer avec lui comme si ce serveur était l'unique responsable du système. Le but est de rendre l'aspect distribué entièrement invisible à l'utilisateur ou l'utilisatrice.

# Tests

Comme pour le labo précédent, nous vous demandons d'implémenter des tests pour ces nouvelles fonctionnalités et pour vérifier le bon fonctionnement de l'algorithme de Lamport. Nous vous recommandons par ailleurs de garder vos tests actuels et de les compléter si nécessaire.

# Rendu

Les éléments à rendre sont les mêmes que pour le labo précédent, notamment les fichiers executables.

Aussi, nous vous demandons à nouveau de décrire l'architecture logicielle de votre solution dans le README de votre repo. Vous devez décrire les différents modules et principales goroutines, leurs responsabilités et leurs moyens d'interaction avec le reste du système. Toute décision non-triviale doit être justifiée, mais inutile de rentrer dans chaque détail, le but étant de décrire la "big picture" de votre solution. Ceci nous servira à mieux appréhender votre code lorsque nous en évaluerons la qualité manuellement, et à juger de la pertinence de vos choix d'architecture et d'implémentation. Voyez aussi cela comme un exercice simplifié d'écriture de Design Specification.

# Contraintes supplémentaires

Les contraintes du labo précédent s'appliquent également à celui-ci.