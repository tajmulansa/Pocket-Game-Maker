import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../app_state.dart';
import '../models/game_project.dart';

class SceneCanvas extends StatelessWidget {
  const SceneCanvas({
    super.key,
    required this.state,
    this.canvasKey,
  });

  final EditorState state;
  final Key? canvasKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _scale(
          constraints.biggest,
          state.project.width.toDouble(),
          state.project.height.toDouble(),
        );

        final canvasSize = Size(
          state.project.width * scale,
          state.project.height * scale,
        );

        return Center(
          child: GestureDetector(
            onTap: () => state.selectObject(null),
            child: Container(
              key: canvasKey,
              width: canvasSize.width,
              height: canvasSize.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(blurRadius: 24, spreadRadius: 2)],
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: _ScenePainter(state: state, scale: scale),
                child: Stack(
                  children: state.scene.objects.map((o) {
                    return Positioned(
                      left: o.x * scale,
                      top: o.y * scale,
                      width: o.width * scale,
                      height: o.height * scale,
                      child: GestureDetector(
                        onTap: () => state.selectObject(o.id),
                        onPanUpdate: (details) {
                          o.x += details.delta.dx / scale;
                          o.y += details.delta.dy / scale;

                          o.x = o.x
                              .clamp(0, state.project.width - o.width)
                              .toDouble();
                          o.y = o.y
                              .clamp(0, state.project.height - o.height)
                              .toDouble();

                          state.markDirty();
                        },
                        child: IgnorePointer(
                          child: _ObjectVisual(
                            object: o,
                            selected: state.selectedObjectId == o.id,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _scale(Size available, double w, double h) {
    return math.min(
      (available.width / w).clamp(0.15, 2.0),
      (available.height / h).clamp(0.15, 2.0),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({
    required this.state,
    required this.scale,
  });

  final EditorState state;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = const Color(0xFF263247)
      ..strokeWidth = 1;

    const step = 16.0;

    for (double x = 0; x <= state.project.width; x += step) {
      canvas.drawLine(
        Offset(x * scale, 0),
        Offset(x * scale, state.project.height * scale),
        grid,
      );
    }

    for (double y = 0; y <= state.project.height; y += step) {
      canvas.drawLine(
        Offset(0, y * scale),
        Offset(state.project.width * scale, y * scale),
        grid,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.scale != scale;
  }
}

class _ObjectVisual extends StatelessWidget {
  const _ObjectVisual({
    required this.object,
    required this.selected,
  });

  final GameObject object;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (object.kind == 'text') {
      return Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          object.text.isEmpty ? object.name : object.text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final shape =
        object.kind == 'coin' ? BoxShape.circle : BoxShape.rectangle;

    return Container(
      decoration: BoxDecoration(
        color: Color(object.color),
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(5) : null,
        border: Border.all(
          color: selected ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          object.kind == 'platform'
              ? ''
              : object.kind.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}