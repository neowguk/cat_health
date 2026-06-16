import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/cat_record.dart';

class CatProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<CatRecord> _records = [];
  String _selectedCat = '';
  bool _loading = true;
  Map<String, String> _tagMap = {};

  List<CatRecord> get records => _records;
  bool get loading => _loading;
  String get selectedCat => _selectedCat;
  Map<String, String> get tagMap => Map.unmodifiable(_tagMap);

  List<String> get catNames {
    final fromRecords = _records.map((r) => r.catName).toSet();
    final fromTags = _tagMap.values.toSet();
    return {...fromRecords, ...fromTags}.toList()..sort();
  }

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
    return _records
        .where((r) =>
            r.timestamp.year == now.year &&
            r.timestamp.month == now.month &&
            r.timestamp.day == now.day)
        .length;
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
    await _loadTagMap();

    if (_selectedCat.isEmpty || !catNames.contains(_selectedCat)) {
      if (catNames.isNotEmpty) _selectedCat = catNames.first;
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

  // ─── 태그 관련 ────────────────────────────────

  String? catNameByTag(String uid) => _tagMap[uid];

  Future<void> registerTag(String uid, String catName) async {
    _tagMap[uid] = catName;
    await _saveTagMap();
    notifyListeners();
  }

  Future<void> unregisterTag(String uid) async {
    _tagMap.remove(uid);
    await _saveTagMap();
    notifyListeners();
  }

  Future<void> addCatIfNotExists(String catName, double weight) async {
    if (!_records.any((r) => r.catName == catName)) {
      final record = CatRecord(
        catName: catName,
        weight: weight,
        timestamp: DateTime.now(),
      );
      await addRecord(record);
    }
  }

  // ─── 고양이 이름 수정 ──────────────────────────

  Future<void> renameCat(String oldName, String newName) async {
    for (final record in _records.where((r) => r.catName == oldName).toList()) {
      await _db.updateRecord(record.copyWith(catName: newName));
    }

    _tagMap.updateAll((key, value) => value == oldName ? newName : value);
    await _saveTagMap();

    if (_selectedCat == oldName) _selectedCat = newName;

    await load();
  }

  // ─── 고양이 삭제 ──────────────────────────────

  Future<void> deleteCat(String catName) async {
    for (final record in _records.where((r) => r.catName == catName).toList()) {
      if (record.id != null) {
        await _db.deleteRecord(record.id!);
      }
    }

    _tagMap.removeWhere((key, value) => value == catName);
    await _saveTagMap();

    if (_selectedCat == catName) _selectedCat = '';

    await load();
  }

  // ─── 내부 저장/로드 ───────────────────────────

  Future<void> _saveTagMap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rfid_tag_map', jsonEncode(_tagMap));
  }

  Future<void> _loadTagMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rfid_tag_map');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _tagMap = decoded.map((k, v) => MapEntry(k, v.toString()));
    }
  }
}
