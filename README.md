# Diva

**Un bureau Omarchy doux et cohérent, avec une assistante en français pour simplifier le quotidien.**

Diva réunit des thèmes, un menu, des contrôles du bureau et une petite compagne animée. Elle aide à retrouver une application, régler le son, organiser les fenêtres ou comprendre un problème, avec des mots simples.

**État actuel : prototype fonctionnel 0.13.0, en phase de finition.** Le projet a été essayé sur Omarchy 4.0.4, dans un compte de test. L'installation sur une machine neuve et l'utilisation sur le portable cible restent à valider. Ce document prépare le futur guide officiel ; il ne constitue pas une annonce de version stable.

- [Guide utilisateur](#guide-utilisateur) : installation, navigation, réglages et limites actuelles.
- [Développement et maintenance](#développement-et-maintenance) : architecture, règles, corrections prioritaires et validation.

## Guide utilisateur

### Installer Diva

L'installation doit être réalisée depuis la session graphique Omarchy de la personne qui utilisera Diva, **sans `sudo`**. Elle personnalise le thème, la barre, les raccourcis et certains réglages du bureau de ce compte.

Le système doit disposer d'Omarchy avec sa coquille active, Git, `jq`, `rsync`, Hyprland et Quickshell. L'installateur vérifie les dépendances principales et lance un aperçu QML avant d'appliquer les changements.

```sh
git clone https://github.com/tdemers218/Diva.git
cd Diva
bin/diva install
bin/diva status
```

Si Diva est déjà clonée, utiliser le dossier existant. Conserver ce dossier : il sert aux mises à jour et à la désinstallation.

Deux options permettent de limiter la personnalisation :

```sh
bin/diva install --no-theme  # Conserver le thème sélectionné
bin/diva install --no-look   # Ne pas appliquer les réglages visuels Hyprland
```

Ces options peuvent être combinées. Elles concernent l'installation ; elles ne désactivent pas l'ensemble des autres fonctions de Diva.

### Ouvrir Diva et lui demander quelque chose

Cliquer sur Diva dans la barre, ou appuyer puis relâcher **Super** seule, la touche généralement marquée Windows. Les combinaisons utilisant Super restent disponibles. Dans la configuration installée, `Super + Espace` n'ouvre plus le menu.

Écrire une demande dans le champ de recherche. Les accents et certaines fautes de frappe sont tolérés ; quelques lettres peuvent suffire pour retrouver une application. Les flèches permettent de choisir un résultat, Entrée de l'activer et Échap de quitter le menu ou la conversation.

| Besoin | Exemple |
| --- | --- |
| Ouvrir une application | « Ouvre Firefox » |
| Retrouver un dossier | « Où sont mes téléchargements ? » |
| Régler le son | « Mets le volume à 40 » |
| Régler l'écran | « Baisse la luminosité » |
| Retrouver une fenêtre | Le nom de l'application ou des mots de son titre |
| Organiser le bureau | « Mets deux fenêtres côte à côte » |
| Changer d'espace | « Va sur l'espace 3 » |
| Comprendre un geste | « Comment je ferme une fenêtre ? » |
| Programmer un rappel | « Rappelle-moi dans 10 minutes de sortir le gâteau » |
| Faire un calcul | `12 * 4` |
| Chercher sur Internet | « Cherche une recette de crêpes » |

Les commandes courantes, calculs et guides de raccourcis sont traités localement. L'assistante IA et les services en ligne nécessitent une connexion lorsqu'ils sont utilisés.

### Applications, fenêtres et espaces

Le dock dans la barre regroupe les applications favorites et ouvertes. Cliquer sur une icône lance l'application ou revient à sa fenêtre. Si elle possède plusieurs fenêtres, Diva propose une vue dédiée. Un clic droit permet d'épingler ou de retirer une application des favoris ; un dock trop long peut défiler.

Pour ouvrir la vue d'ensemble, utiliser son bouton dans le dock, maintenir le pointeur au bord supérieur pendant un quart de seconde, ou faire un geste vers le haut avec quatre doigts sur un pavé tactile compatible.

Dans cette vue :

- Cliquer sur une fenêtre pour la retrouver ; les flèches et Entrée fonctionnent aussi.
- Survoler un espace pour le regarder, puis cliquer pour y entrer.
- Glisser une fenêtre sur un espace pour la déplacer.
- Utiliser **+** pour préparer un espace supplémentaire.
- Fermer avec Échap ou un geste vers le bas avec quatre doigts.

Les gestes horizontaux à trois doigts font défiler le ruban de fenêtres. Les nouvelles fenêtres occupent une colonne pleine largeur ; Diva peut créer une disposition côte à côte à la demande.

Le déclenchement par le bord supérieur peut être désactivé dans **Réglages → Bureau**. Les gestes et le bouton du dock restent disponibles.

### Son, connexion et apparence

La page d'accueil rassemble les commandes de volume, luminosité, Wi-Fi, Bluetooth et verrouillage. **Son**, **Fond**, ainsi que les libellés Wi-Fi et Bluetooth ouvrent leurs pages dans Diva.

Ces pages permettent de choisir un réseau, connecter un appareil Bluetooth, sélectionner une sortie ou une entrée audio, régler le volume des applications et choisir un fond d'écran. La création d'un nouveau profil Wi-Fi d'entreprise reste du ressort des outils d'administration ; les profils déjà enregistrés restent utilisables.

Les réglages proposent six thèmes :

| Thème | Ambiance |
| --- | --- |
| Prune | Prune sombre et rose doux |
| Lavande | Indigo et lavande |
| Menthe | Bleu-vert et accents menthe |
| Pêche | Cacao et pêche |
| Crème | Fond clair et crème chaud |
| Minuit | Presque noir et rose vif |

Le menu de Diva conserve sa propre palette rose. Les thèmes incluent 26 fonds d'écran, avec les crédits dans les dossiers correspondants.

La petite Diva du bureau peut être déplacée et masquée dans les réglages. Agiter doucement le pointeur de gauche à droite près d'elle permet de la caresser. Les animations peuvent être désactivées. L'écran de veille Diva se règle également depuis le menu.

### Activer l'assistante

Dans **Réglages → Mon assistante**, choisir Claude ou ChatGPT, utiliser **Me connecter**, puis **Tester**.

Le programme correspondant doit être installé séparément : Claude Code pour Claude, Codex CLI pour ChatGPT. Diva ne l'installe pas automatiquement. Les appels utilisent l'accès du compte connecté et comptent dans ses limites d'utilisation.

| Niveau | Claude | ChatGPT |
| --- | --- | --- |
| Quotidien, par défaut | Sonnet | Luna |
| Réflexion approfondie, avec lunettes | Opus | Sol |

Le modèle quotidien est sélectionnable dans les réglages. Les modèles de réflexion approfondie sont actuellement configurés dans `ai.deep`.

Diva peut demander une réflexion plus approfondie lorsqu'une tâche paraît complexe. Le contrôleur peut aussi la déclencher après un échec vérifié ou plusieurs anomalies détectées. Elle met alors ses lunettes et affiche les étapes dans un petit terminal violet.

Un seul passage au niveau supérieur est autorisé par tâche. **Les lunettes ne donnent aucune permission supplémentaire.**

### Demander de l'aide en cas de problème

Décrire le symptôme, par exemple « Je n'ai plus de son » ou « Mes écouteurs ne se connectent pas ».

Diva dispose d'un diagnostic et d'une liste limitée de réparations. Elle peut inspecter l'état, appliquer une réparation, vérifier son effet et préparer un rapport si elle n'y arrive pas. Le dépannage autorise au plus deux réparations par demande et quatre en dix minutes.

Les réparations agissent sur les réglages et services prévus ; elles ne réécrivent pas les sources de Diva. Le bouton **Arrêter** est prévu pour interrompre la tâche en cours, mais son comportement doit encore être validé en session réelle.

La vérification des actions reste partielle dans cette version. Une action lancée n'est pas nécessairement terminée ni réussie ; les limites connues sont détaillées dans la partie développement.

### Économiser la batterie

Diva applique progressivement une politique d'économie. Dans les réglages, choisir **Automatique**, **Toujours économiser** ou **Jamais**. Le mode Toujours économiser applique le niveau maximal lorsque l'ordinateur fonctionne sur batterie.

| Niveau automatique | Déclenchement | Changements prévus par le code |
| --- | --- | --- |
| 1 | Sur batterie | Réduction des mouvements spontanés de Diva, suppression des ombres et un seul passage de flou |
| 2 | Charge ≤ 50 % ou autonomie estimée < 2 h 30 | Suppression du flou et des transparences, profil `power-saver`, Bluetooth éteint s'il n'est pas utilisé, luminosité réduite de 15 points si elle dépasse 60 % |
| 3 | Charge ≤ 20 % ou autonomie estimée < 45 min | Animations du compositeur désactivées, luminosité plafonnée à 40 %, rétroéclairage du clavier éteint |

L'estimation dépend de l'utilisation récente. Au branchement, Diva tente de restaurer les réglages enregistrés. **Un bug de restauration de luminosité est connu en 0.13.0** : après le niveau 3, l'écran peut revenir à une valeur intermédiaire plutôt qu'à sa valeur initiale.

Le gain d'autonomie par rapport à Omarchy seul n'a pas encore été mesuré sur une décharge réelle.

### Mettre à jour ou désinstaller

Depuis le dossier du dépôt :

```sh
bin/diva update
bin/diva status

# Pour retirer le pack :
bin/diva uninstall
```

La mise à jour récupère la branche Git suivie, puis relance l'installation. Elle exige un dépôt sans modifications locales. **Elle n'utilise pas encore des versions publiées et validées**, et n'est pas automatiquement déclenchée par une mise à jour d'Omarchy.

La désinstallation est conçue pour retirer les éléments gérés par Diva et restaurer les éléments remplacés. Les réglages personnels de Diva sont conservés. Les sauvegardes d'installation se trouvent dans `~/.local/state/diva/backups/`.

### Limites actuelles à connaître

- La dictée et les échanges vocaux ne sont pas encore disponibles.
- L'interface propre à Diva est en français ; certains menus d'administration, contenus d'extensions et le message du verrouillage d'Omarchy restent en anglais.
- Le parcours Claude a été exercé avec de vrais appels. Le parcours ChatGPT doit encore être validé avec un Codex connecté ; les essais documentés utilisent un substitut.
- Certaines interactions, réparations et installations restent à essayer manuellement. La lecture Netflix et l'installation complète de Stremio ne sont pas entièrement validées.
- L'installation neuve, la locale française, la veille/reprise et l'autonomie sur le portable cible restent à tester.
- Les problèmes de vérification, de diagnostic et de restauration listés ci-dessous sont encore ouverts.

## Développement et maintenance

### Objectif et périmètre

Diva est un pack personnel pour rendre Omarchy accessible à une personne peu technique : une expérience cohérente, des réponses simples en français et des mises à jour faciles à maintenir.

L'autonomie est une priorité. L'objectif est de dépasser les économies par défaut d'Omarchy, avec un gain mesuré et sans réglages pénibles au quotidien. Un grand modèle local n'est pas requis.

Le pack possède actuellement son propre menu et ses propres composants ; Keystroke et HyprWorld ne sont pas des dépendances gérées. Des extensions officielles pourront être intégrées au pack si leur rôle, leur version et leur propriété sont définis. Une installation préexistante ne doit pas devenir la propriété de Diva par défaut.

**Machine cible : HP EliteBook 850 G6**, Intel Core i5-8365U, Intel UHD 620, 16 Go de mémoire. Le développement documenté se fait sur un compte Omarchy séparé d'un Dell Latitude 3410.

Un second compte isole les réglages utilisateur, pas les paquets et services du système. Les changements globaux exigent un environnement de test adapté.

### Architecture et points d'entrée

| Élément | Rôle |
| --- | --- |
| `pack.json` et `bin/diva` | Description du pack, installation, état, mise à jour, désinstallation et tests |
| `theme/` et `hypr/diva.lua` | Thèmes et personnalisation du bureau |
| `plugin/manifest.json` | Extension `io.github.tdemers218.diva`, version 0.13.0 |
| `Diva.qml` | Menu, conversation, exécution et orchestration des tâches |
| `Service.qml` | Chargement indépendant du bureau et de la compagne |
| `Dock.qml`, `Desktop.qml`, `DesktopModel.qml` | Applications, fenêtres et vue d'ensemble |
| `ControlPage.qml` et `SettingsPage.qml` | Contrôles natifs et réglages |
| `core/Actions.js` et `core/Smart.js` | Compréhension locale, recherche, intentions et arguments d'exécution |
| `plugin/bin/diva-ai` | Appels à l'assistante et réponses structurées |
| `plugin/skills/depannage.md` | Compétence de dépannage, chargée lorsqu'un diagnostic accompagne la demande |
| `plugin/bin/diva-run` | Exécution d'une action et vérification lorsqu'un contrôle est défini |
| `plugin/bin/diva-doctor` | `inspect`, `repair`, `verify`, `undo`, `report` |
| `plugin/bin/diva-power` | Lecture batterie, paliers d'économie et restauration |
| `plugin/bin/diva-state` et `diva-window` | État système et opérations fixes sur les fenêtres |
| `plugin/bin/diva-install` et `diva-plugins` | Installations proposées et gestion des extensions |
| `plugin/bin/diva-screensaver` | Effets et scènes de l'écran de veille |
| `tests/` | Tests de logique, intégration, installation et aperçus QML |

Les chemins de composants non préfixés dans ce tableau sont relatifs à `plugin/`. Les notes détaillées sont dans [docs/architecture.md](docs/architecture.md) et le suivi de cohérence dans [docs/sanity-check.md](docs/sanity-check.md). Certaines descriptions historiques de ces documents restent à actualiser ; vérifier le code avant de s'y fier pour une décision d'intégration.

### Données personnelles et mises à jour

Les réglages et l'état modifiable doivent rester hors des sources suivies par Git.

| Chemin par défaut | Contenu |
| --- | --- |
| `~/.config/diva/config.json` | Préférences, fournisseur IA et modèles |
| `~/.config/diva/api-key` | Clé Anthropic facultative |
| `~/.local/state/diva/learned.json` | Raccourcis appris |
| `~/.local/state/diva/companion.json` | Position de la compagne |
| `~/.local/state/diva/power.json` | État des économies et valeurs à restaurer |
| `~/.local/state/diva/journal.jsonl` | Journal de dépannage |
| `~/.local/state/diva/reports/` | Rapports de diagnostic |
| `~/.local/state/diva/install.json` et `backups/` | État et sauvegardes d'installation |
| `~/.cache/diva/` | Cache, notamment celui du catalogue d'extensions |

Extrait de configuration des deux niveaux de réflexion :

```json
{
  "ai": {
    "provider": "claude",
    "models": { "claude": "sonnet", "chatgpt": "gpt-6-luna" },
    "deep": { "claude": "opus", "chatgpt": "gpt-6.1-sol" }
  },
  "power": { "mode": "auto" }
}
```

Cet extrait ne remplace pas les autres préférences du fichier. Les identifiants IA affichés ici correspondent à la version actuelle du projet.

Les mises à jour doivent préserver les préférences, les identifiants de connexion, les raccourcis appris et les configurations d'extensions préexistantes. Ne pas ajouter d'état personnel, de secrets ou de fichiers générés au dépôt.

### Règles pour les actions et le dépannage

- Résoudre localement les demandes connues avant d'appeler un modèle.
- Valider les intentions proposées et exécuter des arguments de forme fixe ; ne pas transformer la réponse du modèle en commande shell libre.
- Garder les mêmes outils et permissions lors du passage au modèle supérieur.
- Conserver une seule escalade par tâche, l'historique des essais et les limites de réparation.
- Vérifier le résultat pertinent pour la demande avant d'annoncer une réussite ou d'apprendre un raccourci.
- Distinguer une panne d'un choix utilisateur ou d'une économie volontaire.
- Journaliser les réparations et proposer une annulation lorsque celle-ci est possible.
- Restaurer sans écraser un changement plus récent de l'utilisateur.
- Corriger les défauts du code dans le dépôt, puis distribuer la correction par mise à jour ; ne pas laisser Diva réécrire ses sources installées.

Le dépôt met déjà en place une partie de ces mécanismes. Les écarts recensés ci-dessous doivent être corrigés avant de présenter ces règles comme des garanties.

Les outils actuels travaillent sans simuler la frappe ou la souris. Si un contrôle direct du bureau devient nécessaire, il devra avoir un état visible, une confirmation pour la session et une suspension en cas d'intervention de l'utilisateur. Le bouton Arrêter devra fonctionner pour toutes les opérations concernées.

### Corrections prioritaires

Ces constats proviennent de la revue du **6 octobre 2026**, sur le commit `507b4fb`. Ils décrivent des problèmes ouverts, pas des correctifs déjà appliqués.

| Priorité | Constat | Correction et critère de validation |
| --- | --- | --- |
| Haute | Restauration de luminosité dans le mauvais ordre | Annuler le plafond avant la réduction. Reproduction isolée : 80 → 65 → 40 → branchement donne actuellement 65, au lieu de 80. Tester aussi une modification manuelle et les transitions 3 → 2 → 0. |
| Haute | Résultat d'action trop optimiste | `diva-run none -- false` renvoie actuellement `ok:true`. Contrôler le code de sortie quand il est disponible, distinguer lancé / vérifié / échec et traiter une réponse illisible comme indéterminée. |
| Haute | Deuxième action sans vérification | `Diva.qml` utilise l'exécution détachée si une vérification est en cours. Sérialiser ou mettre en attente les actions, avec un résultat propre à chacune. |
| Haute | Diagnostic des états volontaires | `diva-doctor` classe Bluetooth éteint, Wi-Fi éteint et silence comme des anomalies sans connaître leur intention. Prendre en compte la politique batterie et le symptôme demandé ; s'arrêter quand celui-ci est résolu. |
| Moyenne | Critères de réussite trop larges | Une ouverture est validée par un changement quelconque de fenêtres ou de focus. Relier la vérification à l'application ou à la fenêtre visée, y compris si l'utilisateur interagit en parallèle. |
| Moyenne | Consommation permanente à examiner | Le dock et le bureau ont chacun un modèle qui échantillonne toutes les 700 ms ; les effets de l'écran de veille utilisent 60 images/s. Étudier un modèle partagé, des mises à jour déclenchées par les changements et un rendu réduit ou statique sur batterie. Mesurer avant de conclure. |

Préserver la protection qui reporte l'apprentissage jusqu'à une réussite vérifiée. Compléter les vérifications pour les rappels, installations et autres actions actuellement sans contrôle observable.

Pour l'économie d'énergie, tester aussi le respect des changements manuels de profil, de Bluetooth et de rétroéclairage, ainsi que la stabilité des paliers lorsque l'autonomie estimée fluctue.

### Validation avant livraison

Sur le compte Omarchy de test :

```sh
bin/diva test
bin/diva status
tests/preview.sh
```

La commande de test requiert notamment Qt Test à `/usr/lib/qt6/bin/qmltestrunner`, Quickshell et les composants Omarchy. Les aperçus isolés sont produits dans `/tmp/diva-*.png` ; ils ne remplacent pas un essai dans la session réelle.

La revue du 6 octobre a exécuté avec succès **43 tests de logique, soit 636 assertions**, via une adaptation Node des tests actions/bureau, **2 tests Python** de fonds d'écran et le contrôle syntaxique de **13 scripts Bash**. Les problèmes de luminosité et de commande échouée ont été reproduits avec des commandes simulées. Le rendu QML et la session Omarchy n'ont pas été exécutés dans cet environnement de revue.

Avant une version destinée au portable cible, valider :

- Une installation neuve, une réinstallation et une désinstallation, avec comparaison des réglages restaurés.
- Une mise à jour après personnalisation, sans modification des sources par les réglages.
- L'apparition et la disparition des applications, menu ouvert comme fermé.
- Les gestes, le dock, les déplacements de fenêtres et les réglages par clic et glisser.
- Les connexions Wi-Fi et Bluetooth, le changement de sortie audio et le volume.
- Des pannes contrôlées, des états volontairement désactivés, Arrêter, les limites et l'annulation.
- Des appels réels Claude et Codex, l'escalade et un échec d'authentification.
- Tous les paliers batterie, le branchement, les changements manuels et la veille/reprise.
- La locale française et tous les messages visibles au quotidien.

Comparer ensuite **Omarchy seul et Omarchy avec Diva** sur le HP cible, avec la même luminosité, les mêmes périphériques et un usage comparable. Mesurer au minimum la consommation au repos, la navigation, la vidéo et la veille. Ne pas annoncer de gain d'autonomie avant ces essais.

### Prochaines étapes

La phase actuelle privilégie la fiabilité, la cohérence et l'autonomie. Les corrections prioritaires et les essais réels passent avant l'ajout de nouvelles fonctions.

Après cette validation :

1. Distribuer des versions identifiées et testées, avec restauration de la version précédente.
2. Évaluer une intégration explicite avec les mises à jour Omarchy, fondée sur ses mécanismes disponibles.
3. Terminer la couverture française et actualiser les documents d'architecture.
4. Rendre le choix du modèle avec lunettes accessible dans les réglages.
5. Ajouter la voix, sans rendre les fonctions locales dépendantes de l'IA.
6. Modulariser progressivement l'orchestration lorsqu'une correction ou un test le justifie.

Toute évolution du guide utilisateur doit décrire le comportement livré et signaler ses limites. Les propositions et les travaux non validés restent dans cette partie développement.

### Licences et crédits

Le manifeste de l'extension déclare une licence MIT. La police Fredoka possède sa propre licence OFL-1.1 dans [plugin/fonts/OFL.txt](plugin/fonts/OFL.txt). Les fonds d'écran sont distribués avec leurs crédits et leur statut de licence dans `theme/<nom>/backgrounds/CREDITS.md`.

