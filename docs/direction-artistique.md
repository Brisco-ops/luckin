# Luck’In : direction artistique

App web installable (PWA) pensée d’abord pour l’iPhone en mode « app installée ». Look **iOS natif, épuré, verre dépoli**, avec une **couleur par section de vie**. Clair et sombre suivent le réglage du téléphone.

## 1. Esprit

- Natif iOS avant tout : listes groupées, feuilles qui montent du bas, menus d’actions, sélecteurs segmentés, cibles tactiles de 44 px minimum.
- Épuré : fond uni, beaucoup d’air, une information principale par ligne, pas de décor inutile.
- Couleur = section : chaque domaine a sa couleur, qui teinte tout son univers (fond, barre d’onglets, accents).
- Verre dépoli (« liquid glass ») : cartes et barres translucides avec flou, bord fin clair, ombre douce.
- Ton : français, tutoiement, phrases courtes, vocabulaire simple, aucun jargon technique.

## 2. Couleurs

### Système (base iOS)

| Jeton | Clair | Sombre |
|---|---|---|
| `--bg` fond | `#F2F2F7` | `#000000` |
| `--card` carte | `#FFFFFF` | `#1C1C1E` |
| `--fill` remplissage (puces, pistes) | `#E3E3E8` | `#2C2C2E` |
| `--label` texte | `#000000` | `#FFFFFF` |
| `--label2` secondaire | `rgba(60,60,67,.6)` | `rgba(235,235,245,.6)` |
| `--label3` tertiaire | `rgba(60,60,67,.3)` | `rgba(235,235,245,.3)` |
| `--sep` séparateur | `rgba(60,60,67,.2)` | `rgba(84,84,88,.65)` |
| `--tint` lien / action | `#007AFF` | `#0A84FF` |
| `--green` / `--orange` / `--red` | `#34C759` / `#FF9500` / `#FF3B30` | `#30D158` / `#FF9F0A` / `#FF453A` |

### Sections (`--area`)

| Section | Couleur |
|---|---|
| Forme | `#F2994A` (orange) |
| Carrière | `#3E6FD8` (bleu) |
| Tâches | `#D94F70` (framboise) |
| Finances | `#2F9E6E` (vert) |
| Apprentissage / Savoir | `#8E5CC9` (violet) |
| Coach central « Luck » | `#2B3FC4` (bleu marque) |
| Agenda Google | `#4285F4` |

Montants : revenus en vert, dépenses en couleur de texte, épargne en `--tint`, virements internes en `--label2`. Priorités des tâches : haute = rouge, moyenne = orange, basse = `--label3`.

### Verre dépoli

```css
--glass: rgba(255,255,255,.55);  --glass-line: rgba(255,255,255,.75);  --glass-shadow: 0 8px 30px rgba(0,0,0,.08);   /* clair */
--glass: rgba(30,30,32,.5);      --glass-line: rgba(255,255,255,.1);   --glass-shadow: 0 8px 30px rgba(0,0,0,.45);   /* sombre */
backdrop-filter: blur(26px) saturate(180%);   border: 1px solid var(--glass-line);   border-radius: 20px;
```

### Fond d’une section

Fond noir (sombre) ou clair, avec des halos flous de la couleur de la section : plusieurs `radial-gradient` mélangeant `--area` avec du blanc, du rose (`#FF2D55`), du jaune (`#FFD60A`) et du noir, placés aux coins. Les cartes en verre flottent par-dessus.

## 3. Typographie

- Police : **Plus Jakarta Sans** (Google Fonts), repli `-apple-system` / SF Pro. Choisie comme équivalent libre d’Instagram Sans.
- Corps : 17 px, interligne 1,35, `letter-spacing: -.01em`.
- Grand titre de page (`h1`) : 34 px, graisse 800, `letter-spacing: -.02em`, aligné à gauche, façon « Large Title » iOS.
- Petit sur-titre au-dessus du h1 (ex. « Finances ») : `--label2`, 15–17 px.
- En-têtes de section : 13 px, MAJUSCULES, `--label2`, légère lettre-espacée.
- Notes sous une section : 13 px, `--label2`.
- Chiffres : `font-variant-numeric: tabular-nums` partout (montants, heures, compteurs).
- Bonjour de l’accueil : 30 px, graisse 600. Citation : italique serif, auteur en petites capitales espacées (11 px, `.18em`).

## 4. Formes et espacements

- Rayon iOS de base : 12 px (`--r`). Cartes en verre : 20 px. Carte amis : 22 px. Pilules et puces : 999 px.
- Cellules de liste : hauteur min. 44 px, marges internes 11 × 16 px, séparateurs de 0,5 px.
- Largeur de contenu : 600 px max, centrée. Marges latérales de 16 px.
- Ronds de chiffres clés (KPI) : 4 ronds en verre sur une ligne, valeur en 19 px graisse 600, libellé en 12 px dessous ; un anneau de progression peut entourer le rond.

## 5. Composants

- **Barre d’onglets en pilule flottante** : en bas, 440 px max, à 10 px du bord (plus la zone sûre), rayon 999 px, verre teinté de la couleur de section, icônes seules (SVG trait 1,8 px). L’onglet actif a un fond de pilule plus marqué. Le coach est toujours le dernier onglet.
- **Accueil** : date et « Bonjour <prénom> » à gauche, rond à l’initiale en haut à droite (réglages), citation, carte du coach central, agenda du jour en liste (pastille de couleur de section par ligne), carte des amis, puis barre des 5 sections avec ronds colorés (`.p-ring`) et libellés.
- **Listes groupées** façon Réglages iOS : cellules avec icône à gauche, texte principal et secondaire, valeur ou chevron à droite.
- **Feuilles (sheets)** : montent du bas avec poignée, en-tête « Annuler / Titre / Enregistrer ». **Menus d’actions** iOS pour les choix rapides (bouton destructeur en rouge).
- **Sélecteur segmenté** iOS ; **puces** (chips) arrondies pour les filtres et suggestions.
- **Cercles à cocher** des tâches, de la couleur de la priorité. Pastilles d’état (« En retard », « nouveau »…) en petites pilules.
- **Barres horizontales** pour les statistiques (libellé, barre, valeur), et sections dépliables (`<details>`) pour les sous-catégories.
- **Calendrier** façon app Calendrier : colonne d’heures, blocs colorés par section, ligne rouge de l’heure actuelle, jour du jour dans un rond rouge.
- **Bouton maison** rond (40 px, bord 2 px couleur de section) en haut à gauche des pages de section.

## 6. Mouvement

- Ouverture d’une section : « éclosion » d’un cercle de couleur depuis la pastille de la section (`bloomFrom`).
- Feuilles : montée en `cubic-bezier(.32,.72,0,1)` en 0,35 s ; fond assombri en fondu.
- Changement d’onglet au glisser : la page suit le doigt puis glisse (0,3 s).
- Écran d’ouverture : logo animé ~4 s (tracé, buste qui passe d’avachi à penché en avant), passable d’un toucher, rejoué seulement après 30 min d’absence.
- Petits retours haptiques sur les actions. Toujours respecter `prefers-reduced-motion` (animations coupées).

## 7. Logo et icône

- Logo « Posture » : une chaise bleue `#2B3FC4`, buste et tête encre `#14161C` qui passent d’avachis à penchés en avant (l’idée de « lean in »). Tête « avant » grise `#D3D6DD`. En sombre : `#4A4F5C`, fond `#14161C`, flèche `#8E9BF0`.
- Mot « luck’in » en minuscules, apostrophe dessinée en flèche.
- Icône d’écran d’accueil : pictogramme seul, sans texte.

## 8. Règles iOS (PWA installée)

- Barre d’état `black-translucent` : le contenu passe sous l’heure. En clair, un voile très progressif garde l’heure lisible (jamais une bande nette).
- Respecter les zones sûres (`env(safe-area-inset-*)`) en haut et en bas.
- Cibles tactiles ≥ 44 px, pas de survol, pas de texte sélectionnable par accident, champs en 16 px minimum (sinon iOS zoome).

## 9. Ce qu’on évite

- Les dégradés criards, les ombres dures, les bordures épaisses.
- Plusieurs couleurs vives sur un même écran : une seule couleur de section, plus les couleurs système pour le sens (vert, orange, rouge).
- Le jargon et les longs paragraphes ; les icônes avec texte dans la barre d’onglets.
