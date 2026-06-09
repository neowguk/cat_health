import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/cat_record.dart';

class CatProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<CatRecord> _records = [];
  String _selectedCat = '';
  bool _loading = true;

  List<CatRecord> get records => _records;
  bool get loading => _loading;
  String get selectedCat => _selectedCat;

  List<String> get catNames =>
      _records.map((r) => r.catName).toSet().toList()..sort();

  List<CatRecord> get selectedRecords =>
      _records.where((r) => r.catName == _selectedCat).toList();

  CatRecord? get latestOfSelected =>
      selectedRecords.isEmpty ? null : selectedRecords.first;

  double? get weightDelta {
    if (selectedRecords.length < 2) return null;
    return selectedRecords[0].weight - selectedRecords[1].weight;
  }

  double get avgWeight7 {
    final recent = _records.take(7).toList();
    if (recent.isEmpty) return 0;
    return recent.map((r) => r.weight).reduce((a, b) => a + b) / recent.length;
  }

  int get todayCount {
    final now = DateTime.now();
    return _records.where((r) =>
    r.timestamp.year == now.year &&
        r.timestamp.month == now.month &&
        r.timestamp.day == now.day
    ).length;
  }

  String get healthStatus {
    if (_records.length < 2) return '데이터 부족';
    final delta = _records.first.weight - _records.last.weight;
    if (delta > 0.15) return '증가';
    if (delta < -0.15) return '감소';
    return '안정';
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _records = await _db.getAllRecords();
    if (_records.isNotEmpty && _selectedCat.isEmpty) {
      _selectedCat = _records.first.catName;
    }
    _loading = false;
    notifyListeners();
  }

  void selectCat(String name) {
    _selectedCat = name;
    notifyListeners();
  }

  Future<void> addRecord(CatRecord record) async {
    await _db.insertRecord(record);
    await load();
  }

  Future<void> deleteRecord(int id) async {
    await _db.deleteRecord(id);
    await load();
  }

  Future<void> resetToSample() async {
    await _db.deleteAllAndSeed();
    _selectedCat = '';
    await load();
  }
}
