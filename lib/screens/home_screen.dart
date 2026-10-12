import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/media_item.dart';
import '../providers/library_controller.dart';
import '../widgets/media_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/vm_logo.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma', 'opus',
        'mp4', 'mkv', 'avi', 'mov', 'wmv', 'webm', 'm4v', '3gp',
      ],
    );
    if (result == null || !mounted) return;
    final items = result.files
        .where((f) => f.path != null)
        .map((f) => MediaItem.fromPath(f.path!))
        .where((m) => m.type != MediaType.unknown)
        .toList();
    if (items.isEmpty || !mounted) return;
    context.read<LibraryController>().addMedia(items);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${items.length} média(s) ajouté(s)')),
      );
    }
  }

  void _openPlayer() {
    final ctrl = context.read<LibraryController>();
    if (ctrl.current == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<LibraryController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0xFF1B1440), VMTheme.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    const VMLogo(showLabel: true),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () => QueueSheet.show(context),
                      icon: const Icon(Icons.queue_music_rounded),
                      tooltip: "File d'attente",
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _pickFiles,
                      style: IconButton.styleFrom(
                        backgroundColor: VMTheme.accent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Ajouter des médias',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TextField(
                  onChanged: ctrl.setSearch,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un titre…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: VMTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: PopupMenuButton<SortMode>(
                      icon: const Icon(Icons.sort_rounded),
                      onSelected: ctrl.setSort,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: SortMode.recent,
                          child: Text('Récents'),
                        ),
                        PopupMenuItem(
                          value: SortMode.name,
                          child: Text('Nom A-Z'),
                        ),
                        PopupMenuItem(
                          value: SortMode.type,
                          child: Text('Type'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _AutoBanner(ctrl: ctrl),
              TabBar(
                controller: _tabs,
                indicatorColor: VMTheme.accent,
                labelColor: Colors.white,
                unselectedLabelColor: VMTheme.textSecondary,
                tabs: const [
                  Tab(text: 'Tous'),
                  Tab(text: 'Musiques'),
                  Tab(text: 'Vidéos'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _MediaList(
                      items: ctrl.visibleLibrary,
                      onPlayAll: () =>
                          ctrl.playAllInOrder(ctrl.visibleLibrary),
                    ),
                    _MediaList(
                      items: ctrl.audioOnly,
                      onPlayAll: () =>
                          ctrl.playAllInOrder(ctrl.audioOnly),
                    ),
                    _MediaList(
                      items: ctrl.videoOnly,
                      onPlayAll: () =>
                          ctrl.playAllInOrder(ctrl.videoOnly),
                    ),
                  ],
                ),
              ),
              MiniPlayer(onExpand: _openPlayer),
            ],
          ),
        ),
      ),
      floatingActionButton: ctrl.current == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: VMTheme.primary,
              onPressed: _openPlayer,
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('Lecteur'),
            ),
    );
  }
}

class _AutoBanner extends StatelessWidget {
  final LibraryController ctrl;
  const _AutoBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: VMTheme.logoGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            ctrl.autoplay
                ? Icons.play_circle_fill_rounded
                : Icons.play_circle_outline_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ctrl.autoplay
                  ? 'Lecture auto : le suivant démarre seul (${ctrl.queue.length} en file)'
                  : 'Lecture auto coupée : activez pour enchaîner sans toucher',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: ctrl.autoplay,
            activeThumbColor: Colors.white,
            onChanged: (_) => ctrl.toggleAutoplay(),
          ),
        ],
      ),
    );
  }
}

class _MediaList extends StatelessWidget {
  final List<MediaItem> items;
  final VoidCallback onPlayAll;
  const _MediaList({required this.items, required this.onPlayAll});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<LibraryController>();
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: VMTheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 44,
                color: VMTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aucun média ici',
              style: TextStyle(
                color: VMTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajoutez musiques et vidéos,\nelles se liront à la suite.',
              textAlign: TextAlign.center,
              style: TextStyle(color: VMTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: Row(
            children: [
              Text(
                '${items.length} élément(s)',
                style: const TextStyle(color: VMTheme.textSecondary),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: VMTheme.accent,
                ),
                onPressed: onPlayAll,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Tout lire'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final qi =
                  ctrl.queue.indexWhere((e) => e.id == item.id);
              final isCurrent =
                  qi != -1 && qi == ctrl.currentIndex;
              return MediaTile(
                item: item,
                isCurrent: isCurrent,
                isPlaying: isCurrent && ctrl.isPlaying,
                onTap: () async {
                  if (qi != -1) {
                    await ctrl.playAt(qi);
                  } else {
                    ctrl.addMedia([item]);
                    await ctrl.playAt(ctrl.queue.length - 1);
                  }
                  if (context.mounted &&
                      item.type == MediaType.video) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlayerScreen(),
                      ),
                    );
                  }
                },
                onRemove: () => ctrl.removeFromLibrary(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
