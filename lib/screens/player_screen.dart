import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/media_item.dart';
import '../providers/library_controller.dart';
import '../widgets/media_tile.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/vm_logo.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final VideoController _videoController;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<LibraryController>();
    _videoController = VideoController(ctrl.player);
  }

  @override
  void dispose() {
    // VideoController ne possède pas de dispose dans cette version :
    // le Player reste la propriété du LibraryController.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<LibraryController>();
    final item = ctrl.current;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lecteur')),
        body: const Center(child: Text('Rien à lire.')),
      );
    }

    final isVideo = item.type == MediaType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const VMLogo(size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () => QueueSheet.show(context),
            tooltip: 'Ordre de lecture',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: isVideo ? 3 : 2,
              child: isVideo
                  ? Center(
                      child: Video(
                        controller: _videoController,
                        controls: NoVideoControls,
                      ),
                    )
                  : _AudioArtwork(
                      isPlaying: ctrl.isPlaying,
                      title: item.name,
                    ),
            ),
            _ProgressBar(ctrl: ctrl),
            _MainControls(ctrl: ctrl),
            _SecondaryControls(ctrl: ctrl),
            // "À suivre" : montre l'enchaînement automatique.
            _UpNext(ctrl: ctrl),
          ],
        ),
      ),
    );
  }
}

class _AudioArtwork extends StatelessWidget {
  final bool isPlaying;
  final String title;
  const _AudioArtwork({required this.isPlaying, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: isPlaying ? 220 : 190,
            height: isPlaying ? 220 : 190,
            decoration: BoxDecoration(
              gradient: VMTheme.logoGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: VMTheme.primary.withValues(alpha: 0.5),
                  blurRadius: isPlaying ? 60 : 25,
                ),
              ],
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 90,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Visual Media • Lecture automatique',
            style: TextStyle(color: VMTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final LibraryController ctrl;
  const _ProgressBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final totalMs =
        ctrl.duration.inMilliseconds == 0 ? 1 : ctrl.duration.inMilliseconds;
    final value =
        (ctrl.position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Slider(
            value: value,
            onChanged: (v) {
              final target = Duration(
                milliseconds: (v * ctrl.duration.inMilliseconds).round(),
              );
              ctrl.seek(target);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(ctrl.position),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                formatDuration(ctrl.duration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainControls extends StatelessWidget {
  final LibraryController ctrl;
  const _MainControls({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 34,
            color: Colors.white70,
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: ctrl.playPrevious,
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              gradient: VMTheme.logoGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              iconSize: 44,
              color: Colors.white,
              icon: ctrl.isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(ctrl.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
              onPressed: ctrl.togglePlayPause,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            iconSize: 34,
            color: Colors.white70,
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: () => ctrl.playNext(),
          ),
        ],
      ),
    );
  }
}

class _SecondaryControls extends StatelessWidget {
  final LibraryController ctrl;
  const _SecondaryControls({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(ctrl.shuffle ? 'Aléatoire ON' : 'Aléatoire'),
            selected: ctrl.shuffle,
            onSelected: (_) => ctrl.toggleShuffle(),
          ),
          ActionChip(
            label: Text(
              ctrl.repeatMode == VmRepeatMode.one
                  ? 'Répéter 1'
                  : ctrl.repeatMode == VmRepeatMode.all
                      ? 'Répéter tout'
                      : 'Sans répétition',
            ),
            avatar: const Icon(Icons.repeat_rounded, size: 16),
            onPressed: ctrl.cycleRepeat,
          ),
          ActionChip(
            label: Text('${ctrl.speed.toStringAsFixed(2)}x'),
            avatar: const Icon(Icons.speed_rounded, size: 16),
            onPressed: () {
              final speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
              final i = speeds.indexWhere((s) => s >= ctrl.speed);
              final next = speeds[(i + 1) % speeds.length];
              ctrl.setSpeed(next);
            },
          ),
          ActionChip(
            label: Text(ctrl.autoplay ? 'Auto ON' : 'Auto OFF'),
            avatar: Icon(
              ctrl.autoplay
                  ? Icons.play_circle_fill_rounded
                  : Icons.play_circle_outline_rounded,
              size: 16,
            ),
            onPressed: ctrl.toggleAutoplay,
          ),
        ],
      ),
    );
  }
}

class _UpNext extends StatelessWidget {
  final LibraryController ctrl;
  const _UpNext({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.queue.isEmpty) return const SizedBox.shrink();
    final nextIndex = ctrl.currentIndex + 1 < ctrl.queue.length
        ? ctrl.currentIndex + 1
        : (ctrl.repeatMode == VmRepeatMode.all ? 0 : -1);
    final next =
        nextIndex >= 0 ? ctrl.queue[nextIndex] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VMTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.playlist_play_rounded, color: VMTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'À suivre (automatique)',
                  style: TextStyle(
                    color: VMTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  next?.name ?? 'Fin de la file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => QueueSheet.show(context),
            child: const Text('Arranger'),
          ),
        ],
      ),
    );
  }
}
