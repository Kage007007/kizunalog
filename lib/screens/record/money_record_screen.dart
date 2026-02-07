import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';
import '../../widgets/record_bottom_sheet.dart';

class MoneyRecordSheet extends StatefulWidget {
  const MoneyRecordSheet({super.key});

  @override
  State<MoneyRecordSheet> createState() => _MoneyRecordSheetState();
}

class _MoneyRecordSheetState extends State<MoneyRecordSheet> {
  int _step = 0;
  String? _selectedSubType;
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _category = MemoryCategory.money;

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    await AppDatabase.instance.insertMemory(
      MemoriesCompanion(
        category: Value(_category.name),
        subType: Value(_selectedSubType ?? ''),
        content: Value(_memoController.text.trim()),
        amount: Value(amount),
      ),
    );
    AdService.instance.onRecordComplete();
    if (mounted) setState(() => _step = 2);
  }

  void _close() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step = _step - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecordSheetScaffold(
      category: _category,
      currentStep: _step,
      totalSteps: 3,
      showClose: _step < 2,
      onClose: _close,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          0 => _buildStepSubType(),
          1 => _buildStepAmount(),
          2 => _buildStepComplete(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildStepSubType() {
    return Padding(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Icon(_category.icon, color: _category.color, size: 36),
          const SizedBox(height: 12),
          const Text('なんのお金？', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          ...List.generate(_category.subTypes.length, (index) {
            final subType = _category.subTypes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() { _selectedSubType = subType; _step = 1; }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: Text(subType, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStepAmount() {
    return Padding(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _category.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_selectedSubType ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _category.color)),
          ),
          const SizedBox(height: 12),
          const Text('いくらもらった？', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController, autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: '¥ ', prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _category.color),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoController, maxLines: 2,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(hintText: 'メモ（おじいちゃんから等）', hintStyle: TextStyle(color: Colors.grey.shade300),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _amountController.text.isEmpty ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: _category.color, foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('きろくする', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildStepComplete() {
    return Padding(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 600), curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(width: 80, height: 80,
              decoration: BoxDecoration(color: _category.color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.savings_rounded, color: _category.color, size: 40))),
          const SizedBox(height: 20),
          const Text('きろくできたよ！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('¥${_amountController.text}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _category.color)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: _category.color, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('とじる', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        ],
      ),
    );
  }
}
