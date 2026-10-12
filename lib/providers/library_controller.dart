import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';

enum VmRepeatMode { off, all, one }

enum SortMode { name, recent, type }

class LibraryController extends ChangeNotifier {
  LibraryController() {
    _initPlayer();
  }

  late final Player player;
  StreamSubscription<bool>? _completedSub;

  final List<MediaItem> _library = [];
  final List<MediaItem> _queue = [];
  final List<MediaItem> _history = [];

  int _currentIndex = -1;
  VmRepeatMode repeatMode = VmRepeatMode.all;
  bool shuffle = false;
  bool autoplay = true;
  SortMode sortMode = SortMode.recent;
  String searchQuery = '';

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;
  double volume = 1.0;
  double speed = 1.0;
  bool isLoading = false;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playingSub;

  List<MediaItem> get library => List.unmodifiable(_library);
  List<MediaItem> get queue => List.unmodifiable(_queue);
  List<MediaItem> get history => List.unmodifiable(_history);

  MediaItem? get current =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;

  int get currentIndex => _currentIndex;
  bool get hasMedia => _queue.isNotEmpty;

  List<MediaItem> get visibleLibrary {
    Iterable<MediaItem> items = _library;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      items = items.where((m) => m.name.toLowerCase().contains(q));
    }
    final list = items.toList();
    switch (sortMode) {
      case SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMode.recent:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case SortMode.type:
        list.sort((a, b) => a.type.index.compareTo(b.type.index));
        break;
    }
    return list;
  }

  List<MediaItem> get audioOnly =>
      visibleLibrary.where((m) => m.type == MediaType.audio).toList();
  List<MediaItem> get videoOnly =>
      visibleLibrary.where((m) => m.type == MediaType.video).toList();

  void _initPlayer() {
    player = Player();
    _posSub = player.stream.position.listen((p) {
      position = p;
      notifyListeners();
    });
    _durSub = player.stream.duration.listen((d) {
      duration = d;
      notifyListeners();
    });
    _playingSub = player.stream.playing.listen((playing) {
      isPlaying = playing;
      notifyListeners();
    });
    // Lecture automatique à la suite : quand le média se termine,
    // on enchaîne sans intervention.
    _completedSub = player.stream.completed.listen((completed) {
      if (completed) {
        _onTrackCompleted();
      }
    });
  }

  Future<void> _onTrackCompleted() async {
    if (!autoplay) return;
    if (repeatMode == VmRepeatMode.one) {
      await replay();
      return;
    }
    await playNext(auto: true);
  }

  // ---------- Bibliothèque ----------

  void addMedia(List<MediaItem> items) {
    final existing = _library.map((e) => e.path).toSet();
    var addedQueue = false;
    for (final item in items) {
      if (existing.contains(item.path)) continue;
      _library.add(item);
      _queue.add(item);
      existing.add(item.path);
      addedQueue = true;
    }
    if (addedQueue && _currentIndex == -1 && _queue.isNotEmpty) {
      _currentIndex = 0;
    }
    unawaited(save());
    notifyListeners();
  }

  void removeFromLibrary(MediaItem item) {
    _library.removeWhere((e) => e.id == item.id);
    final qi = _queue.indexWhere((e) => e.id == item.id);
    if (qi != -1) {
      _queue.removeAt(qi);
      if (qi < _currentIndex) {
        _currentIndex--;
      } else if (qi == _currentIndex) {
        if (_queue.isEmpty) {
          _currentIndex = -1;
          unawaited(player.stop());
        } else {
          _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
        }
      }
    }
    unawaited(save());
    notifyListeners();
  }

  void clearLibrary() {
    _library.clear();
    _queue.clear();
    _currentIndex = -1;
    unawaited(player.stop());
    unawaited(save());
    notifyListeners();
  }

  // ---------- File d'attente / ordre de lecture ----------

  /// Définit la file à partir d'une sélection et démarre à [startIndex].
  Future<void> setQueue(List<MediaItem> items, {int startIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(items);
    _currentIndex = items.isEmpty ? -1 : startIndex.clamp(0, items.length - 1);
    notifyListeners();
    if (current != null) {
      await playAt(_currentIndex);
    }
  }

  /// Réordonne la file (drag & drop). Appelé par ReorderableListView
  /// via onReorderItem (newIndex déjà ajusté).
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex > _queue.length) {
      return;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    // Suivre l'élément en cours de lecture.
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    unawaited(save());
    notifyListeners();
  }

  void moveUp(int index) {
    if (index <= 0 || index >= _queue.length) return;
    reorderQueue(index, index - 1);
  }

  void moveDown(int index) {
    if (index < 0 || index >= _queue.length - 1) return;
    reorderQueue(index, index + 2);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_queue.isEmpty) {
        _currentIndex = -1;
        unawaited(player.stop());
      } else {
        _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
        unawaited(playAt(_currentIndex));
      }
    }
    unawaited(save());
    notifyListeners();
  }

  void shuffleQueue() {
    if (_queue.length < 2) return;
    final rnd = Random();
    final currentItem = current;
    _queue.shuffle(rnd);
    if (currentItem != null) {
      _currentIndex = _queue.indexWhere((e) => e.id == currentItem.id);
    }
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    unawaited(player.stop());
    notifyListeners();
  }

  void playAllInOrder(List<MediaItem> items) {
    unawaited(setQueue(items, startIndex: 0));
  }

  // ---------- Lecture ----------

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    isLoading = true;
    notifyListeners();
    final item = _queue[index];
    try {
      await player.open(Media('file:///${item.path.replaceAll('\\', '/')}'));
      await player.setVolume(volume * 100);
      await player.setRate(speed);
      _history.removeWhere((e) => e.id == item.id);
      _history.insert(0, item);
      if (_history.length > 50) _history.removeLast();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (current == null && _queue.isNotEmpty) {
      await playAt(_currentIndex < 0 ? 0 : _currentIndex);
      return;
    }
    await player.playOrPause();
  }

  Future<void> playNext({bool auto = false}) async {
    if (_queue.isEmpty) return;
    if (shuffle && !auto) {
      final rnd = Random();
      var next = rnd.nextInt(_queue.length);
      if (_queue.length > 1) {
        while (next == _currentIndex) {
          next = rnd.nextInt(_queue.length);
        }
      }
      await playAt(next);
      return;
    }
    var next = _currentIndex + 1;
    if (next >= _queue.length) {
      if (repeatMode == VmRepeatMode.all || auto) {
        next = 0;
      } else {
        return;
      }
    }
    await playAt(next);
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    if (position.inSeconds > 5) {
      await player.seek(Duration.zero);
      return;
    }
    var prev = _currentIndex - 1;
    if (prev < 0) {
      prev = repeatMode == VmRepeatMode.all ? _queue.length - 1 : 0;
    }
    await playAt(prev);
  }

  Future<void> replay() async {
    await player.seek(Duration.zero);
    await player.play();
  }

  Future<void> seek(Duration target) => player.seek(target);

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    await player.setVolume(volume * 100);
    notifyListeners();
  }

  Future<void> setSpeed(double s) async {
    speed = s.clamp(0.25, 3.0);
    await player.setRate(speed);
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void cycleRepeat() {
    repeatMode = VmRepeatMode.values[(repeatMode.index + 1) % 3];
    notifyListeners();
  }

  void toggleAutoplay() {
    autoplay = !autoplay;
    notifyListeners();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setSort(SortMode mode) {
    sortMode = mode;
    notifyListeners();
  }

  // ---------- Persistance ----------

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'vm_library',
        jsonEncode(_library.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        'vm_queue',
        jsonEncode(_queue.map((e) => e.toJson()).toList()),
      );
      await prefs.setInt('vm_index', _currentIndex);
      await prefs.setBool('vm_autoplay', autoplay);
      await prefs.setInt('vm_repeat', repeatMode.index);
    } catch (_) {
      // Stockage local optionnel : on ignore les erreurs.
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final libStr = prefs.getString('vm_library');
      final queueStr = prefs.getString('vm_queue');
      if (libStr != null) {
        final list = (jsonDecode(libStr) as List)
            .map((e) => MediaItem.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
        _library
          ..clear()
          ..addAll(list);
      }
      if (queueStr != null) {
        final list = (jsonDecode(queueStr) as List)
            .map((e) => MediaItem.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
        _queue
          ..clear()
          ..addAll(list);
      }
      _currentIndex = prefs.getInt('vm_index') ?? _currentIndex;
      if (_currentIndex >= _queue.length) _currentIndex = _queue.length - 1;
      autoplay = prefs.getBool('vm_autoplay') ?? true;
      repeatMode =
          VmRepeatMode.values[prefs.getInt('vm_repeat') ?? VmRepeatMode.all.index];
      notifyListeners();
    } catch (_) {
      // Premier lancement : rien à charger.
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    player.dispose();
    super.dispose();
  }
}
