// Visual Media (VM) — modèle de média.
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

enum MediaType { audio, video, unknown }

MediaType mediaTypeFromPath(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  const audioExts = {
    '.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma', '.opus',
  };
  const videoExts = {
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.m4v', '.3gp', '.flv',
  };
  if (audioExts.contains(ext)) return MediaType.audio;
  if (videoExts.contains(ext)) return MediaType.video;
  return MediaType.unknown;
}

class MediaItem {
  final String id;
  final String path;
  final String name;
  final MediaType type;
  final Duration? duration;
  final DateTime addedAt;

  MediaItem({
    required this.id,
    required this.path,
    required this.name,
    required this.type,
    this.duration,
    required this.addedAt,
  });

  factory MediaItem.fromPath(String filePath) {
    return MediaItem(
      id: const Uuid().v4(),
      path: filePath,
      name: p.basename(filePath),
      type: mediaTypeFromPath(filePath),
      addedAt: DateTime.now(),
    );
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'unknown';
    return MediaItem(
      id: json['id'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      type: MediaType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => MediaType.unknown,
      ),
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'type': type.name,
        'addedAt': addedAt.toIso8601String(),
      };
}
