import 'package:flutter/material.dart';
import 'screens/editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PocketGameMakerApp());
}

class PocketGameMakerApp extends StatelessWidget {
  const PocketGameMakerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Pocket Game Maker',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: const Color(0xFF60A5FA), scaffoldBackgroundColor: const Color(0xFF0B1020)),
    home: const EditorScreen(),
  );
}
