import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/library_controller.dart';
import 'media_tile.dart';

/// Panneau "Ordre de lecture" : réordonner, lecture auto à la suite.
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VMTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<LibraryController>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "File d'attente",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: VMTheme.textPrimary,
                      ),
                    ),
                  ),
                  _pillButton(
                    icon: ctrl.autoplay
                        ? Icons.play_circle_fill_rounded
                        : Icons.play_circle_outline_rounded,
                    label: ctrl.autoplay ? 'Auto ON' : 'Auto OFF',
                    active: ctrl.autoplay,
                    onTap: ctrl.toggleAutoplay,
                  ),
                  const SizedBox(width: 8),
                  _pillButton(
                    icon: Icons.shuffle_rounded,
                    label: 'Mélanger',
                    active: ctrl.shuffle,
                    onTap: ctrl.toggleShuffle,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Glissez pour arranger l’ordre — la lecture s’enchaîne automatiquement.',
                  style: TextStyle(
                    color: VMTheme.textSecondary.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _modeChip(
                    label: _repeatLabel(ctrl.repeatMode),
                    icon: _repeatIcon(ctrl.repeatMode),
                    onTap: ctrl.cycleRepeat,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed:
                        ctrl.queue.isEmpty ? null : ctrl.shuffleQueue,
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: const Text('Aléatoire'),
                  ),
                  TextButton.icon(
                    onPressed:
                        ctrl.queue.isEmpty ? null : ctrl.clearQueue,
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Vider'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ctrl.queue.isEmpty
                    ? const Center(
                        child: Text(
                          'File vide.\nAjoutez des musiques ou vidéos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: VMTheme.textSecondary),
                        ),
                      )
                    : ReorderableListView.builder(
                        scrollController: scrollController,
                        itemCount: ctrl.queue.length,
                        onReorderItem: (oldIndex, newIndex) =>
                            ctrl.reorderQueue(oldIndex, newIndex),
                        proxyDecorator: (child, index, anim) => Material(
                          color: Colors.transparent,
                          child: child,
                        ),
                        itemBuilder: (context, index) {
                          final item = ctrl.queue[index];
                          final isCurrent = index == ctrl.currentIndex;
                          return Dismissible(
                            key: ValueKey('queue_${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) =>
                                ctrl.removeFromQueue(index),
                            child: Row(
                              key: ValueKey('row_${item.id}'),
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 4),
                                  child: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(
                                      Icons.drag_handle_rounded,
                                      color: VMTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: MediaTile(
                                    item: item,
                                    isCurrent: isCurrent,
                                    isPlaying:
                                        isCurrent && ctrl.isPlaying,
                                    onTap: () => ctrl.playAt(index),
                                    onRemove: () =>
                                        ctrl.removeFromQueue(index),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 18,
                                        color: VMTheme.textSecondary,
                                      ),
                                      onPressed: () =>
                                          ctrl.moveUp(index),
                                      tooltip: 'Monter',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_downward_rounded,
                                        size: 18,
                                        color: VMTheme.textSecondary,
                                      ),
                                      onPressed: () =>
                                          ctrl.moveDown(index),
                                      tooltip: 'Descendre',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _repeatLabel(VmRepeatMode m) {
    switch (m) {
      case VmRepeatMode.off:
        return 'Répétition : off';
      case VmRepeatMode.all:
        return 'Répétition : tout';
      case VmRepeatMode.one:
        return 'Répétition : un';
    }
  }

  IconData _repeatIcon(VmRepeatMode m) {
    switch (m) {
      case VmRepeatMode.off:
        return Icons.repeat_rounded;
      case VmRepeatMode.all:
        return Icons.repeat_on_rounded;
      case VmRepeatMode.one:
        return Icons.repeat_one_on_rounded;
    }
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? VMTheme.logoGradient : null,
          color: active ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: VMTheme.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: VMTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
