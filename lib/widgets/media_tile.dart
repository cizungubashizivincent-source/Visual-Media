import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/media_item.dart';

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

class MediaIcon extends StatelessWidget {
  final MediaType type;
  final double size;
  const MediaIcon({super.key, required this.type, this.size = 22});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    List<Color> colors;
    switch (type) {
      case MediaType.audio:
        icon = Icons.music_note_rounded;
        colors = const [Color(0xFF7C5CFF), Color(0xFFB79CFF)];
        break;
      case MediaType.video:
        icon = Icons.movie_rounded;
        colors = const [Color(0xFFFF8A3D), Color(0xFFFFC46B)];
        break;
      case MediaType.unknown:
        icon = Icons.insert_drive_file_rounded;
        colors = const [Color(0xFF4A5578), Color(0xFF6B7699)];
        break;
    }
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

class MediaTile extends StatelessWidget {
  final MediaItem item;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const MediaTile({
    super.key,
    required this.item,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: isCurrent ? VMTheme.logoGradient : null,
        color: isCurrent ? null : VMTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            MediaIcon(type: item.type),
            if (isCurrent && isPlaying)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.equalizer_rounded,
                    size: 12,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrent ? Colors.white : VMTheme.textPrimary,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item.type == MediaType.audio
              ? 'Audio • Lecture auto'
              : item.type == MediaType.video
                  ? 'Vidéo • Lecture auto'
                  : 'Fichier',
          style: TextStyle(
            color: isCurrent
                ? Colors.white70
                : VMTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isCurrent ? Colors.white70 : VMTheme.textSecondary,
          ),
          onPressed: onRemove,
          tooltip: 'Retirer',
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
