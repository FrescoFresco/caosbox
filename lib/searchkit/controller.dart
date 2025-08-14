import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:caosbox/searchkit/models.dart';
import 'package:crypto/crypto.dart';

class SearchController extends ChangeNotifier {
  SearchSpec _spec;
  String _quick = '';

  SearchController({SearchSpec? initial})
      : _spec = initial ?? const SearchSpec(root: GroupNode(op: Op.and, children: []));

  SearchSpec get spec => _spec;
  String get quickText => _quick;

  void setQuickText(String v) {
    if (v == _quick) return;
    _quick = v;
    notifyListeners();
  }

  void setSpec(SearchSpec s) {
    _spec = s.clone();
    notifyListeners();
  }

  /// Hash estable para memo (depende de spec + quickText)
  String specHash() {
    final m = jsonEncode({'spec': _specJson(_spec), 'q': _quick});
    return sha1.convert(utf8.encode(m)).toString();
  }

  Map<String, dynamic> _specJson(SearchSpec s) {
    Map<String, dynamic> node(QueryNode n) {
      if (n is LeafNode) {
        return {
          'leaf': true,
          'c': n.clause.runtimeType.toString(),
        };
      } else if (n is GroupNode) {
        return {
          'op': n.op.name,
          'children': [for (final c in n.children) node(c)],
        };
      }
      return {};
    }
    return {'root': node(s.root)};
  }
}
