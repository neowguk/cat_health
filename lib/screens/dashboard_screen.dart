import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../services/ble_service.dart';
import '../services/arduino_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/weight_chart.dart';
import '../widgets/record_list.dart';
import '../widgets/health_status_card.dart';
import '../widgets/ble_panel.dart';
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
    final ble = context.watch<BleService>();
    final arduino = context.watch<ArduinoService>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Row(children: [
          Container(
            width: 42,
            height: 42,
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
            Text('집사의 눈',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
            onPressed: () => setState(() => _tab = 3),
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
                // 0: 대시보드
                _dashboardPage(prov, arduino, cs, tt),
                // 1: 이력
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: RecordList(records: prov.records),
                ),
                // 2: BLE
                const BlePanel(),
                // 3: WiFi
                const WifiPanel(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_rounded), label: '대시보드'),
          const NavigationDestination(
              icon: Icon(Icons.list_alt_rounded), label: '이력'),
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
              isLabelVisible: arduino.connected,
              label: const Text('ON'),
              child: const Icon(Icons.wifi_rounded),
            ),
            label: 'WiFi',
          ),
        ],
      ),
    );
  }

  Widget _dashboardPage(
      CatProvider prov, ArduinoService arduino, ColorScheme cs, TextTheme tt) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
      children: [
        // 1. 통계 카드
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            StatCard(
                label: '등록 고양이',
                value: '${prov.catNames.length}마리',
                icon: Icons.pets_rounded),
            StatCard(
                label: '최근 평균 체중',
                value: '${prov.avgWeight7.toStringAsFixed(2)} kg',
                icon: Icons.monitor_weight_rounded),
            StatCard(
                label: '오늘 측정 수',
                value: '${prov.todayCount}회',
                icon: Icons.today_rounded),
            StatCard(
              label: '온열 패드',
              value: arduino.status.heating ? '🔥 ON' : 'OFF',
              icon: Icons.local_fire_department_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. 고양이 선택 칩
        if (prov.catNames.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: prov.catNames
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: prov.selectedCat == cat,
                          onSelected: (_) => prov.selectCat(cat),
                        ),
                      ))
                  .toList(),
            ),
          ),
        const SizedBox(height: 8),

        // 3. 실시간 상태 카드
        HealthStatusCard(prov: prov),
        const SizedBox(height: 20),

        // 4. 체중 추이
        Text('최근 체중 추이',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        WeightChart(records: prov.selectedRecords),
        const SizedBox(height: 20),

        // 5. 최근 기록
        Text('최근 기록',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        RecordList(records: prov.records, compact: true),
      ],
    );
  }
}
