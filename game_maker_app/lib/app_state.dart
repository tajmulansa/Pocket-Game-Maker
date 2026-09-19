import 'package:flutter/foundation.dart';
import 'models/game_project.dart';

class EditorState extends ChangeNotifier {
  GameProject project = GameProject(name: 'My Pocket Game');
  String? selectedSceneId = 'scene-1';
  String? selectedObjectId;
  bool codeMode = false;
  bool playtest = false;
  bool dirty = false;

  GameScene get scene => project.scenes.firstWhere((s) => s.id == selectedSceneId, orElse: () => project.mainScene);
  GameObject? get selectedObject {
    final id = selectedObjectId;
    if (id == null) return null;
    for (final o in scene.objects) {
      if (o.id == id) return o;
    }
    return null;
  }

  void markDirty() { dirty = true; notifyListeners(); }
  void selectObject(String? id) { selectedObjectId = id; notifyListeners(); }
  void toggleCode() { codeMode = !codeMode; notifyListeners(); }
  void togglePlaytest() { playtest = !playtest; notifyListeners(); }

  void addObject({required String kind, required String name, double? x, double? y}) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final colors = <String, int>{
      'player': 0xFF6EE7B7,
      'enemy': 0xFFF97316,
      'platform': 0xFF64748B,
      'coin': 0xFFFACC15,
      'text': 0xFF38BDF8,
      'tile': 0xFF475569,
    };
    final obj = GameObject(
      id: 'obj-$now', name: name, kind: kind,
      x: x ?? 60 + (scene.objects.length % 5) * 70,
      y: y ?? 60 + (scene.objects.length % 4) * 55,
      width: kind == 'platform' ? 120 : 48,
      height: kind == 'platform' ? 24 : 48,
      color: colors[kind] ?? 0xFF94A3B8,
      text: kind == 'text' ? 'Hello!' : '',
    );
    scene.objects.add(obj);
    selectedObjectId = obj.id;
    markDirty();
  }

  void duplicateSelected() {
    final o = selectedObject;
    if (o == null) return;
    final copy = o.copy();
    copy.id = 'obj-${DateTime.now().microsecondsSinceEpoch}';
    copy.name = '${o.name} Copy';
    copy.x += 20; copy.y += 20;
    scene.objects.add(copy);
    selectedObjectId = copy.id;
    markDirty();
  }

  void deleteSelected() {
    final id = selectedObjectId;
    if (id == null) return;
    scene.objects.removeWhere((o) => o.id == id);
    selectedObjectId = null;
    markDirty();
  }

  void addBehaviorToSelected(BehaviorBlock block) {
    final o = selectedObject;
    if (o == null) return;
    o.behaviors.add(block);
    markDirty();
  }

  void removeBehavior(BehaviorBlock block) {
    final o = selectedObject;
    if (o == null) return;
    o.behaviors.remove(block);
    markDirty();
  }

  void replaceProject(GameProject p) {
    project = p;
    selectedSceneId = p.mainScene.id;
    selectedObjectId = null;
    codeMode = false;
    playtest = false;
    dirty = false;
    notifyListeners();
  }
}
