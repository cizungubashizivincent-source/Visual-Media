import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/library_controller.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final library = LibraryController();
  await library.load();
  runApp(VisualMediaApp(library: library));
}

/// Visual Media (VM) — lecteur moderne style VLC.
class VisualMediaApp extends StatelessWidget {
  final LibraryController library;
  const VisualMediaApp({super.key, required this.library});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: library,
      child: MaterialApp(
        title: 'Visual Media',
        debugShowCheckedModeBanner: false,
        theme: VMTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
