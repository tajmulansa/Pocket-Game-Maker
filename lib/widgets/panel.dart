import 'package:flutter/material.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.width, this.title, this.trailing});
  final Widget child;
  final double? width;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (title != null) Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Row(children: [Expanded(child: Text(title!, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800))), if (trailing != null) trailing!]),
      ),
      Expanded(child: child),
    ]),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  );
}
