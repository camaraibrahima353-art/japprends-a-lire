# J'APPRENDS À LIRE — MVP

Application d'apprentissage de la lecture et de l'écriture pour débutants. Installable sur Android comme une application, elle fonctionne sans Internet.

## Version téléphone installable (dossier `site/`)
Ce dépôt est l'application complète (la racine est servie par GitHub Pages) : icône sur l'écran d'accueil, plein écran, polices, images, sons et leçons gardés sur le téléphone. Après la **première ouverture avec Internet**, tout marche **sans connexion**.

### Mettre l'application en ligne (une seule fois, gratuit)
Il faut une adresse **https** (obligatoire pour l'installation et le micro).
- **Le plus simple — Netlify Drop** : ouvrir `app.netlify.com/drop` sur un ordinateur, glisser le dossier `site/` dans la page. On obtient une adresse du type `https://xxxx.netlify.app` (créer un compte gratuit pour la garder et la renommer).
- **GitHub Pages** : créer un dépôt, y envoyer le contenu de `site/`, puis Settings → Pages → branche `main`.
- Un simple serveur `http://` sur le réseau local (WiFi de la boutique) **ne suffit pas** : Chrome n'installe une application et n'autorise le micro qu'en https.

### Installer sur chaque téléphone Android
1. Ouvrir l'adresse dans **Chrome** (avec Internet).
2. Toucher **📲 Installer l'application** sur l'accueil, ou menu **⋮ → Installer l'application**.
3. L'icône **Aa** apparaît. Paramètres → carte « Hors ligne » doit afficher ✅.
4. Voix du téléphone sans Internet : Paramètres Android → Synthèse vocale → moteur Google → installer la voix **Français**.

### Mettre à jour
Modifier `source/japprends-a-lire.html`, lancer `python3 source/build.py` (régénère `index.html` et `sw.js` avec un nouveau numéro de cache), puis `git push`. Les téléphones prennent la nouvelle version à l'ouverture suivante.

### Fichier APK (facultatif)
Avec l'adresse https, `pwabuilder.com` génère un paquet Android (.apk / .aab) à partir de l'application, pour l'installer comme une appli classique ou la publier sur le Play Store.

## Enregistrer une vraie voix (Administration → 🎙 Voix)
- **155 sons** à enregistrer, rangés par groupes : nom des lettres, son des lettres, mot exemple, syllabes, mots, syllabes des mots, phrases.
- **« Enregistrer les sons manquants »** : le studio affiche le texte à dire → 🎙 → ■ → ▶ écouter → ✓ garder → suivant (arrêt automatique après 10 s).
- Les sons sont gardés dans le téléphone (IndexedDB) et remplacent la voix de synthèse.
- **Partager la voix avec tous les téléphones** : 📦 Exporter les sons (.zip) → décompresser le zip **à la racine du dépôt** (il crée `audio/fr/…` et `index.json`) → `git push`. Chaque téléphone télécharge les sons une fois et les garde hors ligne.
- Ordre de priorité : son enregistré sur l'appareil → son du serveur (`audio/fr/index.json`) → voix de synthèse.
- On peut aussi importer un fichier audio (mp3, m4a, ogg…) dans les onglets Lettres, Syllabes, Mots, Phrases.

## Version simple en un fichier
`source/japprends-a-lire.html` s'ouvre aussi directement dans Chrome (sans installation), mais sans mode hors ligne garanti ni micro.

## Parcours (7 niveaux, déblocage à 70 % au quiz final — réglable)
| Niveau | Apprendre | S'exercer / Quiz |
|---|---|---|
| 1 Alphabet | 26 cartes : majuscule, minuscule, image, mot, 🔊 | petite/grande lettre, écouter et choisir, image → lettre |
| 2 Voyelles | A E I O U Y, chanson des voyelles | quelle est la voyelle ?, écouter, trouver toutes les voyelles |
| 3 Consonnes et sons | nom **et** son de chaque consonne, B+A=BA | quelle consonne fait ce son ?, image → lettre |
| 4 Syllabes | familles M P L S T B, animation M + A = MA | écouter, compléter, former une syllabe avec deux lettres, lire à voix haute |
| 5 Mots | syllabes en couleurs alternées, lecture guidée | mot ↔ image, reconstituer le mot, écouter, lire à voix haute |
| 6 Lecture | phrases avec surlignage mot à mot | phrase ↔ image, mot manquant, lire à voix haute |
| 7 Écriture | tracé au doigt sur lignage Seyès, « Montre-moi » animé | évaluation auto ✅ Bonne écriture / ⚠️ À améliorer / ❌ Recommencer |

Motivation : points, étoiles (1 à 3 par niveau), 15 badges, série de jours 🔥, objectif du jour 🎯, messages « Bravo ! Tu as appris 5 nouvelles lettres aujourd'hui ! 🎉 ».

## Espaces protégés (code par défaut 1234)
- **Espace parent / enseignant** : temps (total, jour, 7 jours), niveaux, résultats, taux de réussite, difficultés, exercices à revoir, plusieurs apprenants.
- **Administration** : lettres (ajout possible de Ɛ, Ŋ, Ɲ…), syllabes, mots, phrases, images, sons, exercices personnalisés, nom/logo/phrase d'accueil, seuil de déblocage, statistiques de tous les apprenants, sauvegarde/import, synchronisation Supabase.

## Architecture (dans le fichier, sections numérotées)
1. **CONFIG & CONTENU** — `DEFAULT_SETTINGS`, `CONTENT_PACKS.fr` (une entrée par langue), `STROKES` (tracés des majuscules).
2. **STOCKAGE** — `Store` (localStorage) : `jal.settings`, `jal.profiles`, `jal.p.<idProfil>`, `jal.content.<langue>`.
3. **AUDIO** — chaque élément a une clé : `L:A` (nom), `LS:A` (son), `LW:A` (mot exemple), `S:MA`, `W:MAMAN`, `W:MAMAN:0` (syllabe d'un mot), `P:p1` (phrase). Si `content.audio[clé]` existe (fichier importé ou chemin `audio/fr/lettres/a.mp3`), il est joué ; sinon synthèse vocale fr-FR.
4. **PÉDAGOGIE** — `LEVELS` (types d'exercices par niveau), générateurs `G`, `TraceBoard` (couverture du modèle + précision du tracé).
5. **ÉCRANS** — `SCREENS` + actions `ACT` (délégation d'événements, aucun framework).
6. **SYNCHRO** — `Sync.push()` vers la table `learners` (voir `schema.sql`).

## Ajouter une langue
Dupliquer `CONTENT_PACKS.fr` en `CONTENT_PACKS.ff` (par ex.), traduire lettres/mots/phrases, passer `ready:true` dans `LANGS`.

## Suite possible
Comptes enseignants avec Supabase Auth et classes, synchronisation automatique quand Internet revient, tracé des minuscules avec ordre des traits, première langue nationale (pack Pular ou Maninka).
