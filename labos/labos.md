---
title: Labos - SDR
css:
    - "/labos/style.css"
---

## Introduction

La partie pratique du cours de SDR se divise en quatre labos consécutifs, construisant chacun sur le précédent. Il s'agira de construire une application distribuée de messagerie instantanée de groupe, dont la spécification fonctionnelle est fournie avec [l'énoncé du labo 1](/labos/1-request-reply.html). Les labos se diviseront comme suit.

- [**Labo 1**](/labos/1-request-reply.html) : Résilience face aux pannes (protocole de fiabilité RR)
- **Labo 2** : Garantie d'ordre total des messages (algorithme d'exclusion mutuelle de Lamport)
- **Labo 3** : Distribution de charge entre serveurs (algorithme d'élection avec gestion de pannes de Chang et Roberts)
- **Labo 4** : Tolérance de réseau incomplètement connecté (utilisation de sondes et échos pour broadcast et découverte topologique pour routage)

Les labos seront à implémenter par groupe de 3 ou 4, au choix.

## Chronologie de chaque labo

Pour chaque labo, le protocole sera le suivant :

- **Séance de conception** : la première séance destinée à chaque labo sera une séance de conception **_individuelle_**. Seul l'énoncé vous sera alors fourni ; pas le code. <span class="remark">(Ceci excepté pour le labo 1, qui vous fournira une base permettant (1) d'accélérer les choses et (2) servir d'exemples pour apprendre à utiliser Go)</span>

  À la fin de celle-ci, vous rendrez **tous** un document markdown ou pdf constituant une spécification de conception, c'est à dire un document décrivant comment le labo pourrait être implémenté. Il faut penser ce document comme celui fourni par l'architecte aux équipes de développement, qui n'auront ensuite qu'à le suivre. Il devra donc notamment inclure
    - les abstractions à définir et leurs APIs
    - leur fonctionnement interne (les structures, goroutines, leurs responsabilités et interactions, etc)
    - leur intégration dans le code existant
  
  Pour chaque labo, nous vous fournirons également un certain nombre de questions auxquelles nous devrons être capables de répondre après lecture de votre spécification, afin de vous aider à être exhaustif. <span class="remark">Par exemple "sous quelle forme sera maintenue la liste des participants à une élection", "comment seront arbitrées deux tentatives de connexion simultanées", "quel choix structurel permettra de garantir l'absence d'accès concurrent au tableau des clients actuellement connectés", etc.</span>

- **Période d'implémentation** : suite à cette séance de conception, nous vous fournirons un code de base pour le labo, qui contiendra un corrigé du labo précédent, ainsi que les APIs des abstractions que nous vous proposons pour ce labo, accompagnées de tests unitaires rudimentaires. Vous aurez alors jusqu'à la deadline pour implémenter le labo, avec comme seule contrainte de ne pas modifier les tests ni les APIs testés.

- **Rendu** : avec votre code, nous vous demanderons également un document markdown ou pdf constituant à nouveau une spécification de conception, cette fois-ci descriptive de la solution que vous avez implémentée.

## Évaluation

Votre note finale pour chaque labo sera calculée comme suit :

- 25% : spécification de conception individuelle. Nous nous placerons dans la peau d'un collègue de travail chargé de valider votre proposition en vue de donner le feu vert aux équipes de développement. Votre note visera à refléter la quantité et l'importance des modifications qu'il aurait à vous demander avant de donner son feu vert et transmettre votre document aux développeur.euses. Cela dépendra donc notamment de
  - l'exhaustivité de votre spécification (notamment en ce qui concerne les questions d'aide fournies dans l'énoncé)
  - la validité de la solution proposée (i.e. s'il existe, ou non, des failles dans votre conception)
- 75% : le rendu final. Nous nous placerons alors dans la peau d'un collègue de travail effectuant une revue de code pour autoriser une merge request dans une branche principale. Votre note visera à refléter la quantité et l'importance des modifications qu'il aurait à demander avant de valider votre merge request. Cela dépendra donc notamment de
  - votre code lui-même (e.g. utilisation pertinente des paradigmes de Go, bonne modularisation, etc)
  - les résultats des tests automatisés, sachant que nous en ajouterons à ceux fournis -- un code qui ne passe pas les tests ne pouvant évidemment pas être merged dans `main`.
  - la qualité de votre spécification de conception et de la documentation de votre code -- un code mal documenté étant pénible à review, mais aussi inacceptable sur `main` pour des raisons de maintenabilité.

Vous comprenez donc qu'il vous faudra viser un travail de qualité professionnelle.