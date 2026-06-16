import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/arduino_service.dart';

class WifiPanel extends StatefulWidget {
  const WifiPanel({super.key});

  @override
  State<WifiPanel> createState() => _WifiPanelState();
}

class _WifiPanelState extends State<WifiPanel> {
  final _nameController = TextEditingController();
  bool _isScanning = false;
  String? _scannedUid;

  @override
  void initState() {
    super.initState();
    final svc = context.read<ArduinoService>();
    svc.fetchCats();
    svc.startPolling();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scannedUid = null;
    });

    _showSnack('이제 RFID 태그를 인식기에 가까이 대주세요');

    await Future.delayed(const Duration(seconds: 10));

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _register() async {
    if (_scannedUid == null || _nameController.text.isEmpty) {
      _showSnack('UID 스캔 후 이름을 입력해주세요');
      return;
    }

    final ok = await context
        .read<ArduinoService>()
        .registerCat(_scannedUid!, _nameController.text);

    if (ok) {
      _nameController.clear();
      setState(() => _scannedUid = null);
      _showSnack('✅ 등록 완료!');
    } else {
      _showSnack('❌ 등록 실패');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ArduinoService>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (svc.status.catDetected && svc.status.catName.isNotEmpty) {
      _scannedUid ??= svc.status.catName;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer.withOpacity(0.4), cs.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: svc.connected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      svc.connected ? 'HiveMQ 연결됨' : '연결 안 됨',
                      style: tt.labelMedium?.copyWith(
                        color: svc.connected ? cs.primary : cs.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '이 앱은 이제 아두이노 IP가 아니라 HiveMQ 클라우드로 연결됩니다.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ValueCard(
                  label: '실시간 체중',
                  value: svc.status.catDetected
                      ? '${svc.status.weight.toStringAsFixed(2)} kg'
                      : '--',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueCard(
                  label: '온열패드',
                  value: svc.status.heating ? '🔥 ON' : 'OFF',
                  icon: Icons.local_fire_department_rounded,
                  highlight: svc.status.heating,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: svc.status.catDetected
                  ? Colors.green.withOpacity(0.1)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: svc.status.catDetected
                    ? Colors.green
                    : cs.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  svc.status.catDetected ? '🐱' : '😴',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  svc.status.catDetected
                      ? '${svc.status.catName} 감지됨!'
                      : '고양이 없음',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '고양이 RFID 등록',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.nfc_rounded),
              label: Text(_isScanning ? '태그를 갖다 대세요...' : 'RFID 스캔 대기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_scannedUid != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                '감지된 UID: $_scannedUid',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '고양이 이름',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _register,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '등록 완료',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            '등록된 고양이',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          svc.cats.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '등록된 고양이가 없어요',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: svc.cats
                      .map(
                        (cat) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('🐱', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: tt.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'UID: ${cat.uid}',
                                      style: tt.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool highlight;

  const _ValueCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            highlight ? Colors.orange.withOpacity(0.1) : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? Colors.orange : cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: highlight ? Colors.orange : cs.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlight ? Colors.orange : null,
            ),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
