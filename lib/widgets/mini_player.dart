import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/library_controller.dart';
import 'media_tile.dart';

/// Mini-lecteur affiché en bas quand un média est chargé.
class MiniPlayer extends StatelessWidget {
  final VoidCallback onExpand;
  const MiniPlayer({super.key, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<LibraryController>();
    final item = ctrl.current;
    if (item == null) return const SizedBox.shrink();
    final progress = ctrl.duration.inMilliseconds > 0
        ? ctrl.position.inMilliseconds / ctrl.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: onExpand,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: VMTheme.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
              child: Row(
                children: [
                  MediaIcon(type: item.type),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VMTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ctrl.isPlaying ? 'Lecture…' : 'En pause',
                          style: const TextStyle(
                            color: VMTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white),
                    onPressed: ctrl.playPrevious,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: VMTheme.logoGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        ctrl.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: ctrl.togglePlayPause,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Colors.white),
                    onPressed: () => ctrl.playNext(),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(VMTheme.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
