import 'package:flutter/foundation.dart';

abstract class LinkRepository extends ChangeNotifier {
  Set<String> linksOf(String id);
  void toggle(String a, String b);
  void replaceAll(Map<String, Set<String>> links);
}
