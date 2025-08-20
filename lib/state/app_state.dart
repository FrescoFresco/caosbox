import 'package:flutter/foundation.dart';
import '../data/repo.dart';
import '../models/item.dart';

class AppState extends ChangeNotifier {
  final Repo repo;
  AppState(this.repo);

  // Búsquedas por pestaña
  String qB1 = '';
  String qB2 = '';
  String qLLeft = '';
  String qLRight = '';

  void setQB1(String v) { qB1 = v; notifyListeners(); }
  void setQB2(String v) { qB2 = v; notifyListeners(); }
  void setQLLeft(String v) { qLLeft = v; notifyListeners(); }
  void setQLRight(String v) { qLRight = v; notifyListeners(); }

  // Acciones de estado
  Future<void> toggleStatus(Item it) async {
    final next = it.status == ItemStatus.completed
        ? ItemStatus.normal
        : ItemStatus.completed;
    await repo.setStatus(it.id, next);
  }

  Future<void> archive(Item it, {bool unarchive = false}) async {
    await repo.setStatus(it.id, unarchive ? ItemStatus.normal : ItemStatus.archived);
  }

  Future<void> toggleLink(String a, String b) async {
    (await repo.hasLink(a, b)) ? await repo.unlink(a, b) : await repo.link(a, b);
  }
}
