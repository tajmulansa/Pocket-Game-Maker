import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/game_project.dart';

class AssetService {
  Future<List<AssetItem>> importAssets() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'svg', 'wav', 'mp3', 'ogg'],
      withData: true,
    );
    if (result == null) return [];
    return result.files.where((f) => f.bytes != null).map((f) {
      final ext = f.extension?.toLowerCase() ?? '';
      final type = ['png', 'jpg', 'jpeg', 'gif', 'svg'].contains(ext) ? 'image' : 'audio';
      return AssetItem(
        id: 'asset-${DateTime.now().microsecondsSinceEpoch}-${f.name.hashCode.abs()}',
        name: f.name,
        type: type,
        data: Uint8List.fromList(f.bytes!),
      );
    }).toList();
  }

  String mimeFor(AssetItem asset) {
    final ext = asset.name.split('.').last.toLowerCase();
    const map = {
      'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'gif': 'image/gif',
      'svg': 'image/svg+xml', 'wav': 'audio/wav', 'mp3': 'audio/mpeg', 'ogg': 'audio/ogg',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}
