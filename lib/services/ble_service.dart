import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService extends ChangeNotifier {
  static const String _serviceUUID    = '4FAFC201-1FB5-459E-8FCC-C5C9C331914B';
  static const String _weightCharUUID = 'BEB5483E-36E1-4688-B7F5-EA07361B26A8';
  static const String _tempCharUUID   = 'BEB5483F-36E1-4688-B7F5-EA07361B26A8';
  static const String _targetName     = 'CatTower';

  BluetoothDevice? _device;
  StreamSubscription? _weightSub, _tempSub, _scanSub;

  BluetoothAdapterState _status = BluetoothAdapterState.unknown;
  ScanState  _scan      = ScanState.idle;
  String     _log       = '대기 중...';
  double?    _weight;
  double?    _temperature;
  bool       _connected    = false;
  bool       _autoReconnect = true;

  BluetoothAdapterState get status => _status;
  ScanState get scanState    => _scan;
  String    get log          => _log;
  double?   get weight       => _weight;
  double?   get temperature  => _temperature;
  bool      get connected    => _connected;
  bool      get autoReconnect => _autoReconnect;

  BleService() {
    FlutterBluePlus.adapterState.listen((s) {
      _status = s;
      _addLog('블루투스 상태: ${s.name}');
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    if (_scan == ScanState.scanning) return;
    _scan = ScanState.scanning;
    _addLog('스캔 시작...');
    notifyListeners();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withServices: [Guid(_serviceUUID)],
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        final name = r.device.platformName;
        if (name == _targetName || name.contains('CatTower')) {
          await FlutterBluePlus.stopScan();
          _scanSub?.cancel();
          _scan = ScanState.idle;
          _addLog('센서 발견: $name');
          notifyListeners();
          await _connect(r.device);
          return;
        }
      }
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning && _scan == ScanState.scanning) {
        _scan = ScanState.idle;
        _addLog('스캔 종료 (센서를 찾지 못했습니다)');
        notifyListeners();
      }
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scan = ScanState.idle;
    _addLog('스캔 중지');
    notifyListeners();
  }

  Future<void> _connect(BluetoothDevice device) async {
    _device = device;
    _addLog('연결 중...');
    try {
      await device.connect(autoConnect: false);
      _connected = true;
      _addLog('연결 성공: ${device.platformName}');
      notifyListeners();

      device.connectionState.listen((state) {
        _connected = state == BluetoothConnectionState.connected;
        _addLog(_connected ? '연결 유지됨' : '연결 끊김');
        notifyListeners();
        if (!_connected && _autoReconnect) {
          Future.delayed(const Duration(seconds: 3), () => _connect(device));
        }
      });

      await _discoverAndSubscribe(device);
    } catch (e) {
      _addLog('연결 실패: $e');
      _connected = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _autoReconnect = false;
    await _weightSub?.cancel();
    await _tempSub?.cancel();
    await _device?.disconnect();
    _connected = false;
    _device = null;
    _weight = null;
    _temperature = null;
    _addLog('연결 해제됨');
    notifyListeners();
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final svc in services) {
      if (svc.uuid.toString().toUpperCase() != _serviceUUID) continue;
      for (final char in svc.characteristics) {
        final uuid = char.uuid.toString().toUpperCase();
        if (uuid == _weightCharUUID) {
          await char.setNotifyValue(true);
          _weightSub = char.lastValueStream.listen(_onWeightData);
          _addLog('체중 캐릭터리스틱 구독 완료');
        } else if (uuid == _tempCharUUID) {
          await char.setNotifyValue(true);
          _tempSub = char.lastValueStream.listen(_onTempData);
          _addLog('온도 캐릭터리스틱 구독 완료');
        }
      }
    }
  }

  void _onWeightData(List<int> data) {
    if (data.isEmpty) return;
    try {
      final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      _weight = (map['w'] ?? map['weight'] as num).toDouble();
    } catch (_) {
      if (data.length >= 4) {
        _weight = ByteData.view(Uint8List.fromList(data).buffer)
            .getFloat32(0, Endian.little);
      }
    }
    _addLog('체중 수신: ${_weight?.toStringAsFixed(2)} kg');
    notifyListeners();
  }

  void _onTempData(List<int> data) {
    if (data.isEmpty) return;
    try {
      final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      _temperature = (map['t'] ?? map['temperature'] as num).toDouble();
    } catch (_) {
      if (data.length >= 4) {
        _temperature = ByteData.view(Uint8List.fromList(data).buffer)
            .getFloat32(0, Endian.little);
      }
    }
    _addLog('온도 수신: ${_temperature?.toStringAsFixed(1)} °C');
    notifyListeners();
  }

  void _addLog(String msg) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
    _log = '[$ts] $msg';
    if (kDebugMode) print('[BLE] $msg');
  }

  void setAutoReconnect(bool v) {
    _autoReconnect = v;
    notifyListeners();
  }
}

enum ScanState { idle, scanning }
