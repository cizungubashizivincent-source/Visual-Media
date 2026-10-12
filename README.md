# Visual Media (VM) — Lecteur moderne style VLC

App Flutter : lecture audio + vidéo, **lecture automatique à la suite**,
file d'attente réorganisable (drag & drop, monter/descendre, swipe pour supprimer).

## Lancer
```bash
flutter pub get
flutter run
```

## Fonctionnalités
- Médiathèque (Tous / Musiques / Vidéos), recherche, tri (récents, nom, type)
- Ajout de fichiers via sélecteur (mp3, wav, flac, mp4, mkv, avi, mov…)
- **Autoplay** : à la fin d'un média, le suivant démarre seul (désactivable)
- **Arranger l'ordre** : `File d'attente` → glisser-déposer, flèches haut/bas, mélanger, répéter (off/all/one)
- Écran lecteur vidéo (media_kit) + écran audio animé, vitesse 0.5x–2x, volume, seek
- Mini-lecteur, "À suivre", historique, persistance locale (shared_preferences)
- Logo VM intégré (widget `VMLogo` + `assets/vm_logo.svg`)

## Structure
```
lib/
  main.dart
  core/theme.dart
  models/media_item.dart
  providers/library_controller.dart
  screens/home_screen.dart
  screens/player_screen.dart
  widgets/vm_logo.dart
  widgets/media_tile.dart
  widgets/mini_player.dart
  widgets/queue_sheet.dart
assets/vm_logo.svg
```

Logo : dégradé violet `#7C5CFF` → orange `#FF8A3D`, triangle "play" façon cône VLC modernisé.
