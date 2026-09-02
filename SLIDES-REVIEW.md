# Revue des slides SDR — observations

Relecture complète des 15 decks liés depuis `sdr-classroom.github.io/index.html`
(0-intro, 0-1-pannes, 1-go, 2-1-horloges, 2-2-mutex-lamport, 3-1-jetons-multiples-mutex,
3-2-mutex-jeton-unique, 4-0-diffusion-elections-bully, 4-2-diffusion-elections-cr,
4-3-diffusion-elections-cr-pannes2, 5-1-sondes-echos, 5-2-synchronisation, 6-battements,
7-consensus, 7-1-consensus-raft), croisée avec `fiche_unite.md` et les donnés de labo
(`sdr-classroom.github.io/labos/*.md`).

**Convention de référence.** `deck / S<n>.<k>` = n-ième slide horizontale du deck, k-ième
étape verticale (fragment de build). Ex. `2-2-mutex-lamport / S4.6`.

**Comment compléter ce document.** Chaque observation a un identifiant stable, un constat,
et une ligne `**Solution :**` vide à remplir. Les observations sont triées par importance
décroissante ; les tranches P1/P2/P3/P4 sont indicatives.

**Suivi.** Les observations sont regroupées en 13 issues sur
[`sdr-classroom/website-private`](https://github.com/sdr-classroom/website-private/issues) — **dépôt privé**, cf. `CLAUDE.md`.
Une branche + une PR par issue. Ce fichier reste la source des constats détaillés ; les issues
portent les décisions et l'avancement.

| Issue | Titre | Observations |
|---|---|---|
| [#1](https://github.com/sdr-classroom/website-private/issues/1) | Modèle système : suppositions et vocabulaire « synchrone » *(décision)* | O13, O14, O33, O34, O42 |
| [#2](https://github.com/sdr-classroom/website-private/issues/2) | Chapitre fiabilité : diffusion fiable, RR\*, RPC/adressage *(décision)* | O24, O25, O26 |
| [#3](https://github.com/sdr-classroom/website-private/issues/3) | Gabarit des decks : pseudocode et complexités manquants *(décision)* | O28, O29, O30 |
| [#4](https://github.com/sdr-classroom/website-private/issues/4) | Deck Go | O9, O10, O11, O39, O40, O41 |
| [#5](https://github.com/sdr-classroom/website-private/issues/5) | Mutex : Raymond, Ricart & Agrawala, complexités | O1, O2, O3, O8 |
| [#6](https://github.com/sdr-classroom/website-private/issues/6) | Élection (Bully) | O15, O16, O17 |
| [#7](https://github.com/sdr-classroom/website-private/issues/7) | Chang & Roberts | O18, O19, O20 |
| [#8](https://github.com/sdr-classroom/website-private/issues/8) | Sondes et échos | O4, O5, O21, O22 |
| [#9](https://github.com/sdr-classroom/website-private/issues/9) | Battements | O7, O31, O43, O44 |
| [#10](https://github.com/sdr-classroom/website-private/issues/10) | Consensus et Raft | O6, O12, O23 |
| [#11](https://github.com/sdr-classroom/website-private/issues/11) | Fautes de frappe *(à faire en premier)* | O35 |
| [#12](https://github.com/sdr-classroom/website-private/issues/12) | Titres des decks et noms de dossiers | O36, O37, (O27 noté) |
| [#13](https://github.com/sdr-classroom/website-private/issues/13) | Nettoyage de `slides/` | O38 |

O32 (calendrier des labos) est traité par la refonte `sdr-labs/`, pas ici.

---

## P1 — Erreurs qui induisent les étudiant·e·s en erreur

Ces points sont des bugs dans du contenu que les étudiant·e·s recopient (pseudocode, chiffres,
code Go). Ils sont à corriger en priorité.

### O1. Raymond : le pseudocode donne le jeton alors qu'on est en SC
`3-2-mutex-jeton-unique / S8.3–S8.7`

La variable `inSC` (« booléen, init false, ssi je suis actuellement en SC ») est déclarée dans
le tableau des variables mais **n'est jamais lue ni écrite** dans le pseudocode. Conséquence :
sur `Réception de REQ de la part de i`, si `parent` est `nil` (donc j'ai le jeton) et que je suis
en section critique, `handleJeton` est exécuté immédiatement, dépile la file et **envoie le jeton
alors que je suis en SC**. L'exclusion mutuelle est violée. Il manque un garde
`Si inSC, sortir` en tête de `handleJeton` (l'équivalent du `if not using` de Raymond 1989),
plus la mise à jour de `inSC` à l'entrée et à la sortie de SC.

**Solution :** Double-checker que c'est effectivement nécessaire, puis si oui ajouter ça, en faisant attention de garder le visuel correct. cette attention doit tenir sur tous les changements qu'on fera ici.

### O2. Raymond : `hasRequested` n'est pas remis à `true` après réémission d'un REQ
`3-2-mutex-jeton-unique / S8.7`

Dans `handleJeton` : `hasRequested ← false` est exécuté, puis dans la branche `Sinon` on fait
`Envoyer OK à p ; parent ← p ; Si queue n'est pas vide → Envoyer REQ à p`. Ce dernier REQ est
bien envoyé, mais `hasRequested` reste à `false`. Une réception ultérieure de REQ enverra donc
un second REQ au parent alors qu'un est déjà en vol (le `Sinon, si hasRequested est false` de
`Réception de REQ` ne filtre plus rien).

**Solution :** même chose que O2. J'ai un doute sur la nécessité de ce changement. hasRequested ne décrit-il pas que *ce* processus a demandé le jeton? Pas qu'il a forwardé une autre requête ? Ou justement si ?

### O3. Ricart & Agrawala : deux noms pour la même variable
`3-1-jetons-multiples-mutex / S5.2, S5.3, S5.5`

La variable est déclarée `missingOKs`, l'événement s'appelle « Passage de `missingOKs` à 0 »,
la demande de SC fait `missingOKs ← n-1`, mais le handler `Réception {OK, tsi}` fait
`waitingOKs -= 1`. `waitingOKs` n'existe nulle part ailleurs : le compteur n'est jamais
décrémenté, l'entrée en SC n'est jamais déclenchée.

**Solution :** Vérifie que c'est bien à missingOKs que je pensais, et corrige.

### O4. Sondes et échos sur arbre : l'écho est envoyé à `parent = nil` chez la source
`5-1-sondes-echos / S6.6`

```
Réception d'un écho e de i
    Ajouter e à echos_reçus
    Si parent est nil et echos_reçus a la taille de voisins
        echo := agrégerEchos(echos_reçus)
        Terminer le sondage avec echo
    Si echos_reçus a la taille de voisins - 1        ← pas de Sinon, pas de garde sur parent
        echo := agrégerEchos(echos_reçus)
        Envoyer echo à parent
```
Les deux `Si` sont indépendants. Chez la source (`parent = nil`, k voisins), le second se
déclenche dès `k-1` échos reçus et tente d'envoyer un écho à `parent = nil`. La version graphe
(`S8.5`) et la version multi-sources (`S10.6`) ont, elles, la bonne structure
`Si parent est nil … Sinon …` — c'est donc bien un oubli dans la version arbre.

**Solution :** Vérifie quelle serait le fix, propose-le moi, et si c'est ok et que tu confirmes que ça corrige bien le problème, applique-le.

### O5. Sondes et échos sur graphe : la source n'est jamais marquée « sondée »
`5-1-sondes-echos / S8.3` vs `S8.4`

`Demande d'envoi d'une sonde s` ne met jamais `sonde_reçue = true`. Quand la sonde revient à la
source par un cycle, le handler `Réception d'une sonde` prend donc la branche `Sinon` : la source
se donne un `parent`, réinitialise `echos_reçus` et `echos_attendus`, et perd son état de source.
La version multi-sources échappe au problème par construction (`sonde_reçue` y est remplacé par
la présence de la clé dans `echos_attendus`, laquelle est bien posée par `Demande d'envoi`).

**Solution :** idem

### O6. Raft : le quorum annoncé n'est pas une majorité
`7-1-consensus-raft / S3.4`

« J'attends le ACK d'au moins ⎡N/2⎤+1 voisins ». Pour N=5 cela fait 4 ACK, alors que la majorité
est 3 (le leader compris, donc 2 ACK de followers). La formule est fausse quel que soit le
décompte retenu, et elle contredit `S2.2` / `S7.2` qui posent correctement la borne à
⎡N/2⎤-1 pannes tolérées. À trancher aussi : « voisins » (hors soi) ou « processus » (soi inclus) —
le deck mélange les deux.

**Solution :** Vérifie la valeur officielle de Raft. si c'est bien -1, alors mets -1.

### O7. Cannon : l'initialisation de `Bkj` lit la matrice A
`6-battements / S10.3`

« Avec initialement, `Aik = A[i][(i+j)%n]`, `Bkj = A[(i+j)%n][j]`, `Cij = 0` ».
Le second doit être `B[(i+j)%n][j]`.

**Solution :** Oula oui, fix ça.

### O8. Lamport : la complexité en messages n'est pas sur la même base que les suivantes
`2-2-mutex-lamport / S5.2`, `3-1-jetons-multiples-mutex / S4.2` et `S9.3`, `3-2 / S8.2`

Le deck Lamport annonce « Communication **par SC** : 3n(n-1) ». Le coût réel d'une entrée en SC
est 3(n-1) (un REQ, un ACK et un REL par pair). 3n(n-1) correspondrait à n processus demandant
chacun la SC. Comme Ricart & Agrawala est annoncé à « 2(n-1) messages **par processus souhaitant
entrer en SC** » et Carvalho & Roucairol à « entre 0 et 2(n-1) », la progression
3(n-1) → 2(n-1) → [0, 2(n-1)] → 2log(n) est illisible : telle qu'écrite, elle donne l'impression
d'un gain d'un facteur n entre Lamport et Ricart & Agrawala. Il faut une base de comparaison
unique et explicite pour les quatre algorithmes.

**Solution :** Agreed. Disons que c'est "par processus souhaitant entrer en SC". Vérifie que ça s'applique bien partout (certains dépendent peut-être trop du fait que tous veuillent entrer, jsp), et ensuite on valide et on corrige.

### O9. Deck Go : plusieurs extraits ne compilent pas
`1-go`

Erreurs de compilation dans du code que les étudiant·e·s vont copier au labo 0/1 :

| Réf. | Problème |
|---|---|
| `S4.9` | `pakage util` → `package util` |
| `S7.3` | `_, _ := swap("Hello","world!")` → *no new variables on left side of :=* |
| `S8.9` (Java) | `runAll(Task[] task)` puis `count += tasks.length` — paramètre nommé `task`, corps utilisant `tasks` |
| `S11.8` | `<msg>, ok := <channel>` — l'opérateur de réception `<-` manque |
| `S11.12` et `S11.13` | `for _, _ := range queries` → même erreur que `S7.3` ; s'écrit `for range queries` |
| `S11.13` | `func makeQueriesTimeout(queries [string])` → `[]string` |
| `S11.13` | `go func() { c <- makeQuery(q) }` — les `()` d'appel manquent ; l'expression est de plus inutilisée |
| `S11.16` | `cas req := <-getUser:` → `case` |
| `S12.5` et `S12.6` | `defer conn.Close()` dans `main` alors que la variable s'appelle `listener` ; `conn` n'existe pas à cette portée |

**Solution :** Aïe, prends effectivement le temps de tout tester, et vérifier que ça fait ce que c'est sensé. Propose ensuite des corrections et je validerai. si tu vois des manières plus simples/conventionnelles de faire la même chose, n'hésite pas ; ce code vient d'une ancienne version du cours et je n'exclue pas la possibilité que ce soit inutilement compliqué.

### O10. Deck Go : le compteur de l'exemple « composition » ne compte rien
`1-go / S8.10` et `S8.14`

`func (r CountingRunner) Run(t Task) { r.count++ ; r.runner.Run(t) }` utilise un récepteur
**par valeur** : `r.count++` incrémente une copie et est perdu. Or c'est précisément la slide qui
conclut « comptera chaque tâche une seule fois » — le résultat observé serait 0. Il faut
`func (r *CountingRunner) …`. Dans le même exemple, `S8.14` écrit
`return r.runner.Name()` alors que la méthode définie sur `Runner` s'appelle `GetName()`.

**Solution :** Vérifie ça et suggères un fix.

### O11. Deck Go : `make([]byte, 3, 5)` décrit à l'envers
`1-go / S5.7`

« Crée un tableau de zéros de taille 5, et crée un slice de **capacité 3** dessus ». C'est la
*longueur* qui vaut 3 et la *capacité* 5 — le schéma de la même slide (Taille 3, Capacité 5) dit
d'ailleurs le contraire du texte.

**Solution :** yes, corrige ça.

### O12. Consensus : les suppositions de Paxos/Raft sont fausses et contredisent le deck suivant
`7-consensus / S11.5`

« Jusqu'à N/2 pannes récupérables » (il faut *strictement moins* que N/2, cf. ⎡N/2⎤-1 annoncé en
`7-1-consensus-raft / S2.2`) et « Système partiellement **asynchrone** » (le terme utilisé partout
ailleurs dans le cours, et le terme standard, est *partiellement synchrone* — c'est aussi ce que
dit `S3.3` de ce même deck).

**Solution :** oui fais ces corrections.

---

## P2 — Incohérences conceptuelles et de modèle

### O13. Le modèle de réseau/système change de deck en deck, sans page de référence
Transversal

Récapitulatif de ce qui est supposé, deck par deck :

| Deck | Pertes | Pannes | Synchronie |
|---|---|---|---|
| `0-intro / S13.3` | aucune | — | non dit |
| `0-1-pannes / S3.3` | aucune | permanentes | **synchrone** (borne T connue) |
| `0-1-pannes / S4.3` | aucune | perm. + récupérables | **partiellement synchrone** (T inconnue) |
| `3-2 / S2.2` | aucune | aucune | non dit |
| `4-0 (Bully) / S3.2` | aucune | aucune | **synchrone** |
| `4-2 (C&R) / S2` | aucune | aucune | **asynchrone** |
| `4-3 (C&R+pannes) / S3.4` | aucune | récupérables | **synchrone** |
| `5-1`, `5-2`, `6` | non dit | non dit | non dit |
| `7-consensus / S3.2` | aucune | permanentes | **synchrone** |
| `7-1 (Raft) / S2.2` | **possibles** | récupérables sans amnésie | partiellement synchrone |

Le modèle fait donc synchrone → asynchrone → synchrone → … sans qu'aucune slide ne récapitule
l'évolution. Trois decks (`5-1`, `5-2`, `6-battements`) n'énoncent aucune supposition du tout.

**Solution :** fais un double-check là-dessus. parce que par exemple 4-3 il me semble qu'on accepte les pertes, non ? Même chose dans d'autres (gener consensus). et 4-2 utilise vraiment asynchrone ? pour 0-1-pannes c'est ok pour moi qu'on touche à toutes les suppositions, c'est justement le but d'être exhaustif. pour 5-1, 5-2, 6, let's look into it, and clarify what assumptions are made. Ça sera probablement pas un petit morceau, soyons conscients de ça et abordons-le comme tel.

### O14. « Système synchrone » vs « algorithme synchrone » : collision de vocabulaire
`5-2-synchronisation / S2.2`, `7-consensus / S3.2`, `0-1-pannes / S3.3`, `4-0 / S3.2`

Le cours utilise « synchrone » pour deux notions orthogonales : le *système* (borne sur le délai
de transit) et l'*algorithme* (progression par battements). Le problème est identifié par une
parenthèse dans `5-2 / S2.2` (« Attention : rien à voir avec un système sychrone ») et une autre
dans `7-consensus / S3.2` (« À ne pas confondre avec un algorithme synchrone »), mais uniquement
en aparté, et jamais au moment où le terme est introduit pour la première fois (`0-1-pannes`).

**Solution :** est-ce qu'on pourrait ne plus parler d'algorithme synchrone du tout ? Remplacer par "par battement" ou "synchronisé" à la limite ? Je demande surtout si la littérature utilise ces mots aussi ou non.

### O15. Élection : « Sûreté » et « Résilience » se contredisent
`4-0-diffusion-elections-bully / S2.2`

Les propriétés souhaitées listent « Sureté : un seul processus ne peut être élu » puis
« Résilience : … Si le réseau est scindé en deux, un élu doit exister par partition ». Les deux
sont incompatibles telles quelles. C'est en plus exactement le split-brain que Raft interdit
plus tard (`7-1 / S7.2`, « Un seul leader à la fois »), sans que le lien soit fait.
Accessoirement, la formulation « un seul processus ne peut être élu » se lit spontanément comme
« un processus ne peut pas être élu » ; « au plus un processus est élu » lèverait l'ambiguïté.

**Solution :** Quelles sont les propriétés officielles dans la littérature, alors ?

### O16. Le deck « Bully » ne présente pas l'algorithme du Bully
`4-0-diffusion-elections-bully`, et l'entrée « Algorithme du Bully » dans `index.html`

L'algorithme présenté est : chacun diffuse son aptitude, attend 2T, prend le maximum. L'algorithme
du Bully (Garcia-Molina 1982) est un protocole `election` / `answer` / `coordinator` dans lequel
un processus n'interroge que les processus d'ID supérieur. Le deck se sous-titre lui-même
« a.k.a. un algorithme naïf », ce qui suggère que le nom est un raccourci — mais il est repris tel
quel dans le titre du deck, dans le planning et dans le nom du dossier. Deux options : renommer
(« élection par diffusion complète »), ou présenter le vrai Bully. À noter que le Bully ne figure
pas dans la fiche d'unité (voir O25).

**Solution :** Le vrai algorithme de bully, comment fonctionne-t-il plus précisément ? est-il complexe ? s'il l'est, alors on ne veut pas le présenter ici; le but ici est simplement de donner une version naïve pour bien comprendre ce que c'est qu'on veut faire.

### O17. Bully, version à deux routines : `apt_self` est déclarée constante puis modifiée
`4-0-diffusion-elections-bully / S6.4` vs `S6.5`

`apt_self` est déclarée « entier, **constant**, mon aptitude », et le handler suivant fait
`apt_self ← new_apt`. Par ailleurs la version à deux routines abandonne silencieusement la
logique `inElection` / `isReqPending` de la version à une routine (`S5.5`, `S5.6`) : l'énoncé
« Si une élection est en cours quand une nouvelle est demandée, elle est différée à la fin de
celle en cours » (`S4.3`) n'a plus de traduction dans le pseudocode final.

**Solution :** disons que apt-self n'est jamais modifié dans le pseudocode, mais on peut garder une mention du fait qu'on pourrait autoriser sa modification mais la repousser si en-cours-d'élection. Un peu comme une chose qui serait la responsabilité de l'utilisateur de la couche élection, ou bien un petit add-on à l'algorithme qui ne nous intéresse pas. est-ce que ça casserait quelque chose à la définition qu'on donne de l'élection ?

### O18. Chang & Roberts : « le demandeur réessaiera plus tard » n'est implémenté nulle part
`4-2-diffusion-elections-cr / S5.2` et `S6.4` ; `4-3 / S6.4`

Le résumé annonce « Je refuse la demande *(le demandeur réessaiera plus tard)* » et le pseudocode
se contente de `Si inElection → Refuser la demande`. Aucun mécanisme de réessai n'est décrit, alors
que le deck Bully, lui, en avait un explicite (`isReqPending`). L'exercice de `4-0 / S8.2` suppose
d'ailleurs le réessai (« Si une demande d'élection est rejetée, le processus réessaie une fois
l'élection courante terminée »).

**Solution : **Oui, c'est normal. c'set la responsabilité du demandeur.

### O19. Chang & Roberts avec pannes : la liste des événements n'a pas été mise à jour
`4-3-diffusion-elections-cr-pannes2 / S6.3` vs `S6.5`, `S6.6`

La slide « Initialisation » annonce encore `Réception d'une annonce {i, apt_i}` et
`Réception d'un résultat {i}` — les signatures de la version *sans* pannes. Les handlers effectifs
prennent une liste de participants et un couple `{new_élu, accepted}`. Le tableau des variables
(`S6.2`) ne déclare pas non plus ces listes.

**Solution :** Corrige ça, effectivement. Pour ce qui est de la liste des participants et un couple, n'est-ce pas le contenu du message, et non une variable ? N'allons pas créer de variables qui n'en sont volontairement pas.

### O20. Chang & Roberts : « 3N messages par élection » à vérifier
`4-2-diffusion-elections-cr / S5.3`

Tel que décrit (un tour d'annonce + un tour de résultat sur l'anneau), le coût est 2N messages.
D'où vient le troisième N ? Par ailleurs `O(3NT)` s'écrit `O(NT)` — la constante n'a pas sa place
dans un grand-O, et le deck utilise ailleurs la notation correctement.

**Solution :** On suppose que T est une inconnue, donc ok dans le grand-O. Et pourquoi 3N, parce que le tour d'annonce ne s'arrête pas forcément dès qu'il rencontre le premier, mais potentiellement lorsqu'il rencontre le dernier pour la deuxième fois. right?

### O21. L'interface « sondes et échos » promet un retour que le pseudocode ignore
`5-1-sondes-echos / S5.5` vs `S6.5`, `S8.4`, `S10.5`

L'interface annonce « Notification de réception de sonde — **Peut retourner une nouvelle sonde à
propager** ». Les trois pseudocodes appellent `receptionSonde()` en ignorant sa valeur de retour et
propagent `s` inchangé. (Au passage : `receptionSonde()` sans argument dans les versions arbre et
graphe, `receptionSonde(s, s_id)` dans la version multi-sources.)

**Solution :** Rendons tout ça cohérent. utilisons la valeur retournée, et assurons-nous que les arguments soient cohérents.

### O22. Sondes et échos multi-sources : `s_id` est retiré de `echos_attendus` mais pas d'ailleurs
`5-1-sondes-echos / S10.6`

`Enlever s_id de echos_attendus` laisse les entrées correspondantes dans `echos_reçus` et `parent`
(fuite mémoire), et surtout : puisque `sonde_reçue` est encodé par la présence de la clé dans
`echos_attendus` (`S10.3`), une sonde retardataire portant le même `s_id` sera traitée comme une
sonde neuve après la fin du sondage. Dans le même handler, `Envoyer echo avec s_id à parent`
devrait lire `parent[s_id]`.

**Solution :** la remarque que tu fais sur la sonde retardataire, indique-t-elle qu'il faudrait simplement ne jamais rien supprimer ? Si oui, alors on ne supprime rien. Ou alors on stocke un genre de "last id" pour stocker l'id le plus élevé dont on a fini le traitement, ou qqch comme ça. Et à l'inverse, si on peut supprimer s_id de echos_attendus, alors supprimons-le de toutes les maps, effectivement. pour parent[s_id], agreed.

### O23. Raft : la notion de mandat (*term*) est utilisée sans avoir été définie
`7-1-consensus-raft / S4.9`

« si c'est la première candidature valide pour ce **mandat** » est la seule occurrence du concept,
et il n'est défini nulle part. Or le mandat est la brique centrale de Raft : c'est lui qui rend
la comparaison de logs (`S4.3`) et le rejet des messages périmés bien définis. Le deck compare
les logs par « committed le plus récent, puis pending le plus récent » — Raft compare
`(dernier terme, dernier index)`. La simplification est signalée par une astérisque en `S4.4`
(« un peu plus compliqué que ça en cas de gros ralentissements du réseau ») mais son coût n'est
pas explicité.

**Solution :** À quel point est-ce que ça compliquerait les choses d'introduire correctement ce terme de mandat ?

---

## P3 — Structure du cours et couverture

### O24. La diffusion fiable (*reliable broadcast*) n'est enseignée nulle part — et le labo 1 la demande

C'est le point soulevé dans la demande, et il est confirmé par la lecture.

- Le seul endroit où le mécanisme apparaît est une remarque de fin de section, dans le dernier
  deck théorique : `7-consensus / S9.5` — « L'approche utilisée ici, "À la réception d'un
  broadcast, je broadcast à mon tour", n'est pas spécifique au consensus. Elle permet un broadcast
  sûr dans tout contexte de broadcast. » Soit une slide, en semaine 14, sans nom, sans propriétés,
  sans pseudocode, sans exercice.
- Or le labo 1 (semaines 2–4) demande explicitement d'obtenir « l'absence de perte de messages et
  la réception d'un accusé de réception pour chaque message envoyé, ainsi que l'absence de
  duplication et de réordonnancement », sur un envoi qui est un **broadcast** (« un serveur attend
  qu'un message soit entré sur la ligne de commande pour l'envoyer à tous ses voisins »).
- Le cours donne R / RR / RR+id / RRA, tous **point à point**. Le passage du point-à-point au
  broadcast (diffusion best-effort, puis fiable, puis les propriétés validité / intégrité /
  accord) n'est jamais fait.
- Sous-point important : **aucune des slides RR* n'explique comment garantir le non-réordonnancement**,
  alors que c'est une exigence explicite du labo 1. RRA avec une seule requête en vol par
  destinataire le donne implicitement, mais ce n'est écrit nulle part.

Emplacement naturel : dans `0-intro`, juste après `S17` (RRA) et avant l'exercice `S18` — ou dans
un nouveau deck `0-2-diffusion-fiable`, ce qui permettrait aussi de déplacer les protocoles RR*
hors du deck d'introduction (voir O26).

**Solution :** Est-ce que les slides RR* corrigent effectivement le réordonnancement, ou non ? si oui, il faudra effectivement le noter. Pour ce qui est de broadcaster, ajoutons-le effectivement à la suite de tous ces protocoles.

### O25. Écart entre le contenu enseigné et la fiche d'unité
`fiche_unite.md` vs les decks

Dans la fiche mais absents des slides :
- « communication par **RPC** » et « **adressage** » (chapitre Introduction, 4 h). Aucun deck ne
  les aborde.

Dans les slides mais absents de la fiche :
- Carvalho & Roucairol (`3-1`) — la fiche ne nomme que Lamport, Ricart & Agrawala et Raymond ;
- l'algorithme du Bully (`4-0`) — la fiche ne nomme que Chang & Roberts, avec et sans pannes ;
- Raft (`7-1`) — la fiche ne parle que d'« algorithme de consensus » et de machine d'état.

Labos : la fiche annonce mutex / élection / **synchronisation** / **consensus** (4 × 8 h). Les
labos effectifs sont RR / mutex / élection / sondes et échos. Deux des quatre thèmes ne
correspondent pas.

**Solution :** on va refaire les labos, donc c'est ok. ensuite, pour RPC on pourrait effectivement frame les slides RR* pour parler de ça. comment ferais-tu ça ? je ne suis pas très à l'aise avec RPC, et j'ai du mal à voir comment RPC pourrait être rendu pertinent pour le reste des slides. Est-ce qu'on pourrait en faire une genre de "boite noire" qu'on utiliserait dans des algos suivants dans le cours ? Et pour adressage, de quoi est-ce que tu penses que ça parle ? IP ?

### O26. Le deck d'introduction porte quatre sujets distincts
`0-intro` (18 slides)

`0-intro` contient : la logistique du cours (S3–S5), les définitions systèmes répartis /
parallélisme / Flynn / couplage (S8–S11), les propriétés d'un bon système réparti (S12), la
synchronicité des primitives réseau (S13) et **toute la théorie des classes de fiabilité
R / RR / RR+id / RRA** (S14–S18). Les protocoles de fiabilité sont le seul contenu du deck qui
soit examinable comme un algorithme, ils sont la matière directe du labo 1, et la fiche les range
sous « Fiabilité et reprise à la suite d'une panne » — c'est-à-dire avec `0-1-pannes`, pas avec
l'introduction. Le découpage actuel les rend difficiles à retrouver.

**Solution :** Je proposerais effectivement de sortir les classes de fiabilité, voire même, effectivement, dans le même deck que gestion des pannes.

### O27. Le sommaire du cours ne correspond pas au plan du site
`0-intro / S6` vs `index.html`

Le « Programme » liste 8 entrées numérotées 0–7 (Introduction, Golang, Estampilles, Jetons,
Diffusion, Sondes et échos, Synchronisation et battements, Consensus). Le site n'affiche que 5
chapitres (Ch.1 Estampilles, Ch.2 Jetons, Ch.3 Diffusion, Ch.4 Sondes et Échos, Ch.5 Consensus) :
Introduction, Golang et « Synchronisation et battements » n'y ont pas de chapitre. Rien ne permet
à un·e étudiant·e de situer le cours du 09.12 ou du 16.12 dans le programme annoncé en semaine 1.

**Solution :** ok. j'y ferai attention durant le semestre ; ingorons pour l'instant.

### O28. Quatre decks n'ont pas de pseudocode, alors que c'est le format standard du cours
Transversal

Tous les decks algorithmiques suivent le même gabarit : idée → exemple → résumé → **tableau de
variables + pseudocode** → propriétés/complexité → exercice + corrigé. Font exception :

| Deck | Variables + pseudocode | Propriétés/complexité | Exercice + corrigé |
|---|---|---|---|
| `0-1-pannes` (détecteurs) | absent | propriétés seules | **absent** |
| `5-1-sondes-echos` | présent | **absent** | présent |
| `5-2-synchronisation` (α, β) | **absent** | présent | présent |
| `6-battements` | présent | présent (mais cf. O31) | présent |
| `7-consensus` | **absent** | tolérance seule | présent |
| `7-1-consensus-raft` | **absent** | propriétés seules | **absent** |

Le contraste est net pour Raft, qui est le dernier cours avant le TE3 et le seul deck sans
pseudocode **ni** exercice.

**Solution :** Tu ajouteras une/des slides là où c'est manquant pour ça. Tu peux proposer du contenu si tu le veux. tu me demanderas si tu peux commencer sur cet item avant de te lancer.

### O29. Les sondes et échos n'ont aucune analyse de complexité
`5-1-sondes-echos`

Aucune slide « Propriétés », « Complexité » ou « Performances » dans tout le deck, alors que c'est
le seul paradigme du cours dans ce cas, et que la comparaison α (O(E) messages, O(T) latence) vs
β (O(V) messages, O(TV) latence) du deck suivant repose sur le même schéma d'arbre.

**Solution :** mentionné dans O28 : tu ajouteras ça, oui.

### O30. `4-3` (Chang & Roberts avec pannes) n'a ni complexité ni performance
`4-3-diffusion-elections-cr-pannes2`

Le deck ajoute un mainteneur d'anneau (ACK + timeouts + saut du suivant en panne) et remplace les
messages scalaires par des listes de participants. Le coût en messages et la taille des messages
changent donc substantiellement par rapport aux « 3N » de `4-2 / S5.3`, sans qu'aucune slide ne
le mentionne.

**Solution :** oui, on pourra ajouter ça aussi.

### O31. ~~Analyse de Cannon laissée en plan~~ — **FAUX POSITIF, classé**
`6-battements / S11.2` (index plat 35)

Constat initial : la case « Mémoire par processus » semblait sans réponse.

**Invalidé par le rendu** (`npm run render -- 6-battements 35 --steps`, état `f3`) : la réponse
« Constante » est bien présente, en fragment. Mon extracteur de texte l'avait supprimée parce qu'il
déduplique les chaînes identiques d'une même slide, et « Constante » figurait déjà juste au-dessus
pour « Taille d'un message ». Rien à corriger.

Leçon générale : les constats d'*absence* tirés de l'extraction textuelle sont les moins fiables.
Ceux du présent document qui portent sur du texte **présent et fautif** ont tous été revérifiés
dans le HTML source.

### O32. Le calendrier des labos annoncé en cours ne correspond pas aux donnés
`0-intro / S4.3` vs `labos/1-request-reply.md`

La slide annonce une pondération « Phase de conception (25%) / Phase de mise en œuvre (75%) » et,
en séance 2, une « proposition d'architecture **fournie** » sur laquelle s'appuyer. La donnée du
labo 1 ne mentionne ni la pondération, ni l'architecture fournie : elle dit « la deuxième séance
de labo sera votre dernière occasion de valider auprès de nous votre proposition de solution ».
De même, `S4.1` annonce « généralement 4 semaines par labo » quand la donnée précise « excepté le
labo 1, qui en durera trois ».

**Solution :** on va le refaire sur la base des réflexions qu'on a faites sur le nouveau format des labos.

### O33. Le modèle réseau de l'introduction est présenté à la fois comme hypothèse et comme résultat
`0-intro / S13.3` → `S14`–`S17`

`S13.3` pose « Garanties du réseau / Ce que nous supposerons dans ce cours : pas de perte, pas de
duplication, pas de changement d'ordre », puis conclut la même slide par
« → Différents protocoles de fiabilité ». Les slides suivantes construisent précisément ces
garanties. Une même page présente donc les trois propriétés comme une hypothèse *et* comme
l'objectif des protocoles qui suivent. C'est la confusion que le labo 1 doit lever (les
étudiant·e·s doivent *implémenter* ces garanties par-dessus UDP) — voir aussi O24.

**Solution :** je pense que le but de cette slide est de dire "dans ce cours, on va vouloir pouvoir supposer ça. aujourd'hui, on va voir comment on peut y arriver". makes sense ?

### O34. Panne d'omission et panne byzantine présentées dans le désordre
`0-1-pannes / S2.4` puis `S2.5`

La panne arbitraire (« le type de panne le plus coûteux à supporter ») est présentée avant la
panne d'omission, rangée dans un « and more… » de fin de slide avec l'eavesdropping. Une
présentation par force croissante — permanente → récupérable → omission → arbitraire — donnerait
la hiérarchie d'inclusion, qui est le point utile. L'eavesdropping n'est d'ailleurs pas une panne
au même sens (pas d'écart au protocole) et mériterait d'être séparé.

**Solution :** c'est pour ça que eavesdropping était mise à part. Pour omission, est-ce qu'on parle simplement de perte de message au final ? Auquel cas, est-ce que ça mérite vraiment d'être dans ces slides ? et est-ce que c'est effectivement pire qu'une panne permanente ?

---

## P4 — Nommage, orthographe, hygiène du dépôt

### O35. Fautes de frappe confirmées

| Deck | Ref. | Écrit | Attendu |
|---|---|---|---|
| `1-go` | S3.2 | Robert **Gresemer** | Robert Griesemer |
| `1-go` | S11 (titre) | **Concurence** | Concurrence |
| `1-go` | S8.2 | **farenheit**, `ebulitionC` / `ebuilitonF` | fahrenheit ; noms de variables cohérents |
| `1-go` | S4.3, S5.3 | **Optionel** | Optionnel |
| `1-go` | S5.7 | **longeur** | longueur |
| `1-go` | S7.3, S7.4 | **existente(s)** | existante(s) |
| `1-go` | S5.3 | **succinte** | succincte |
| `7-consensus` | S11.5 | John **Ousterhou** | John Ousterhout |
| `7-consensus` | S3.2 | **réordonancement** | réordonnancement (orthographié correctement dans `7-1`) |
| `0-1-pannes` | S3.3, S4.3 | **réordonancement** | réordonnancement |
| `3-2` | S2.4 (titre) | Carvalho et **Ricairol** | Roucairol (correct en S2.5) |
| `3-2` | S2.5 | délai de **transite** | de transit |
| `3-1` | S10.5 | **S**elfRequestTs | selfRequestTs |
| `4-0` | S7.2 | le même élu sera à nouveau **choisit** | choisi |
| `4-3` | S3 (titre) | **Maintient** de l'anneau | Maintien |
| `4-3` | S7.5 | gestion **grâcieuse** | gracieuse |
| `5-1` | S3.3 | **Sychronisation** de processus | Synchronisation |
| `5-1` | S3.2 | **Invariante** ; « dans l'**autres** sens » | Invariant ; l'autre sens |
| `5-2` | S2.2 | un système **sychrone** | synchrone |
| `7-1` | S7.2 | un log n'est **commited** | committed (orthographe correcte ailleurs) |
| `7-1` | S7.3 | si deux processus **on** un même log | ont |
| `7-1` | S4.9 | candidat **au** prochaines élections | aux |
| `0-intro` | S11.7 | couplage à tendence forte | tendance |
| `0-intro` | S4.3 | document d'**achitecture** | architecture |
| `0-intro` | S13.3 | reçu **q'une** fois | qu'une |
| `2-1` | S4.6, S4.7 | ordre total **stricte** | strict |
| `2-1` | S4.4 | on avait **définit** | défini |

Également, orthographe flottante à l'intérieur d'un même deck : `echo`/`écho` et `echos`/`échos`
(`5-1` partout), `status`/`statuts` (`5-2 / S7.2` vs `S4.2`), `connection` (anglicisme, `1-go / S11.10`,
`5-2 / S6.5`).

**Solution :** oui, toutes fautes de frappe ou orthographe peuvent être corrigées.

### O36. Les titres des decks ne correspondent pas aux entrées du planning
`index.html` vs page de titre de chaque deck

| Planning | Titre de la slide 1 |
|---|---|
| Algorithme du Bully | « Diffusion — Élections - Introduction » |
| Mutex par jetons | « Jetons — Mutex optimisées » |
| Synchronisation | « Sondes et échos — Synchronisation » |
| Algorithmes synchronisés | « Battements » |
| Consensus naïf | « Consensus » |

**Solution :** on pourra effectivement faire ça.

### O37. La numérotation des dossiers a dérivé de celle des exports slides.com

Chaque dossier de deck contient un sous-dossier portant le nom d'origine de la présentation, et
ces noms ne correspondent plus :

| Dossier | Sous-dossier |
|---|---|
| `3-2-mutex-jeton-unique/` | `sdr-4-jetons-1-mutex/` |
| `4-0-diffusion-elections-bully/` | `sdr-4-0-diffusion-elections/` |
| `4-2-diffusion-elections-cr/` | `sdr-4-1-elections-sans-pannes/` |
| `4-3-diffusion-elections-cr-pannes2/` | `sdr-4-1-diffusion-elections/` |
| `5-1-sondes-echos/` | `sdr-4-2-diffusion-elections-avec-pannes/` |
| `6-battements/` | `sdr-5-2-sondes-et-echos-synchronisation/` |
| `7-consensus/` | `sdr-6-1-detecteurs-de-panne/` |

Le suffixe `2` de `4-3-…-cr-pannes2` trahit le même historique. Conséquence pratique : impossible
de savoir de quel deck slides.com provient un dossier, donc lequel rééditer.

**Solution :** ça aussi oui.

### O38. Fichiers morts dans `slides/`

- Dossiers vides (que le `lib/`, pas d'`index.html`) : `4-1-diffusion-elections-bully/`,
  `4-3-diffusion-elections-cr-pannes/`.
- Huit exports HTML d'une édition précédente, à la racine de `slides/`, non liés depuis
  `index.html` : `3.4-mutex-jeton-unique.html`, `4-elections.html`, `4.2-elections-pannes.html`,
  `5.1-synchronizers.html`, `5.2-ondulation.html`, `5.3-sondes-echos.html`,
  `6.1-detecteurs-de-panne.html`, `6.2-consensus.html` (≈ 19 Mo au total). Certains couvrent des
  sujets qui n'existent plus dans le cours actuel (`5.2-ondulation`).
- Deux PDF de corrigés aux noms quasi identiques et rattachés à des semaines différentes :
  `5-2-synchronisation-solutions.pdf` (semaine 12) et
  `5-2-sondes-et-echos-synchronisation-solutions.pdf` (semaine 13, deck `6-battements`).

Aucun lien cassé dans `index.html` en revanche — vérifié.

**Solution :** on peut supprimer les exports de l'édition précédente. Idem pour les solutions.

### O39. Deck Go : références documentaires périmées
`1-go / S4.2`

Le deck renvoie à `golang.org` et à une arborescence « Documents > Learning Go > … », qui n'existe
plus : le site est `go.dev` et la navigation a changé. Le planning, lui, pointe déjà correctement
vers `go.dev/tour/welcome/1`. Dans la même veine, `S4.3` présente `go.mod` comme
« Optionel s'il n'y a qu'un package », ce qui n'est plus vrai depuis le passage aux modules.

**Solution :** Fixe les références.

### O40. Deck Go : conseil de concurrence discutable
`1-go / S11.17`

« Il ne faut qu'un récepteur par channel. (Sinon, lequel lira en premier sera imprévisible) » —
plusieurs récepteurs sur un même channel est un idiome standard (pool de workers), et
l'imprévisibilité de qui reçoit est en général le comportement voulu. La donnée du labo 1 reprend
d'ailleurs la règle telle quelle (« Comme il se doit, celles-ci ne sont lues que par une seule
goroutine »). Si c'est une contrainte pédagogique volontaire, il vaudrait mieux la présenter comme
telle plutôt que comme une propriété du langage.

**Solution :** on peut peut-être, oui, dire que cette règle ne tient pas lorsque l'objectif est de dispatcher arbitrairement. on serait d'accord là dessus ? ou même là ça resterait discutable ?

### O41. Deck Go : la capture de variable de boucle dépend de la version de Go
`1-go / S11.12`, `S11.13`

`for _, q := range queries { go func() { c <- makeQuery(q) }() }` capture `q`. Depuis Go 1.22 la
variable de boucle est par itération et l'exemple est correct ; avant, c'était le bug de capture
classique. Comme rien n'indique la version de Go visée par le cours, l'exemple est ambigu —
et c'est précisément un piège que les étudiant·e·s vont rencontrer au labo.

**Solution :** on va viser la version la plus récente. on peut noter sur cette slide quelque part en bas que ce n'était pas le cas auparavent.

### O42. Détecteur « parfait un jour » : Δ ne décroît jamais
`0-1-pannes / S4.4`

Le timeout dynamique est incrémenté à chaque suspicion et n'est jamais réduit. C'est suffisant
pour la précision-un-jour (et la slide le démontre correctement), mais un réseau qui redevient
rapide après un pic garde un détecteur arbitrairement lent. Cela mérite au moins une remarque,
d'autant que Raft (`7-1 / S4.7`) réintroduit plus tard des timeouts, aléatoires cette fois, sans
que le lien soit fait.

**Solution :** oui, on peut ajouter la remarque.

### O43. Le corrigé de l'exercice « découverte de topologie » a des notations flottantes
`6-battements / S8.3`

Le même voisinage est noté `D:CE` dans la colonne A et `D:EC` dans les colonnes B/C/D/E, et
`B:AC` devient `B:CA` en dernière ligne. Rien de faux (ce sont des ensembles), mais dans un
corrigé que les étudiant·e·s comparent case par case, cela crée du doute inutile.

**Solution :** ok, corriges pour que ce soit cohérent (e.g. ordre alphabétique d'affichage du set)

### O44. ~~Corrigé de Cannon non vérifié~~ — **VÉRIFIÉ CORRECT, classé**
`6-battements / S12.3`

La matrice de l'énoncé n'était lisible que dans l'image ; le rendu de `S12.2` donne
`A = [[2,1,0],[0,1,2],[3,0,1]]` et `B = [[3,1,0],[0,2,1],[0,3,2]]`.

Les trois battements rejoués avec l'alignement initial du deck : les neuf tableaux du corrigé
(A, B et C à la fin de chaque battement) sont **exacts sans exception**, et le C final
`[[6,4,1],[0,8,5],[9,6,2]]` est bien le produit A·B.

Retombée sur [[O7]] : ce recalcul ne tombe juste qu'avec `Bkj = B[(i+j)%n][j]`. Le corrigé est donc
bâti sur la formule correcte, ce qui confirme que le `A[...]` de `S10.3` est une **coquille isolée
dans le pseudocode**, sans propagation dans le reste du deck.

### O46. Le synchroniseur alpha repose sur une hypothèse FIFO jamais énoncée
`5-2-synchronisation / S4.2`, à rapprocher de `S7.2` et de [[O45]]

`S4.2` affirme : « Besoin d'un numéro de battement sur les messages ? **Non !** Si j'ai reçu un prêt
d'un voisin, je sais que ses prochains messages sont du battement suivant. »

L'inférence n'est valide que si les messages d'un même lien arrivent **dans l'ordre d'émission**.
Sans FIFO par lien, un message du battement k émis avant le « prêt » peut arriver après lui et être
rangé dans le battement k+1. L'affirmation « pas besoin d'id » n'est donc pas gratuite : elle est
payée par une hypothèse FIFO que le cours n'énonce nulle part (cf. O13 — `5-2` n'a aucun bloc de
suppositions).

C'est aussi ce qui donne l'explication propre du contraste avec beta : beta ne peut pas faire cette
inférence, parce que `S6.5` autorise explicitement les messages de l'algorithme synchronisé à
circuler sur des liens **hors arbre**, sur lesquels aucun « prêt » n'est échangé. D'où la nécessité
d'un id de battement porté par le message.

**Solution :** énoncer l'hypothèse FIFO dans les suppositions de `5-2`, et remplacer l'assertion de
`S4.2` par l'argument (« parce que les liens sont FIFO ») — ce qui rend du même coup lisible
pourquoi beta a besoin d'ids.

---

## Annexe — points vérifiés et corrects

Notés pour éviter de les re-litiger :

- Aucun lien local cassé dans `sdr-classroom.github.io/index.html`.
- `2-1-horloges / S5.3` : l'ordre total strict de l'exercice 1 est cohérent.
- `1-go / S5.6` : la question sur les slices (`Reliu`) et son explication sont justes.
- `6-battements / S6.3` : la diffusion finale a bien lieu avant le test d'arrêt, comme le corrigé
  de `S8.3` le souligne.
- `4-0 / S4.6` : le « jusqu'à 4T » se décompose correctement (1T + 2T + 1T).
- `5-1 / S8` : le comptage des sondes croisées sur un cycle est correct (chaque nœud émet sur tous
  ses liens sauf celui du parent, donc les décréments sont symétriques).
- `7-consensus / S10.3` : tolérer jusqu'à N-1 pannes est bien correct sous détecteur parfait.
- `7-1 / S2.2` : ⎡N/2⎤-1 est la bonne borne de pannes (contrairement à O6 et O12).
