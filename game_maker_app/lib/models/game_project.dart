import 'dart:convert';
import 'dart:typed_data';

class AssetItem {
  AssetItem({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
  });

  String id;
  String name;
  String type;
  Uint8List data;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'data': base64Encode(data),
      };

  factory AssetItem.fromJson(Map<String, dynamic> json) => AssetItem(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        data: base64Decode(json['data'] as String),
      );
}

class BehaviorBlock {
  BehaviorBlock({
    required this.id,
    required this.type,
    this.params = const {},
  });

  String id;
  String type;
  Map<String, dynamic> params;

  BehaviorBlock copy() => BehaviorBlock(id: id, type: type, params: {...params});

  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'params': params};

  factory BehaviorBlock.fromJson(Map<String, dynamic> json) => BehaviorBlock(
        id: json['id'] as String,
        type: json['type'] as String,
        params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
      );
}

class GameObject {
  GameObject({
    required this.id,
    required this.name,
    required this.kind,
    this.x = 100,
    this.y = 100,
    this.width = 48,
    this.height = 48,
    this.color = 0xFF6EE7B7,
    this.assetId,
    this.text = '',
    List<BehaviorBlock>? behaviors,
  }) : behaviors = behaviors ?? [];

  String id;
  String name;
  String kind;
  double x;
  double y;
  double width;
  double height;
  int color;
  String? assetId;
  String text;
  List<BehaviorBlock> behaviors;

  GameObject copy() => GameObject(
        id: id,
        name: name,
        kind: kind,
        x: x,
        y: y,
        width: width,
        height: height,
        color: color,
        assetId: assetId,
        text: text,
        behaviors: behaviors.map((b) => b.copy()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'color': color,
        'assetId': assetId,
        'text': text,
        'behaviors': behaviors.map((b) => b.toJson()).toList(),
      };

  factory GameObject.fromJson(Map<String, dynamic> json) => GameObject(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String,
        x: (json['x'] as num?)?.toDouble() ?? 100,
        y: (json['y'] as num?)?.toDouble() ?? 100,
        width: (json['width'] as num?)?.toDouble() ?? 48,
        height: (json['height'] as num?)?.toDouble() ?? 48,
        color: (json['color'] as num?)?.toInt() ?? 0xFF6EE7B7,
        assetId: json['assetId'] as String?,
        text: json['text'] as String? ?? '',
        behaviors: ((json['behaviors'] as List?) ?? [])
            .map((e) => BehaviorBlock.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class GameScene {
  GameScene({required this.id, required this.name, List<GameObject>? objects})
      : objects = objects ?? [];

  String id;
  String name;
  List<GameObject> objects;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'objects': objects.map((o) => o.toJson()).toList(),
      };

  factory GameScene.fromJson(Map<String, dynamic> json) => GameScene(
        id: json['id'] as String,
        name: json['name'] as String,
        objects: ((json['objects'] as List?) ?? [])
            .map((e) => GameObject.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class GameProject {
  GameProject({
    required this.name,
    this.width = 640,
    this.height = 360,
    List<GameScene>? scenes,
    List<AssetItem>? assets,
    this.customJs = '',
  })  : scenes = scenes ?? [GameScene(id: 'scene-1', name: 'Main')],
        assets = assets ?? [];

  String name;
  int width;
  int height;
  List<GameScene> scenes;
  List<AssetItem> assets;
  String customJs;

  GameScene get mainScene => scenes.first;

  Map<String, dynamic> toJson() => {
        'name': name,
        'width': width,
        'height': height,
        'scenes': scenes.map((s) => s.toJson()).toList(),
        'assets': assets.map((a) => a.toJson()).toList(),
        'customJs': customJs,
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory GameProject.fromJson(Map<String, dynamic> json) {
    final loadedScenes = ((json['scenes'] as List?) ?? [])
        .map((e) => GameScene.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return GameProject(
        name: json['name'] as String? ?? 'Untitled Game',
        width: (json['width'] as num?)?.toInt() ?? 640,
        height: (json['height'] as num?)?.toInt() ?? 360,
        scenes: loadedScenes.isEmpty ? [GameScene(id: 'scene-1', name: 'Main')] : loadedScenes,
        assets: ((json['assets'] as List?) ?? [])
            .map((e) => AssetItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        customJs: json['customJs'] as String? ?? '',
      );
  }
}
