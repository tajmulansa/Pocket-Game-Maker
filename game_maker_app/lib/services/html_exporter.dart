import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/game_project.dart';

class HtmlExportResult {
  HtmlExportResult({required this.path, required this.folderExport});

  final String path;
  final bool folderExport;
}

class HtmlExporter {
  Future<HtmlExportResult?> exportProject(GameProject project) async {
    if (Platform.isAndroid || Platform.isIOS) return null;

    final root = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose HTML5 export folder',
    );
    if (root == null) return null;

    final safe = project.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final out = Directory('$root${Platform.pathSeparator}$safe');
    await out.create(recursive: true);

    final engine = await rootBundle.loadString('engine/pocket_runtime.js');

    await File('${out.path}${Platform.pathSeparator}index.html')
        .writeAsString(_indexHtml(project));

    await File('${out.path}${Platform.pathSeparator}game.js')
        .writeAsString(_gameJs(project, engine));

    final assetDir =
        Directory('${out.path}${Platform.pathSeparator}assets');
    await assetDir.create(recursive: true);

    for (final asset in project.assets) {
      await File('${assetDir.path}${Platform.pathSeparator}${asset.name}')
          .writeAsBytes(asset.data, flush: true);
    }

    return HtmlExportResult(path: out.path, folderExport: true);
  }

  Future<Uint8List> buildZip(GameProject project) async {
    final engine = await rootBundle.loadString('engine/pocket_runtime.js');
    final archive = Archive();

    final index = utf8.encode(_indexHtml(project));
    final game = utf8.encode(_gameJs(project, engine));

    archive.addFile(ArchiveFile('index.html', index.length, index));
    archive.addFile(ArchiveFile('game.js', game.length, game));

    for (final asset in project.assets) {
      archive.addFile(
        ArchiveFile('assets/${asset.name}', asset.data.length, asset.data),
      );
    }

    final bytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  String buildPreviewHtml(GameProject project, String engine) =>
      '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><title>${_esc(project.name)}</title><style>html,body{margin:0;background:#0b1020;overflow:hidden;width:100%;height:100%;display:grid;place-items:center}canvas{image-rendering:pixelated;max-width:100vw;max-height:100vh;background:#101827}</style></head><body><canvas id="game"></canvas><script>window.PGM_PROJECT=${jsonEncode(project.toJson())};</script><script>$engine</script></body></html>';

  String _indexHtml(GameProject project) =>
      '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><title>${_esc(project.name)}</title><style>html,body{margin:0;background:#0b1020;overflow:hidden;width:100%;height:100%;display:grid;place-items:center}canvas{image-rendering:pixelated;max-width:100vw;max-height:100vh;background:#101827}</style></head><body><canvas id="game"></canvas><script src="game.js"></script></body></html>';

  String _gameJs(GameProject project, String engine) =>
      'window.PGM_PROJECT=${jsonEncode(project.toJson())};\n$engine';

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}