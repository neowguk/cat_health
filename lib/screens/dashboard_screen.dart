import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/weight_chart.dart';
import '../widgets/record_list.dart';
import '../widgets/health_status_card.dart';

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
      context.read<MqttService>().resetLiveState();

      context.read<MqttService>().onNewTag = (String uid) {
        if (!mounted) return;
        final prov = context.read<CatProvider>();
        final mqtt = context.read<MqttService>();
        final existing = prov.catNameByTag(uid);

        if (existing != null) {
          mqtt.ignoreHeater = false;
          prov.selectCat(existing);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🐱 $existing 감지됨'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          mqtt.ignoreHeater = true;
          _showRegisterDialog(uid);
        }
      };
    });
  }

  void _showRegisterDialog(String uid) {
    final controller = TextEditingController();
    final prov = context.read<CatProvider>();
    final mqtt = context.read<MqttService>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.pets_rounded),
              SizedBox(width: 8),
              Text('새 고양이 등록'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'UID: $uid',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (prov.catNames.isNotEmpty) ...[
                  Text(
                    '기존 고양이에 연결',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: prov.catNames
                        .map(
                          (name) => ActionChip(
                            label: Text(name),
                            avatar: const Icon(Icons.pets_rounded, size: 16),
                            onPressed: () async {
                              await prov.registerTag(uid, name);
                              prov.selectCat(name);
                              mqtt.ignoreHeater = false;
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name 에 태그 연결 완료'),
                                  ),
                                );
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                ],
                Text(
                  prov.catNames.isEmpty ? '고양이 이름을 입력하세요' : '또는 새 고양이 이름 입력',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: prov.catNames.isEmpty,
                  decoration: const InputDecoration(
                    labelText: '고양이 이름',
                    hintText: '예: 나비, 보리, 코코',
                    prefixIcon: Icon(Icons.pets_rounded),
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                await prov.registerTag(uid, name);
                await prov.addCatIfNotExists(name, mqtt.weight);
                prov.selectCat(name);
                mqtt.ignoreHeater = false;

                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🐱 $name 등록 완료'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCatManageSheet(
    CatProvider prov,
    ColorScheme cs,
    TextTheme tt,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.pets_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    '고양이 관리',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${prov.catNames.length}마리',
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: prov.catNames.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets_rounded,
                              size: 48, color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            '등록된 고양이가 없습니다',
                            style: tt.bodyMedium?.copyWith(color: cs.outline),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'RFID 태그를 찍어 등록하세요',
                            style: tt.bodySmall?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      itemCount: prov.catNames.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final name = prov.catNames[i];
                        final tagCount =
                            prov.tagMap.values.where((v) => v == name).length;
                        final recordCount =
                            prov.records.where((r) => r.catName == name).length;

                        return Card(
                          elevation: 0,
                          color: prov.selectedCat == name
                              ? cs.primaryContainer.withOpacity(0.4)
                              : cs.surfaceContainerHighest,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Icon(Icons.pets_rounded,
                                  color: cs.primary, size: 20),
                            ),
                            title: Text(
                              name,
                              style: tt.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '기록 $recordCount건 · 태그 $tagCount개',
                              style: tt.bodySmall?.copyWith(color: cs.outline),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_rounded,
                                      color: cs.primary, size: 20),
                                  tooltip: '이름 수정',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showRenameDialog(name, prov, cs, tt);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: cs.error, size: 20),
                                  tooltip: '삭제',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showDeleteConfirmDialog(
                                        name, recordCount, prov, cs, tt);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    String currentName,
    CatProvider prov,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_rounded),
            SizedBox(width: 8),
            Text('이름 수정'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '새 이름',
            prefixIcon: Icon(Icons.pets_rounded),
          ),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == currentName) {
                Navigator.pop(ctx);
                return;
              }
              if (prov.catNames.contains(newName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$newName 은 이미 존재하는 이름입니다'),
                    backgroundColor: cs.error,
                  ),
                );
                return;
              }

              await prov.renameCat(currentName, newName);
              Navigator.pop(ctx);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$currentName → $newName 변경 완료'),
                  ),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    String catName,
    int recordCount,
    CatProvider prov,
    ColorScheme cs,
    TextTheme tt,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: cs.error),
            const SizedBox(width: 8),
            const Text('고양이 삭제'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                children: [
                  TextSpan(
                    text: catName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' 을(를) 삭제합니다.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '체중 기록 $recordCount건과 연결된 태그가 모두 삭제됩니다.',
                      style: tt.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () async {
              await prov.deleteCat(catName);
              Navigator.pop(ctx);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$catName 삭제 완료'),
                    backgroundColor: cs.error,
                  ),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatProvider>();
    final mqtt = context.watch<MqttService>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Row(
          children: [
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
            Text(
              '집사의 눈',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded),
            tooltip: '고양이 관리',
            onPressed: () => _showCatManageSheet(prov, cs, tt),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await prov.resetToSample();
              context.read<MqttService>().resetLiveState();
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
                _dashboardPage(prov, mqtt, cs, tt),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: RecordList(records: prov.records),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: '대시보드',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            label: '이력',
          ),
        ],
      ),
    );
  }

  Widget _dashboardPage(
    CatProvider prov,
    MqttService mqtt,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
      children: [
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
              icon: Icons.pets_rounded,
            ),
            StatCard(
              label: '온열 패드',
              value: mqtt.heater ? '🔥 ON' : 'OFF',
              icon: Icons.local_fire_department_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 44,
          child: prov.catNames.isEmpty
              ? Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: cs.outline),
                    const SizedBox(width: 6),
                    Text(
                      'RFID 태그를 찍어 고양이를 등록하세요',
                      style: tt.bodySmall?.copyWith(color: cs.outline),
                    ),
                  ],
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: prov.catNames
                      .map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: prov.selectedCat == cat,
                            onSelected: (_) => prov.selectCat(cat),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 8),
        _liveStatusCard(prov, mqtt, cs, tt),
        const SizedBox(height: 20),
        _heaterControlCard(mqtt, cs, tt),
        const SizedBox(height: 20),
        HealthStatusCard(prov: prov),
        const SizedBox(height: 20),
        Text(
          '최근 체중 추이',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        WeightChart(records: prov.selectedRecords),
        const SizedBox(height: 20),
        Text(
          '최근 기록',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        RecordList(records: prov.records, compact: true),
      ],
    );
  }

  Widget _heaterControlCard(
    MqttService mqtt,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final isConnected = mqtt.connectionStatus == 'connected';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: mqtt.heater
                    ? cs.errorContainer.withOpacity(0.7)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: mqtt.heater ? cs.error : cs.outline,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '온열 패드 직접 제어',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected
                        ? '스위치로 ON / OFF를 바꿀 수 있어요'
                        : 'MQTT 연결 후 제어할 수 있어요',
                    style: tt.bodySmall?.copyWith(
                      color: isConnected ? cs.outline : cs.error,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: mqtt.heater,
              onChanged: isConnected
                  ? (value) async {
                      await mqtt.setHeater(value);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveStatusCard(
    CatProvider prov,
    MqttService mqtt,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final catName = mqtt.lastRfid.isNotEmpty
        ? (prov.catNameByTag(mqtt.lastRfid) ?? mqtt.lastCatName)
        : null;
    final isConnected = mqtt.connectionStatus == 'connected';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.sensors_rounded,
                    size: 20,
                    color: isConnected ? cs.primary : cs.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '실시간 현황',
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      isConnected ? '연결됨' : mqtt.connectionStatus,
                      style: tt.bodySmall?.copyWith(
                        color: isConnected ? cs.primary : cs.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            if (catName != null && catName.isNotEmpty) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: cs.primaryContainer,
                    child:
                        Icon(Icons.pets_rounded, color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catName,
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          Icon(Icons.nfc_rounded, size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(
                            'RFID 감지됨',
                            style: tt.bodySmall?.copyWith(color: cs.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.nfc_rounded, size: 18, color: cs.outline),
                  const SizedBox(width: 8),
                  Text(
                    'RFID 태그를 찍으면 고양이가 표시됩니다',
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monitor_weight_rounded,
                                size: 16, color: cs.outline),
                            const SizedBox(width: 6),
                            Text(
                              '체중',
                              style: tt.bodySmall?.copyWith(color: cs.outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${mqtt.weight.toStringAsFixed(2)} kg',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: mqtt.heater
                          ? cs.errorContainer.withOpacity(0.5)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: mqtt.heater ? cs.error : cs.outline,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '온열 패드',
                              style: tt.bodySmall?.copyWith(
                                color: mqtt.heater ? cs.error : cs.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mqtt.heater ? '🔥 ON' : 'OFF',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: mqtt.heater ? cs.error : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
