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

## Dictée (niveaux Syllabes, Mots et Lecture → ✏️ Dictée)
- **4 modes** : syllabes (lettres), mots en syllabes, mots lettre par lettre, phrases (remettre les mots dans l'ordre).
- **3 niveaux de mots** : Facile (syllabes simples), Moyen (ou, on, an, ch, lettres muettes…), Difficile (ai, eau, oi, ph, gn…). En « Difficile », clavier complet avec les accents.
- 🔊 réécouter, 🐢 lentement (syllabe par syllabe), image d'aide activable, 5 / 10 / 15 mots.
- Une erreur : les cases fausses passent en rouge et l'enfant corrige. Deuxième erreur : la bonne réponse s'affiche. Fin : score, liste des mots, « Revoir mes erreurs ».
- Les résultats vont dans l'espace parent (difficultés, à revoir).
- **93 mots** en français (32 faciles, 32 moyens, 29 difficiles) et 14 phrases. Les mots ajoutés dans l'administration (avec leur niveau) entrent aussi dans la dictée.

## Conjugaison (niveau 8, ouvert après le niveau 5 « Mots », en français)
7 leçons qui s'ouvrent l'une après l'autre (quiz réussi à 70 %) :
| Leçon | Temps | Verbes |
|---|---|---|
| 1 Être et avoir | présent | être, avoir |
| 2 Les verbes en -er | présent | parler, chanter, danser, jouer, marcher, regarder, donner, aimer, écouter, manger, travailler, laver |
| 3 Aller, faire, venir… | présent | aller, faire, dire, venir, voir, prendre |
| 4 Pouvoir, vouloir, finir… | présent | pouvoir, vouloir, savoir, finir, boire, dormir, lire, écrire |
| 5 Le futur | futur simple | être, avoir, aller, faire, parler, manger, finir, venir, pouvoir, voir |
| 6 L'imparfait | imparfait | être, avoir, aller, faire, parler, manger, finir, jouer, dormir, venir |
| 7 Le passé composé | passé composé | avoir, être, parler, manger, finir, faire, dire, voir, prendre, boire, lire, aller, venir, tomber |

Chaque leçon : tableau de conjugaison (terminaisons en couleur, 🔊 sur chaque ligne, « Écouter tout »), règle à retenir, exercices et quiz : choisir la bonne forme, la bonne terminaison, le bon pronom, l'infinitif, avoir ou être (passé composé), la bonne forme selon le temps (Aujourd'hui / Demain / Avant / Hier). Après chaque bonne réponse, l'application lit la phrase entière (« nous mangeons »).

## Mathématiques (bouton 🔢 sur l'accueil)
- **Les opérateurs** : + − × ÷ = < > avec leur nom, une explication, un dessin (mangues, ballons…) et 🔊 ; quiz « Quel signe ? » (trouver l'opération, comparer deux nombres, nommer un signe).
- **Tables de multiplication de 0 à 100** (×0 à ×10) : tableau avec 🔊 et « Écouter la table », mode « Cacher les résultats » pour réciter, astuce pour chaque table, entraînement de 10 questions au pavé numérique, tables mélangées par dizaine (0–10, 11–20… 91–100), étoiles par table.
- **Calculs, 12 niveaux** : additions et soustractions jusqu'à 10, 20, 100 (avec objets à compter au début), nombre manquant, multiplications, divisions exactes, petits problèmes (mangues, taxi, marché…), calculs mélangés, grands nombres. Le niveau suivant s'ouvre à 70 %.
- **Calcul mental** : 60 secondes chrono (additions, soustractions, tables, mélangé) avec record.
- Une erreur → « Essaie encore » ; deuxième erreur → la bonne réponse est affichée et lue. Résultats dans l'espace parent (tables réussies, niveaux, record).

## Lire un texte (bouton 📷 sur l'accueil)
- Prendre une photo d'une page (ou choisir une image) : le texte est reconnu **sur le téléphone, sans Internet** (Tesseract, français), puis lu à voix haute.
- Lecture phrase par phrase, la phrase lue est surlignée et le mot prononcé aussi (si la voix du téléphone le permet) ; ⏮ ⏭, vitesse lente / normale / rapide, taille du texte A− / A+, toucher un mot pour l'entendre.
- ✏️ Corriger le texte reconnu, 💾 le garder dans « Mes textes », ou ⌨️ écrire / coller un texte.
- Le module de lecture de photos (≈ 4 Mo) se télécharge à la première utilisation, ou d'avance : Paramètres → « Préparer la lecture de photos hors ligne ».
- Marche avec du texte imprimé. L'écriture à la main est mal reconnue.

## Langues
- **Français** (alphabet latin).
- **Maninka en N’Ko (ߒߞߏ)** : 7 voyelles, ߒ et 20 consonnes, syllabes (familles ߓ ߕ ߘ ߞ ߟ ߡ), 12 mots, 4 petites phrases, écriture de droite à gauche, police Noto Sans NKo incluse. Changer de langue : bouton 🌍 sur l’accueil ou Paramètres. Chaque langue a sa propre progression.
  - Les mots sont écrits **sans signes de ton** : à faire vérifier par un maître N’Ko (modifiables dans Administration).
  - Il n’existe pas de voix de synthèse maninka : en secours, le téléphone lit une transcription avec la voix française. **Enregistrez la vraie voix** dans Administration → 🎙 Voix (avec la langue N’Ko choisie) ; l’export crée `audio/emk-nkoo/`.

## Ajouter une langue
Dupliquer `CONTENT_PACKS.fr` en `CONTENT_PACKS.ff` (par ex.), traduire lettres/mots/phrases, passer `ready:true` dans `LANGS`.

## Suite possible
Comptes enseignants avec Supabase Auth et classes, synchronisation automatique quand Internet revient, tracé des minuscules avec ordre des traits, première langue nationale (pack Pular ou Maninka).
