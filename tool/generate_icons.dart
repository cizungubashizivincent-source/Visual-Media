// Genere les icones launcher Visual Media (VM) + icone store.
// Usage : dart run tool/generate_icons.dart
// Ne fait partie ni de l'app ni des tests : script outillage.
import 'dart:io';
import 'package:image/image.dart' as img;

const int master = 1024;

img.ColorRgba8 _lerp(img.ColorRgba8 a, img.ColorRgba8 b, double t) {
  int mix(num x, num y) => (x + (y - x) * t).round().clamp(0, 255);
  return img.ColorRgba8(mix(a.r, b.r), mix(a.g, b.g), mix(a.b, b.b), 255);
}

void _paintGradientSquare(img.Image canvas, int left, int top, int size) {
  final violet = img.ColorRgba8(124, 92, 255, 255);
  final orange = img.ColorRgba8(255, 138, 61, 255);
  final radius = (size * 0.28).round();
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      // coins arrondis
      final cx = x < radius
          ? radius - x
          : (x >= size - radius ? x - (size - radius - 1) : 0);
      final cy = y < radius
          ? radius - y
          : (y >= size - radius ? y - (size - radius - 1) : 0);
      if (cx > 0 && cy > 0 && cx * cx + cy * cy > radius * radius) {
        continue; // transparent
      }
      final t = (x + y) / (2.0 * (size - 1));
      canvas.setPixel(left + x, top + y, _lerp(violet, orange, t));
    }
  }
}

void _paintMark(img.Image canvas, int left, int top, int size) {
  final white = img.ColorRgba8(255, 255, 255, 255);
  final s = size.toDouble();
  img.fillPolygon(
    canvas,
    vertices: [
      img.Point(left + s * 0.34, top + s * 0.26),
      img.Point(left + s * 0.72, top + s * 0.50),
      img.Point(left + s * 0.34, top + s * 0.74),
    ],
    color: white,
  );
  final barH = (s * 0.05).round();
  final barY = (top + s * 0.815).round();
  img.fillRect(
    canvas,
    x1: (left + s * 0.22).round(),
    y1: barY,
    x2: (left + s * 0.78).round(),
    y2: barY + barH,
    radius: barH ~/ 2,
    color: white,
  );
}

/// Logo carre arrondi plein cadre (legacy + store).
img.Image _buildLegacy(int size) {
  final canvas = img.Image(width: size, height: size);
  _paintGradientSquare(canvas, 0, 0, size);
  _paintMark(canvas, 0, 0, size);
  return canvas;
}

/// Premier plan adaptatif : logo centre a 72 % sur fond transparent.
img.Image _buildForeground(int size) {
  final canvas = img.Image(width: size, height: size);
  final logo = (size * 0.72).round();
  final off = ((size - logo) / 2).round();
  _paintGradientSquare(canvas, off, off, logo);
  _paintMark(canvas, off, off, logo);
  return canvas;
}

void _write(img.Image image, String path) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('OK $path (${image.width}x${image.height})');
}

void main() {
  const densities = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  const fgDensities = {
    'mdpi': 108,
    'hdpi': 162,
    'xhdpi': 216,
    'xxhdpi': 324,
    'xxxhdpi': 432,
  };
  final legacyMaster = _buildLegacy(master);
  for (final e in densities.entries) {
    final resized = img.copyResize(
      legacyMaster,
      width: e.value,
      height: e.value,
      interpolation: img.Interpolation.average,
    );
    _write(
        resized, 'android/app/src/main/res/mipmap-${e.key}/ic_launcher.png');
  }
  final fgMaster = _buildForeground(master);
  for (final e in fgDensities.entries) {
    final resized = img.copyResize(
      fgMaster,
      width: e.value,
      height: e.value,
      interpolation: img.Interpolation.average,
    );
    _write(resized,
        'android/app/src/main/res/mipmap-${e.key}/ic_launcher_foreground.png');
  }
  final store = img.copyResize(legacyMaster, width: 512, height: 512);
  _write(store, 'assets/store_icon_512.png');

  // XML icone adaptative.
  const adaptive = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''';
  for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
    final f = File('android/app/src/main/res/mipmap-anydpi-v26/$name')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(adaptive);
    stdout.writeln('OK ${f.path}');
  }
  stdout.writeln('Termine. Ajoute ic_launcher_background dans colors.xml.');
}
