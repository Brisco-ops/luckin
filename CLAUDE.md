# Luck’In

PWA personnelle de Fabrice pour piloter sa vie par sections (Forme, Carrière, Finances, Apprentissage), utilisable avec des amis (comptes, groupe, encouragements). Sections construites : **Forme** (sport et nutrition), **Carrière** (candidatures, événements, contacts) et **Tâches** (to-do avec échéances et priorités) ; Finances et Apprentissage affichent des pistes.

- En ligne : https://brisco-ops.github.io/luckin/ (GitHub Pages, dépôt `Brisco-ops/luckin`, branche `main`, racine du dépôt).
- Installée sur iPhone depuis Safari (« Sur l’écran d’accueil »). Toutes les décisions UI visent iOS en mode app installée.

## Façon de travailler avec Fabrice

- Réponses en français, directes, sans détour (« droit au but »). Phrases courtes et claires.
- Il construit pas à pas : livrer une version qui marche, la tester, puis itérer sur ses retours.
- Toute l’interface est en français. Vocabulaire simple, pas de jargon technique dans l’app.

## Structure

```
src/head.html   <head> : meta PWA, manifest, icônes (avant <title>)
src/base.css    styles de base façon iOS (listes groupées, feuilles, segments…)
src/app.css     tout le style propre à Luck’In (ajouté par-dessus base.css)
src/body.html   tout le HTML + le JavaScript de l’app (un seul <script>, IIFE)
build.py        assemble index.html et met à jour la version du cache de sw.js
index.html      GÉNÉRÉ — ne pas modifier à la main
sw.js           service worker : réseau d’abord (cache:'no-cache'), cache hors ligne, notifications push
manifest.webmanifest, *.png   manifest et icônes (pictogramme seul, sans texte)
supabase/       schéma SQL, SQL des notifications, fonction Edge « push »
```

Après chaque modification de `src/` : `python3 build.py`, puis commit et push de `index.html` **et** `sw.js` (la version du cache change, c’est ce qui force la mise à jour sur les téléphones).

Aperçu local : `python3 -m http.server 8000` puis http://localhost:8000 (le service worker et les notifications n’y fonctionnent pas : https uniquement).

## Données

- Le dépôt est public : aucun fichier de données personnelles (Excel, CSV…) dans git (`.gitignore` les exclut).

- Tout le journal vit dans `localStorage` sous la clé `cap-fit-v1` (objet `db` : `settings`, `days`, `workouts`, `templates`, `weekly`, `active`, `foods`, `jobs`, `events`, `contacts`, `todos`, `reading`, `mod`, `owner`). Chat du coach : `cap-fit-v1:chat`. Ne jamais renommer ces clés : les données existantes des utilisateurs en dépendent.
- `save()` met `db.mod` à jour, écrit en local puis appelle `cloudQueue()` (synchro différée de 1,5 s). `writeLocal()` écrit sans déclencher de synchro.
- Toute nouvelle option dans `settings` doit avoir une valeur par défaut dans `seed()` **et** une migration pour les installations existantes (voir le bloc `onboarded==null` après `db=load()`).

## Supabase

- Projet `https://uuekwjieeswcipzkucjb.supabase.co`, clé publique `sb_publishable_…` dans le code (normal : la sécurité repose sur RLS).
- **Ne jamais** mettre dans le code ni dans git : clés `sb_secret_…` / `service_role`, mot de passe de la base, clés VAPID privées, `CRON_SECRET`. Le dépôt est public.
- Auth : e-mail + mot de passe, « Confirm email » désactivé (l’e-mail Supabase gratuit n’envoie qu’aux membres de l’équipe). Pas de code OTP ni de lien magique (l’app iOS installée ne partage pas la session avec Safari).
- Stockage : bucket privé `brain` (Apprentissage), une politique par opération limitée au dossier `auth.uid()`. Tables (RLS sur toutes) : `profiles`, `user_data` (journal complet, propriétaire seul), `groups` (code d’invitation 6 caractères), `group_members`, `daily_share`, `push_subs`, `cheers`. Fonctions SQL : `is_groupmate`, `join_group(invite)`, `delete_me()`.
- **Confidentialité, règle produit** : les amis ne voient que la régularité (réveil, soir, séance faits oui/non) et la progression en % vers l’objectif. Jamais le poids, les repas, les mesures, les douleurs. `apiKey` (clé Anthropic du coach) n’est jamais envoyée au cloud.
- Synchro : dernier écrit gagne sur le document entier (`db.mod`). `db.owner` empêche de mélanger les données de deux comptes sur un même téléphone.
- Notifications : fonction Edge `push` (`supabase/functions/push/index.ts`), déployée depuis le tableau de bord Supabase avec « Verify JWT » désactivé (elle vérifie elle-même l’utilisateur ou l’en-tête `x-cron-secret`). `pg_cron` l’appelle toutes les 15 min pour les rappels (réveil 07:00, soir 21:30, dimanche 19:00 par défaut ; envoyés seulement si le rituel n’est pas fait). Rappels d’entretien et d’événement (Carrière) : 2 jours avant et la veille à 19:00, le matin même à 08:00 (sauf entretien avant 09:00), lus dans `user_data.data.jobs` et `.events`, coupables via `notif.iv`. Rappels de tâches : résumé à 08:00 (tâches du jour et en retard) et ~15 min avant une tâche qui a une heure, lus dans `user_data.data.todos`, coupables via `notif.td`. Bouton 🔥 : un encouragement par jour et par ami. Secrets dans Supabase › Edge Functions › Secrets : `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `CRON_SECRET`. La clé VAPID publique est aussi dans `src/body.html` (`VAPID_PUB`).

## Repères dans src/body.html

- Réglages généraux (prénom, compte et amis, notifications, coach IA, données, suppression du compte) : page ouverte depuis le rond à l’initiale en haut à droite de l’accueil (`#hMe`, action `openPrefs`, `paintPrefs`, `H.cur==='reglages'`). Après une action de compte, appeler `refreshView()` (repeint cette page si elle est ouverte, sinon `render()`). Chaque section garde ses propres réglages (Forme : onglet engrenage « Réglages Forme » = `vSettings`).
- Vues : `vToday`, `vWorkout`/`vActive`, `vStats`, `vCoach`, `vSettings` ; `render(o)` ; `sec(head, body, foot, cls)` pour les sections.
- Fiches : `morningSheet`, `mealSheet`, `eveningSheet`, `weeklySheet`, `cardioSheet`, `tplSheet` ; actions via `data-act` (gestionnaire de clics) et formulaires via `data-form` (gestionnaire submit).
- Accueil : date + « Bonjour » + rond Réglages, citation, puis l’agenda « Aujourd’hui » / « Bientôt » (7 jours) de toutes les sections (`agendaItems`, `paintAgenda` : rituels Forme non faits, séance du jour, entretiens, événements, relances, contacts à recontacter, tâches en retard/du jour/à venir ; toucher une ligne ouvre sa fiche, le cercle coche une tâche), carte du groupe `paintFriends`, et en bas la barre des 5 sections (`#orbit.hbar`, boutons `.planet` avec pastille `.p-ring` d’où part l’animation `bloomFrom`). `AREAS`, `paintHome`, `showHome`, `openArea`. Actions d’accueil : `agMorning`, `agEvening`, `agWeekly`, `agWorkout`.
- Comptes et groupe : `cloudBoot`, `cloudStart`, `cloudPull`, `cloudFlush`, `showGate`, `showOnboard`, `loadGroup`, `accountSec`.
- Notifications : `notifSec`, `notifEnable`, `notifRefresh`, `fnCall`.
- Carrière (page dans `#area`, sa propre barre d’onglets `.ctabs` : Candidatures / Événements / Contacts / Bilan, onglet dans `S.car` et `cap-fit-v1:car`) : `paintCareer` → `carJobs` / `carEvents` / `carContacts` / `carStats` (chiffres clés + barres horizontales par statut, étape, raison, mois, contrat, lieu, entreprise), `jobSheet`, `jobGoalSheet`, `jobAct` (actions `job*`), `jobSubmit`. Données `db.jobs` (entreprise, poste, lien, date, statut `envoyee|entretien|offre|refus|silence`, `relances[]`, `interviews[]`) et `settings.career` `{goal, relance}`. Événements (salons, masterclass…), sélecteur « À venir | Passés » en haut de l’onglet (`S.evView`) : `db.events` (titre, type, date, heure, lieu, lien, `questions` une par ligne, `notes`), `evSheet`, `evSubmit`, actions `ev*`. Contacts : `db.contacts` (nom, entreprise, poste, email, linkedin, phone, `met`, `next` = à recontacter le, `last`, notes), `ctSheet`, `ctSubmit`, actions `ct*`. « Écrire un message » (`ctMsgSheet`, modèles `ctTemplates` : remerciement, relance, demande d’échange, libre ; `met` accordé « lors du/de la/des… ») ouvre Mail (`mailto:` avec objet) ou Messages (`sms:numéro&body=`) déjà rempli ; le message est gardé dans `x.msgs` (30 max), `last` = aujourd’hui et `next` échu effacé. Toutes les actions Carrière passent par `jobAct` (renvoie false si l’action n’est pas à elle). Champs d’une candidature en plus : `contract`, `location`, `contact`, `stage` (étape atteinte), `reason`. Import Excel/CSV : `jobImport` (SheetJS chargé à la demande depuis jsdelivr ; colonnes Structure/Entreprise, Poste, Date, Contrat, Statut, Étape, Raison, Contact, Localisation, Lien ; doublons ignorés ; crée aussi les contacts).
- Tâches (page dans `#area`, sans barre) : `paintTodos`, `tdSheet`, `todoSubmit`, `todoAct` (actions `td*`). `db.todos` : `title`, `due`, `time`, `prio` (`haute|moyenne|basse`), `cat` (liste déroulante : `TD_CATS` + catégories déjà utilisées + « Nouvelle catégorie »), `note`, `done`, `doneAt`, `rep` (`day|weekday|week|month|year`), `dom` (jour du mois d’origine), `hist` (dates des fois où une tâche récurrente a été faite). Cocher une tâche récurrente la décale à la prochaine échéance après aujourd’hui (`nextDue`), sans la marquer faite. Rangement : par échéance (en retard, aujourd’hui, demain, 7 jours, plus tard, sans échéance) puis priorité ; le cercle à cocher prend la couleur de la priorité.
- Apprentissage = deuxième cerveau (page dans `#area`, sans barre) : `paintBrain` (liste `brList`/`brResults` avec recherche et étiquettes, ou note `brNoteView` selon `S.note`), `brSheet`, `brLinkSheet`, `brainSubmit`, `brainAct` (actions `br*`). `db.notes` : `title` (unique), `body` (texte, liens `[[Titre]]` comme Obsidian, listes « - », **gras**), `tags`, `links[]` (`url`, `title`), `media[]` (`id`, `type` image|audio|video, `path`, `name`, `size`). Connexions = liens sortants `brOut` + mentions `brBack` ; renommer une note met à jour les `[[ ]]` des autres. Médias dans Supabase Storage, bucket privé `brain` (`supabase/brain.sql`), chemin `<uid>/<noteId>/<id>.<ext>`, URL signées 1 h (`brUrl`) ; photos réduites à 2048 px (`brShrink`), 50 Mo max, mémo vocal via MediaRecorder (`brRecToggle`). Vidéos : de préférence en lien. Écriture : barre d’outils `.br-tools` + appui long dans le texte (menu `brMenu` dans la feuille, `brPop`) pour insérer [[note]], **gras**, `## titre`, liste, lien web `[texte](url)`, image ou fichier (envoyé tout de suite, jeton `![[media:<id>]]` affiché à sa place ; médias en attente `S.brPend` supprimés si on annule). Vue « Carte des connexions » (`S.brView='map'`, sélecteur Liste | Carte) : `brGraphData` (notes + notes citées pas encore créées en pointillés), `brLayout` (disposition par forces, gardée dans `S.brLay` tant que les liens ne changent pas), `brGraph` (SVG `#brgs`, étirée aux proportions du cadre, glisser = déplacer, pincer = zoomer via `S.brVB`, « Recentrer » = `brFit`). Export : `brExport` (JSZip chargé à la demande) → .zip « Deuxième cerveau » avec une note = un .md (frontmatter title/tags/created/updated, liens [[ ]], médias `![[fichier]]` dans « Médias »), enregistré via le menu Partager (`brSaveZip`).
- **Règle des barres d’onglets (toutes les sections)** : retoucher l’onglet déjà ouvert remonte en haut de la page ; s’il est déjà en haut et que c’est le premier onglet, retour à l’accueil (Forme : `setTab` ; Carrière : action `carTab`). À reproduire pour toute nouvelle section avec barre. Une section avec `paint` dans `AREAS` s’affiche comme page.
- Ouverture : `#splash` (logo « lean in » animé en SVG/CSS, 4 s, joué à l’ouverture de l’app ; après un passage dans une autre app, rejoué seulement si l’absence a duré 30 min ou plus (`AWAY`), jamais pendant une séance ou une lecture ; un toucher le passe).

## Identité visuelle

- Logo « Posture » : chaise bleue `#2B3FC4`, buste et tête encre `#14161C` qui passent d’avachi à penché en avant ; tête « avant » grise `#D3D6DD` (sombre : `#4A4F5C`, fond `#14161C`, flèche `#8E9BF0`). Mot « luck’in » en minuscules, apostrophe en flèche. Fichiers sources : `~/Documents/App/luckin-logo/`.
- UI : style iOS, verre dépoli (`--glass`, `--glass-line`, `--glass-shadow`), barre d’onglets en pilule flottante, couleur de section via `--area`. Police Plus Jakarta Sans. Clair et sombre suivent le téléphone.
- Couleurs des sections : Forme `#F2994A`, Carrière `#3E6FD8`, Finances `#2F9E6E`, Apprentissage `#8E5CC9`.

## Pièges iOS connus

- Notifications : seulement dans l’app installée (iOS 16.4+), permission demandée pendant un geste de l’utilisateur.
- Pas d’accès à Santé, pas de son en arrière-plan ; le clavier peut laisser la barre du bas décalée (correctif `nudge`).
- L’icône d’écran d’accueil ne se met à jour qu’en réinstallant l’app.
- Barre d’état `black-translucent` : l’heure est toujours écrite en blanc. En mode clair, un voile très progressif (`body::after`, sans bord net) la garde lisible ; ne pas le remettre en bande de la hauteur exacte de la barre (démarcation visible).

## Prochaines étapes envisagées

1. Retours de la première semaine avec les amis.
2. Carrière v2 : retours de Fabrice, préparation d’entretien avec le coach.
3. « Mot de passe oublié » : abandonné à la demande de Fabrice (pas de SMTP). Un écran à code a existé (commit 4b9d00d, retiré) si on y revient.
4. Sections Finances et Apprentissage ; système d’objectifs (3 max, urgence 30 % / impact 50 % / effort 20 %).
