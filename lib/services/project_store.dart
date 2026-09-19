import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_project.dart';

class ProjectStore {
  Future<String?> save(GameProject project) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Pocket Game Maker project',
      fileName: '${project.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pgm.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null) return null;
    await File(path).writeAsString(project.encode());
    return path;
  }

  Future<GameProject?> open() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return null;
    return GameProject.fromJson(jsonDecode(utf8.decode(result.files.single.bytes!)) as Map<String, dynamic>);
  }

  Future<Directory> tempProjectDir() => getTemporaryDirectory();
}
