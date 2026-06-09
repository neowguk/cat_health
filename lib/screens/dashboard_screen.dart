import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../services/ble_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/weight_chart.dart';
import '../widgets/record_list.dart';
import '../widgets/add_record_sheet.dart';
import '../widgets/health_status_card.dart';
import '../widgets/ble_panel.dart';
import '../services/arduino_service.dart';
import '../widgets/wifi_panel.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatProvider>();
    final ble  = context.watch<BleService>();
    final cs   = Theme.of(context).colorScheme;
    final tt   = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('캣타워 건강 앱',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text('체중 DB + BLE 센서',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: Icon(
              ble.connected
                  ? Icons.bluetooth_connected_rounded
                  : Icons.bluetooth_disabled_rounded,
              color: ble.connected ? cs.primary : cs.error,
            ),
            onPressed: () => setState(() => _tab = 4),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await prov.resetToSample();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('샘플 데이터가 복원되었습니다.')),
                );
              }
            },
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
        index: _tab,
        children: [
          _dashboardPage(prov, cs, tt),
          AddRecordSheet(catNames: prov.catNames, inline: true),
          WeightChart(records: prov.selectedRecords),
          RecordList(records: prov.records),
          const BlePanel(),
          const WifiPanel(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_rounded), label: '대시보드'),
          const NavigationDestination(icon: Icon(Icons.add_chart_rounded), label: '기록'),
          const NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: '추이'),
          const NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: '이력'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: ble.connected,
              label: const Text('ON'),
              child: const Icon(Icons.bluetooth_rounded),
            ),
            label: 'BLE',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: context.watch<ArduinoService>().connected,
              label: const Text('ON'),
              child: const Icon(Icons.wifi_rounded),
            ),
            label: 'WiFi',
          ),
        ],
      ),
      floatingActionButton: _tab != 4
          ? FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => AddRecordSheet(catNames: prov.catNames),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('기록 추가'),
      )
          : null,
    );
  }

  Widget _dashboardPage(CatProvider prov, ColorScheme cs, TextTheme tt) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (prov.catNames.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: prov.catNames.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: prov.selectedCat == cat,
                  onSelected: (_) => prov.selectCat(cat),
                ),
              )).toList(),
            ),
          ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            StatCard(label: '등록 고양이', value: '${prov.catNames.length}마리', icon: Icons.pets_rounded),
            StatCard(label: '최근 평균 체중', value: '${prov.avgWeight7.toStringAsFixed(2)} kg', icon: Icons.monitor_weight_rounded),
            StatCard(label: '오늘 측정 수', value: '${prov.todayCount}회', icon: Icons.today_rounded),
            StatCard(label: '최근 상태', value: prov.healthStatus, icon: Icons.favorite_rounded),
          ],
        ),
        const SizedBox(height: 20),
        HealthStatusCard(prov: prov),
        const SizedBox(height: 20),
        Text('최근 체중 추이', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        WeightChart(records: prov.selectedRecords),
        const SizedBox(height: 20),
        Text('최근 기록', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        RecordList(records: prov.records, compact: true),
      ],
    );
  }
}
