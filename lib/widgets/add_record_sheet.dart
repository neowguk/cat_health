import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cat_record.dart';
import '../providers/cat_provider.dart';

class AddRecordSheet extends StatefulWidget {
  final List<String> catNames;
  final bool inline;
  const AddRecordSheet({super.key, required this.catNames, this.inline = false});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _tempCtrl   = TextEditingController();
  String? _selectedCat;
  bool _saving = false;

  final _defaults = ['나비', '코코', '보리'];

  List<String> get _allCats =>
      {..._defaults, ...widget.catNames}.toList()..sort();

  @override
  void initState() {
    super.initState();
    _selectedCat = widget.catNames.isNotEmpty
        ? widget.catNames.first
        : _defaults.first;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _tempCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final record = CatRecord(
      catName: _selectedCat!,
      weight: double.parse(_weightCtrl.text),
      temperature: double.parse(_tempCtrl.text),
      timestamp: DateTime.now(),
    );
    await context.read<CatProvider>().addRecord(record);
    if (mounted) {
      _weightCtrl.clear();
      _tempCtrl.clear();
      setState(() => _saving = false);
      if (!widget.inline) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${record.catName}: ${record.weight.toStringAsFixed(2)} kg 저장 완료'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, widget.inline ? 8 : 20, 20,
            MediaQuery.of(context).viewInsets.bottom + 32),
        shrinkWrap: true,
        children: [
          if (!widget.inline) ...[
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
          ],
          Text('기록 추가',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('센서 없이도 수동으로 입력할 수 있습니다.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          Text('고양이 선택', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCat,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true, fillColor: cs.surfaceContainerLow,
            ),
            items: _allCats.map((c) =>
                DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCat = v),
            validator: (v) => v == null ? '고양이를 선택해 주세요.' : null,
          ),
          const SizedBox(height: 16),
          Text('체중 (kg)', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '예: 4.62', suffixText: 'kg',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true, fillColor: cs.surfaceContainerLow,
            ),
            validator: (v) {
              final d = double.tryParse(v ?? '');
              if (d == null || d <= 0 || d > 15) return '0.01 ~ 15 사이 숫자를 입력해 주세요.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text('캣타워 온도 (°C)', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tempCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '예: 33.8', suffixText: '°C',
              helperText: '실제 센서 값이 들어오면 같은 구조로 저장됩니다.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true, fillColor: cs.surfaceContainerLow,
            ),
            validator: (v) {
              final d = double.tryParse(v ?? '');
              if (d == null || d < 10 || d > 50) return '10 ~ 50 사이 온도를 입력해 주세요.';
              return null;
            },
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            label: const Text('기록 저장',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
