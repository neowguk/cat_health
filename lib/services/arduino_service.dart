import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CatStatus {
  final bool catDetected;
  final String catName;
  final double weight;
  final bool heating;

  CatStatus({
    required this.catDetected,
    required this.catName,
    required this.weight,
    required this.heating,
  });

  factory CatStatus.empty() => CatStatus(
      catDetected: false, catName: '', weight: 0, heating: false);

  factory CatStatus.fromJson(Map<String, dynamic> j) => CatStatus(
    catDetected: j['cat_detected'] ?? false,
    catName: j['cat_name'] ?? '',
    weight: (j['weight'] as num? ?? 0).toDouble(),
    heating: j['heating'] ?? false,
  );
}

class RegisteredCat {
  final String uid;
  final String name;
  RegisteredCat({required this.uid, required this.name});
  factory RegisteredCat.fromJson(Map<String, dynamic> j) =>
      RegisteredCat(uid: j['uid'], name: j['name']);
}

class ArduinoService extends ChangeNotifier {
  String arduinoIp = '192.168.0.100';
  Timer? _timer;

  CatStatus _status = CatStatus.empty();
  List<RegisteredCat> _cats = [];
  bool _connected = false;

  CatStatus get status => _status;
  List<RegisteredCat> get cats => _cats;
  bool get connected => _connected;

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => fetchStatus());
  }

  void stopPolling() {
    _timer?.cancel();
    _connected = false;
    notifyListeners();
  }

  Future<void> fetchStatus() async {
    try {
      final res = await http
          .get(Uri.parse('http://$arduinoIp/status'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        _status = CatStatus.fromJson(jsonDecode(res.body));
        _connected = true;
        notifyListeners();
      }
    } catch (_) {
      _connected = false;
      notifyListeners();
    }
  }

  // RFID 스캔 (최대 10초 대기)
  Future<String?> scanRfid() async {
    try {
      final res = await http
          .get(Uri.parse('http://$arduinoIp/scan'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) return data['uid'];
      }
    } catch (_) {}
    return null;
  }

  // 고양이 RFID 등록
  Future<bool> registerCat(String uid, String name) async {
    try {
      final res = await http
          .post(Uri.parse('http://$arduinoIp/register?uid=$uid&name=$name'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          await fetchCats();
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // 등록된 고양이 목록
  Future<void> fetchCats() async {
    try {
      final res = await http
          .get(Uri.parse('http://$arduinoIp/cats'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _cats = data.map((e) => RegisteredCat.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void setIp(String ip) {
    arduinoIp = ip;
    notifyListeners();
  }
}

