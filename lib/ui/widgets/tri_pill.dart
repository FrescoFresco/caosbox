import 'package:flutter/material.dart';
import 'package:caosbox/core/utils/tri.dart';

class TriPill extends StatelessWidget {
  final String label; final Tri mode; final VoidCallback onTap;
  const TriPill({super.key, required this.label, required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color? bg; if (mode == Tri.include) bg = Colors.green.withOpacity(.15);
    if (mode == Tri.exclude) bg = Colors.red.withOpacity(.15);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (mode == Tri.include) const Icon(Icons.check, size: 14),
          if (mode == Tri.exclude) const Icon(Icons.block, size: 14),
          if (mode != Tri.off) const SizedBox(width: 4),
          Text(label),
        ]),
      ),
    );
  }
}
