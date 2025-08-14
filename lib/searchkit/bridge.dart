import 'package:flutter/foundation.dart';
import 'package:caosbox/app/state/app_state.dart';
import 'package:caosbox/core/models/item.dart';
import 'package:caosbox/searchkit/controller.dart';
import 'package:caosbox/searchkit/engine.dart';
import 'package:caosbox/searchkit/models.dart';

/// Aplica spec + quickText sobre source(). Resultados en [results].
class SearchBinder {
  final AppState state;
  final Iterable<Item> Function() source;
  final SearchController controller;

  final ValueNotifier<List<Item>> results = ValueNotifier<List<Item>>(<Item>[]);
  String _lastRev = '';
  String _lastHash = '';

  SearchBinder({required this.state, required this.source, required this.controller}) {
    // escucha cambios
    state.addListener(_recompute);
    controller.addListener(_recompute);
    // arranque
    _recompute();
  }

  void dispose() {
    state.removeListener(_recompute);
    controller.removeListener(_recompute);
    results.dispose();
  }

  void _recompute() {
    final rev = state.hashCode.toString(); // simple “rev”; puedes exponer uno propio en AppState
    final hash = controller.specHash();
    if (rev == _lastRev && hash == _lastHash) return;

    final base = source();

    // Quick text: OR sobre id|content|note
    SearchSpec spec = controller.spec;
    final q = controller.quickText.trim();
    if (q.isNotEmpty) {
      final tokens = [Token(q, Tri.include)];
      final orGroup = GroupNode(
        op: Op.or,
        children: [
          LeafNode(clause: TextClause(element: 'id', tokens: tokens)),
          LeafNode(clause: TextClause(element: 'content', tokens: tokens)),
          LeafNode(clause: TextClause(element: 'note', tokens: tokens)),
        ],
      );
      spec = SearchSpec(
        root: GroupNode(op: Op.and, children: [spec.root, orGroup]),
      );
    }

    final out = List<Item>.from(applySearch(state, base, spec));
    results.value = out;

    _lastRev = rev;
    _lastHash = hash;
  }
}
