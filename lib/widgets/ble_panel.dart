import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../providers/cat_provider.dart';
import '../models/cat_record.dart';

class BlePanel extends StatelessWidget {
  const BlePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ble  = context.watch<BleService>();
    final prov = context.watch<CatProvider>();
    final cs   = Theme.of(context).colorScheme;
    final tt   = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StatusCard(ble: ble),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _ValueCard(label: '실시간 체중',
              value: ble.weight != null
                  ? '${ble.weight!.toStringAsFixed(2)} kg' : '--',
              icon: Icons.monitor_weight_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _ValueCard(label: '실시간 온도',
              value: ble.temperature != null
                  ? '${ble.temperature!.toStringAsFixed(1)} °C' : '--',
              icon: Icons.thermostat_rounded)),
        ]),
        const SizedBox(height: 16),
        Text('센서 데이터 저장',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _SaveSection(ble: ble, prov: prov),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('자동 재연결',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('연결 끊김 시 3초 후 자동 재시도'),
            value: ble.autoReconnect,
            onChanged: ble.setAutoReconnect,
          ),
        ),
        const SizedBox(height: 20),
        Text('BLE 로그',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Text(ble.log,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12,
                  color: cs.onSurfaceVariant)),
        ),
        const SizedBox(height: 20),
        _GuideCard(),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final BleService ble;
  const _StatusCard({required this.ble});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final connected = ble.connected;
    final scanning  = ble.scanState == ScanState.scanning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer.withOpacity(0.4), cs.surface],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(
                color: connected ? Colors.green : scanning ? Colors.orange : Colors.red,
                shape: BoxShape.circle,
              )),
          const SizedBox(width: 8),
          Text(connected ? '연결됨' : scanning ? '스캔 중...' : '연결 안 됨',
              style: tt.labelMedium?.copyWith(
                  color: connected ? cs.primary : cs.error,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Text('캣타워 BLE 센서',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('광고명: CatTower 포함 시 자동 연결',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: scanning ? ble.stopScan : connected ? null : ble.startScan,
            icon: scanning
                ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.bluetooth_searching_rounded),
            label: Text(scanning ? '중지' : '스캔 시작'),
          )),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(
            onPressed: connected ? ble.disconnect : null,
            icon: const Icon(Icons.bluetooth_disabled_rounded),
            label: const Text('연결 해제'),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
          )),
        ]),
      ]),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ValueCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(height: 10),
        Text(value, style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: [const FontFeature.tabularFigures()])),
        Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _SaveSection extends StatefulWidget {
  final BleService ble;
  final CatProvider prov;
  const _SaveSection({required this.ble, required this.prov});

  @override
  State<_SaveSection> createState() => _SaveSectionState();
}

class _SaveSectionState extends State<_SaveSection> {
  String? _selectedCat;
  bool _saving = false;
  final _defaults = ['나비', '코코', '보리'];

  @override
  void initState() {
    super.initState();
    _selectedCat = widget.prov.catNames.isNotEmpty
        ? widget.prov.catNames.first : _defaults.first;
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final ble = widget.ble;
    final allCats = {..._defaults, ...widget.prov.catNames}.toList()..sort();
    final canSave = ble.weight != null && ble.temperature != null && !_saving;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(children: [
        DropdownButtonFormField<String>(
          value: _selectedCat,
          decoration: InputDecoration(
            labelText: '고양이 선택',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true, fillColor: cs.surface,
          ),
          items: allCats.map((c) =>
              DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCat = v),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: canSave ? _save : null,
          icon: _saving
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded),
          label: const Text('센서 데이터 저장',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (!canSave)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('센서를 먼저 연결하면 값이 자동으로 채워집니다.',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
          ),
      ]),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final record = CatRecord(
      catName: _selectedCat!,
      weight: widget.ble.weight!,
      temperature: widget.ble.temperature!,
      timestamp: DateTime.now(),
    );
    await widget.prov.addRecord(record);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${record.catName}: ${record.weight.toStringAsFixed(2)} kg 저장 완료'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _GuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline_rounded, size: 16, color: cs.tertiary),
          const SizedBox(width: 6),
          Text('센서 연동 안내', style: tt.labelMedium?.copyWith(
              color: cs.tertiary, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        ...[
          '1. ESP32 캣타워 센서에서 BLE GATT 서버 실행',
          '2. Service UUID: 4FAFC201-1FB5-459E-8FCC-C5C9C331914B',
          '3. 체중 Char: BEB5483E-... → JSON {"w":4.62} 또는 Float32 LE',
          '4. 온도 Char: BEB5483F-... → JSON {"t":33.8} 또는 Float32 LE',
          '5. 광고 이름에 CatTower 포함 시 앱이 자동으로 연결합니다.',
        ].map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(s, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        )),
      ]),
    );
  }
}
