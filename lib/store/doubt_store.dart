import 'package:flutter/foundation.dart';

import '../models/doubt.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';

/// Single source of truth for saved doubts. UI isse listen karti hai.
class DoubtStore extends ChangeNotifier {
  DoubtStore(this._db);

  final DbService _db;
  List<Doubt> _doubts = [];
  bool _loading = false;

  List<Doubt> get doubts => _doubts;
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _doubts = await _db.getAll();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addSaved(String imagePath, SolvedAnswer answer) async {
    final draft = Doubt(
      id: null,
      imagePath: imagePath,
      title: answer.title,
      solution: answer.solution,
      createdAt: DateTime.now(),
    );
    final id = await _db.insert(draft);
    _doubts = [
      Doubt(id: id, imagePath: draft.imagePath, title: draft.title,
          solution: draft.solution, createdAt: draft.createdAt),
      ..._doubts,
    ];
    notifyListeners();
  }

  Future<void> remove(Doubt d) async {
    await _db.delete(d.id!);
    _doubts = _doubts.where((x) => x.id != d.id).toList();
    notifyListeners();
  }
}
