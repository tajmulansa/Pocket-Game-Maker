import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app_state.dart';
import '../models/game_project.dart';
import '../services/asset_service.dart';
import '../services/html_exporter.dart';
import '../services/project_store.dart';
import '../widgets/panel.dart';
import '../widgets/scene_canvas.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final state = EditorState();
  final store = ProjectStore();
  final assetService = AssetService();
  final exporter = HtmlExporter();
  final canvasKey = GlobalKey();
  final codeController = TextEditingController();
  int mobileTab = 1;

  @override
  void dispose() { codeController.dispose(); state.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (state.playtest) return _playtest();
        if (state.codeMode && codeController.text != state.project.customJs) {
          codeController.text = state.project.customJs;
          codeController.selection = TextSelection.fromPosition(TextPosition(offset: codeController.text.length));
        }
        return Scaffold(
          appBar: _appBar(),
          body: LayoutBuilder(builder: (context, c) {
            if (c.maxWidth < 780) return _mobileLayout();
            return Row(children: [_leftPanel(), Expanded(child: _canvasPanel()), _rightPanel()]);
          }),
        );
      },
    );
  }

  PreferredSizeWidget _appBar() {
    final narrow = MediaQuery.sizeOf(context).width < 620;
    final more = PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        switch (v) {
          case 'open': _open();
          case 'save': _save();
          case 'assets': _importAssets();
          case 'code': state.toggleCode();
          case 'export': _export();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'open', child: Text('Open project')),
        PopupMenuItem(value: 'save', child: Text('Save project')),
        PopupMenuItem(value: 'assets', child: Text('Import assets')),
        PopupMenuItem(value: 'code', child: Text('Toggle code mode')),
        PopupMenuItem(value: 'export', child: Text('Export HTML5 ZIP')),
      ],
    );
    return AppBar(
      titleSpacing: 14,
      title: Row(children: [
        const Icon(Icons.grid_4x4_rounded, size: 22), const SizedBox(width: 10),
        Flexible(child: Text(state.project.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
        if (state.dirty) const Padding(padding: EdgeInsets.only(left: 7), child: Icon(Icons.circle, size: 7)),
      ]),
      actions: narrow ? [
        IconButton(tooltip: 'Play', icon: const Icon(Icons.play_arrow_rounded), onPressed: state.togglePlaytest),
        more, const SizedBox(width: 4),
      ] : [
        IconButton(tooltip: 'Open project', icon: const Icon(Icons.folder_open_rounded), onPressed: _open),
        IconButton(tooltip: 'Save project', icon: const Icon(Icons.save_rounded), onPressed: _save),
        IconButton(tooltip: 'Import assets', icon: const Icon(Icons.photo_library_outlined), onPressed: _importAssets),
        const SizedBox(width: 4),
        FilledButton.icon(onPressed: state.toggleCode, icon: Icon(state.codeMode ? Icons.design_services : Icons.code_rounded), label: Text(state.codeMode ? 'Visual' : 'Code')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: state.togglePlaytest, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Play')),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: _export, icon: const Icon(Icons.file_download_outlined), label: const Text('Export')),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _mobileLayout() => Column(children: [
    Expanded(child: switch (mobileTab) { 0 => _leftPanel(), 1 => _canvasPanel(), _ => _rightPanel() }),
    NavigationBar(selectedIndex: mobileTab, onDestinationSelected: (i) => setState(() => mobileTab = i), destinations: const [
      NavigationDestination(icon: Icon(Icons.account_tree_outlined), selectedIcon: Icon(Icons.account_tree), label: 'Scene'),
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Editor'),
      NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Inspect'),
    ]),
  ]);

  Widget _leftPanel() => Panel(title: 'Scene', width: 220, trailing: PopupMenuButton<String>(onSelected: _addScene, itemBuilder: (_) => const [PopupMenuItem(value: 'scene', child: Text('New scene'))]), child: ListView(padding: const EdgeInsets.all(10), children: [
    SectionHeader('Scenes'),
    ...state.project.scenes.map((s) => ListTile(
      dense: true, selected: s.id == state.selectedSceneId,
      leading: const Icon(Icons.layers_outlined, size: 19), title: Text(s.name),
      onTap: () { state.selectedSceneId = s.id; state.selectedObjectId = null; state.notifyListeners(); },
    )),
    SectionHeader('Objects'),
    Wrap(spacing: 6, runSpacing: 6, children: [
      _dragObject('player', Icons.person_outline, 'Player'),
      _dragObject('enemy', Icons.smart_toy_outlined, 'Enemy'),
      _dragObject('platform', Icons.rectangle_outlined, 'Platform'),
      _dragObject('coin', Icons.circle_outlined, 'Coin'),
      _dragObject('tile', Icons.grid_on_rounded, 'Tile'),
      _dragObject('text', Icons.title, 'Text'),
    ]),
    const SizedBox(height: 8),
    ...state.scene.objects.map((o) => DragTarget<String>(
      onAcceptWithDetails: (d) => state.addBehaviorToSelected(BehaviorBlock(id: 'b-${DateTime.now().microsecondsSinceEpoch}', type: d.data)),
      builder: (_, candidate, __) => ListTile(
        dense: true, selected: o.id == state.selectedObjectId,
        leading: Icon(_iconForKind(o.kind), size: 18), title: Text(o.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(o.kind), onTap: () => state.selectObject(o.id),
        trailing: o.behaviors.isEmpty ? null : CircleAvatar(radius: 9, child: Text('${o.behaviors.length}', style: const TextStyle(fontSize: 10))),
      ),
    )),
    const SizedBox(height: 6), const Divider(), SectionHeader('Behaviors'),
    ..._behaviorPalette(),
  ]));

  Widget _dragObject(String kind, IconData icon, String label) => Draggable<String>(
    data: 'object:$kind', feedback: Material(color: Colors.transparent, child: Chip(avatar: Icon(icon, size: 16), label: Text(label))),
    child: ActionChip(avatar: Icon(icon, size: 16), label: Text(label), onPressed: () => state.addObject(kind: kind, name: label)),
  );

  List<Widget> _behaviorPalette() => ['move','gravity','collision','score','timer','trigger'].map((type) => Draggable<String>(
    data: type, feedback: Material(color: Colors.transparent, child: Chip(label: Text(_behaviorLabel(type)))),
    child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: Theme.of(context).dividerColor)),
      child: ListTile(dense: true, leading: Icon(_behaviorIcon(type), size: 18), title: Text(_behaviorLabel(type)), subtitle: Text(_behaviorHint(type), maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => state.addBehaviorToSelected(BehaviorBlock(id: 'b-${DateTime.now().microsecondsSinceEpoch}', type: type))),
    )),
  )).toList();

  Widget _canvasPanel() => Container(
    color: const Color(0xFF0A0F1C),
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8), child: Row(children: [
        Chip(avatar: const Icon(Icons.grid_3x3, size: 16), label: Text('${state.project.width} × ${state.project.height}')),
        const Spacer(),
        Text('Drag objects • Drop behavior blocks on objects', style: Theme.of(context).textTheme.bodySmall),
      ])),
      Expanded(child: state.codeMode ? _codeEditor() : DragTarget<String>(
        onAcceptWithDetails: (details) {
          final data = details.data;
          if (!data.startsWith('object:')) return;
          final box = canvasKey.currentContext?.findRenderObject();
          if (box is! RenderBox || !box.hasSize) return;
          final local = box.globalToLocal(details.offset);
          final x = local.dx / box.size.width * state.project.width;
          final y = local.dy / box.size.height * state.project.height;
          final kind = data.substring('object:'.length);
          state.addObject(kind: kind, name: kind[0].toUpperCase() + kind.substring(1), x: x, y: y);
        },
        builder: (context, candidate, rejected) => SceneCanvas(state: state, canvasKey: canvasKey),
      )),
    ]),
  );

  Widget _codeEditor() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Custom JavaScript', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text('API: game.objects, game.input.down(key), game.score.add(n), game.restart()', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      Expanded(child: TextField(
        controller: codeController, expands: true, maxLines: null, minLines: null,
        onChanged: (v) { state.project.customJs = v; state.markDirty(); },
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: InputDecoration(filled: true, fillColor: const Color(0xFF070B12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), hintText: '// Your custom game logic\n// Example: game.score.add(1);'),
      )),
    ]),
  );

  Widget _rightPanel() => Panel(title: 'Inspector', width: 300, child: ListView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 20), children: [
    if (state.selectedObject == null) ...[
      const SectionHeader('Project'),
      TextField(decoration: const InputDecoration(labelText: 'Game name'), controller: TextEditingController(text: state.project.name), onSubmitted: (v) { state.project.name = v; state.markDirty(); }),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _numberField('Width', state.project.width.toDouble(), (v) { state.project.width = v.round().clamp(160, 1920).toInt(); state.markDirty(); })), const SizedBox(width: 8), Expanded(child: _numberField('Height', state.project.height.toDouble(), (v) { state.project.height = v.round().clamp(90, 1080).toInt(); state.markDirty(); }))]),
      const SectionHeader('Assets'),
      if (state.project.assets.isEmpty) const Text('No assets yet. Import sprites, tilesets, sounds, or music.'),
      ...state.project.assets.map((a) => _assetRow(a)),
    ] else ...[
      const SectionHeader('Transform'),
      Row(children: [Expanded(child: _numberField('X', state.selectedObject!.x, (v) { state.selectedObject!.x = v; state.markDirty(); })), const SizedBox(width: 8), Expanded(child: _numberField('Y', state.selectedObject!.y, (v) { state.selectedObject!.y = v; state.markDirty(); }))]),
      Row(children: [Expanded(child: _numberField('W', state.selectedObject!.width, (v) { state.selectedObject!.width = v.max(4); state.markDirty(); })), const SizedBox(width: 8), Expanded(child: _numberField('H', state.selectedObject!.height, (v) { state.selectedObject!.height = v.max(4); state.markDirty(); }))]),
      TextField(decoration: const InputDecoration(labelText: 'Name'), controller: TextEditingController(text: state.selectedObject!.name), onSubmitted: (v) { state.selectedObject!.name = v; state.markDirty(); }),
      if (state.selectedObject!.kind == 'text') TextField(decoration: const InputDecoration(labelText: 'Text'), controller: TextEditingController(text: state.selectedObject!.text), onSubmitted: (v) { state.selectedObject!.text = v; state.markDirty(); }),
      const SectionHeader('Behaviors'),
      if (state.selectedObject!.behaviors.isEmpty) const Text('Drop behavior blocks onto this object.'),
      ...state.selectedObject!.behaviors.map((b) => _behaviorCard(b)),
      const SizedBox(height: 8), Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: state.duplicateSelected, icon: const Icon(Icons.copy, size: 16), label: const Text('Duplicate'))), const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: state.deleteSelected, icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete'))),
      ]),
    ],
  ]));

  Widget _behaviorCard(BehaviorBlock b) {
    final p = b.params;
    return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(_behaviorIcon(b.type), size: 18), const SizedBox(width: 8), Expanded(child: Text(_behaviorLabel(b.type), style: const TextStyle(fontWeight: FontWeight.w800))), IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => state.removeBehavior(b))]),
      switch (b.type) {
        'move' => _inlineNumber('Speed', p, 'speed', 140, b),
        'gravity' => _inlineNumber('Gravity', p, 'gravity', 800, b),
        'score' => _inlineNumber('Points', p, 'points', 10, b),
        'timer' => _inlineNumber('Seconds', p, 'seconds', 60, b),
        'trigger' => Column(children: [
          TextField(decoration: const InputDecoration(labelText: 'Key (e.g. Space)'), onChanged: (v) { p['key'] = v; state.markDirty(); }),
          TextField(decoration: const InputDecoration(labelText: 'Action: addScore | jump | restart'), onChanged: (v) { p['action'] = v; state.markDirty(); }),
          _inlineNumber('Points / Jump', p, 'points', 1, b),
        ]),
        _ => const Text('Auto-configured behavior.'),
      },
    ])));
  }

  Widget _inlineNumber(String label, Map<String,dynamic> p, String key, double fallback, BehaviorBlock b) => Row(children: [Expanded(child: Text(label)), SizedBox(width: 90, child: TextFormField(initialValue: '${p[key] ?? fallback}', keyboardType: TextInputType.number, onChanged: (v) { p[key] = double.tryParse(v) ?? fallback; state.markDirty(); }, decoration: const InputDecoration(isDense: true)))]);
  Widget _numberField(String label, double value, ValueChanged<double> onChange) => TextFormField(initialValue: value.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, isDense: true), onChanged: (v) => onChange(double.tryParse(v) ?? value));

  Widget _assetRow(AssetItem a) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: a.type == 'image' ? Image.memory(a.data, width: 32, height: 32, fit: BoxFit.contain) : const Icon(Icons.audiotrack), title: Text(a.name, overflow: TextOverflow.ellipsis), subtitle: Text(a.type));

  Widget _playtest() => Scaffold(appBar: AppBar(title: const Text('Playtest'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => state.togglePlaytest())), body: FutureBuilder<String>(
    future: rootBundle.loadString('engine/pocket_runtime.js').then((engine) => exporter.buildPreviewHtml(state.project, engine)), builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      return Center(child: InAppWebView(initialData: InAppWebViewInitialData(data: snap.data!, baseUrl: WebUri('http://localhost/'))));
    }));

  Future<void> _save() async {
    final path = await store.save(state.project);
    if (path != null && mounted) { state.dirty = false; state.notifyListeners(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${path.split(Platform.pathSeparator).last}'))); }
  }

  Future<void> _open() async {
    final p = await store.open();
    if (p != null) state.replaceProject(p);
  }

  Future<void> _importAssets() async {
    final added = await assetService.importAssets();
    if (added.isEmpty) return;
    state.project.assets.addAll(added); state.markDirty();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${added.length} asset(s)')));
  }

  Future<void> _export() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getTemporaryDirectory();

    final file = File(
      '${dir.path}/${state.project.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.html5.zip',
    );

    await file.writeAsBytes(
      await exporter.buildZip(state.project),
      flush: true,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'HTML5 game export',
    );

    return;
  }

  final result = await exporter.exportProject(state.project);

  if (result != null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported folder: ${result.path}'),
      ),
    );
  }
}

  void _addScene(String value) {
    final id = 'scene-${DateTime.now().microsecondsSinceEpoch}';
    state.project.scenes.add(GameScene(id: id, name: 'Scene ${state.project.scenes.length + 1}')); state.selectedSceneId = id; state.selectedObjectId = null; state.markDirty();
  }

  IconData _iconForKind(String kind) => switch(kind) { 'player' => Icons.person_outline, 'enemy' => Icons.smart_toy_outlined, 'platform' => Icons.rectangle_outlined, 'coin' => Icons.circle_outlined, 'tile' => Icons.grid_on_rounded, 'text' => Icons.title, _ => Icons.crop_square_rounded };
  IconData _behaviorIcon(String type) => switch(type) { 'move' => Icons.directions_run, 'gravity' => Icons.south, 'collision' => Icons.view_in_ar_outlined, 'score' => Icons.stars_outlined, 'timer' => Icons.timer_outlined, 'trigger' => Icons.flash_on_outlined, _ => Icons.code };
  String _behaviorLabel(String type) => switch(type) { 'move' => 'Move', 'gravity' => 'Gravity', 'collision' => 'Collision', 'score' => 'Score', 'timer' => 'Timer', 'trigger' => 'Trigger', _ => type };
  String _behaviorHint(String type) => switch(type) { 'move' => 'Arrow keys / WASD', 'gravity' => 'Falling + jump-ready', 'collision' => 'Solid platform collision', 'score' => 'Collect coins', 'timer' => 'Countdown clock', 'trigger' => 'Key-driven action', _ => 'Custom' };
}

extension on num {
  double max(double other) => this < other ? other : toDouble();
}
