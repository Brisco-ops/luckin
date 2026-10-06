# Luck’In

PWA personnelle de Fabrice pour piloter sa vie par sections (Forme, Carrière, Finances, Apprentissage), utilisable avec des amis (comptes, groupe, encouragements). Seule la section **Forme** (sport et nutrition) est construite ; les autres affichent des pistes.

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

- Tout le journal vit dans `localStorage` sous la clé `cap-fit-v1` (objet `db` : `settings`, `days`, `workouts`, `templates`, `weekly`, `active`, `foods`, `reading`, `mod`, `owner`). Chat du coach : `cap-fit-v1:chat`. Ne jamais renommer ces clés : les données existantes des utilisateurs en dépendent.
- `save()` met `db.mod` à jour, écrit en local puis appelle `cloudQueue()` (synchro différée de 1,5 s). `writeLocal()` écrit sans déclencher de synchro.
- Toute nouvelle option dans `settings` doit avoir une valeur par défaut dans `seed()` **et** une migration pour les installations existantes (voir le bloc `onboarded==null` après `db=load()`).

## Supabase

- Projet `https://uuekwjieeswcipzkucjb.supabase.co`, clé publique `sb_publishable_…` dans le code (normal : la sécurité repose sur RLS).
- **Ne jamais** mettre dans le code ni dans git : clés `sb_secret_…` / `service_role`, mot de passe de la base, clés VAPID privées, `CRON_SECRET`. Le dépôt est public.
- Auth : e-mail + mot de passe, « Confirm email » désactivé (l’e-mail Supabase gratuit n’envoie qu’aux membres de l’équipe). Pas de code OTP ni de lien magique (l’app iOS installée ne partage pas la session avec Safari).
- Tables (RLS sur toutes) : `profiles`, `user_data` (journal complet, propriétaire seul), `groups` (code d’invitation 6 caractères), `group_members`, `daily_share`, `push_subs`, `cheers`. Fonctions SQL : `is_groupmate`, `join_group(invite)`, `delete_me()`.
- **Confidentialité, règle produit** : les amis ne voient que la régularité (réveil, soir, séance faits oui/non) et la progression en % vers l’objectif. Jamais le poids, les repas, les mesures, les douleurs. `apiKey` (clé Anthropic du coach) n’est jamais envoyée au cloud.
- Synchro : dernier écrit gagne sur le document entier (`db.mod`). `db.owner` empêche de mélanger les données de deux comptes sur un même téléphone.
- Notifications : fonction Edge `push` (`supabase/functions/push/index.ts`), déployée depuis le tableau de bord Supabase avec « Verify JWT » désactivé (elle vérifie elle-même l’utilisateur ou l’en-tête `x-cron-secret`). `pg_cron` l’appelle toutes les 15 min pour les rappels (réveil 07:00, soir 21:30, dimanche 19:00 par défaut ; envoyés seulement si le rituel n’est pas fait). Bouton 🔥 : un encouragement par jour et par ami. Secrets dans Supabase › Edge Functions › Secrets : `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `CRON_SECRET`. La clé VAPID publique est aussi dans `src/body.html` (`VAPID_PUB`).

## Repères dans src/body.html

- Vues : `vToday`, `vWorkout`/`vActive`, `vStats`, `vCoach`, `vSettings` ; `render(o)` ; `sec(head, body, foot, cls)` pour les sections.
- Fiches : `morningSheet`, `mealSheet`, `eveningSheet`, `weeklySheet`, `cardioSheet`, `tplSheet` ; actions via `data-act` (gestionnaire de clics) et formulaires via `data-form` (gestionnaire submit).
- Accueil : `AREAS`, `paintHome`, `showHome`, `openArea`, `bloomFrom` ; carte du groupe `paintFriends`.
- Comptes et groupe : `cloudBoot`, `cloudStart`, `cloudPull`, `cloudFlush`, `showGate`, `showOnboard`, `loadGroup`, `accountSec`.
- Notifications : `notifSec`, `notifEnable`, `notifRefresh`, `fnCall`.
- Ouverture : `#splash` (logo « lean in » animé en SVG/CSS, 7,5 s, rejoué à chaque retour dans l’app sauf pendant une séance ou une lecture ; un toucher le passe).

## Identité visuelle

- Logo « Posture » : chaise bleue `#2B3FC4`, buste et tête encre `#14161C` qui passent d’avachi à penché en avant ; tête « avant » grise `#D3D6DD` (sombre : `#4A4F5C`, fond `#14161C`, flèche `#8E9BF0`). Mot « luck’in » en minuscules, apostrophe en flèche. Fichiers sources : `~/Documents/App/luckin-logo/`.
- UI : style iOS, verre dépoli (`--glass`, `--glass-line`, `--glass-shadow`), barre d’onglets en pilule flottante, couleur de section via `--area`. Police Plus Jakarta Sans. Clair et sombre suivent le téléphone.
- Couleurs des sections : Forme `#F2994A`, Carrière `#3E6FD8`, Finances `#2F9E6E`, Apprentissage `#8E5CC9`.

## Pièges iOS connus

- Notifications : seulement dans l’app installée (iOS 16.4+), permission demandée pendant un geste de l’utilisateur.
- Pas d’accès à Santé, pas de son en arrière-plan ; le clavier peut laisser la barre du bas décalée (correctif `nudge`).
- L’icône d’écran d’accueil ne se met à jour qu’en réinstallant l’app.

## Prochaines étapes envisagées

1. Retours de la première semaine avec les amis.
2. Section Carrière : candidatures, relances, entretiens, objectif hebdomadaire.
3. « Mot de passe oublié » (brancher un SMTP, ex. Resend).
4. Sections Finances et Apprentissage ; système d’objectifs (3 max, urgence 30 % / impact 50 % / effort 20 %).
