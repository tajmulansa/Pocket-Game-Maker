import 'package:flutter/material.dart';

class ToolButton extends StatelessWidget {
  const ToolButton({super.key, required this.icon, required this.label, required this.onTap, this.compact = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10), onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 8 : 10),
          child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 9), if (!compact) Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))]),
        ),
      ),
    ),
  );
}
