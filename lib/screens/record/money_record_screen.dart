import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';
import '../../widgets/sub_type_grid.dart';

class MoneyRecordScreen extends StatefulWidget {
  const MoneyRecordScreen({super.key});

  @override
  State<MoneyRecordScreen> createState() => _MoneyRecordScreenState();
}

class _MoneyRecordScreenState extends State<MoneyRecordScreen> {
  final _category = MemoryCategory.money;
  String _selectedSubType = '';
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSubType = _category.subTypes.first.label;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount == 0) return;
    await AppDatabase.instance.insertMemory(
      MemoriesCompanion(
        category: Value(_category.name),
        subType: Value(_selectedSubType),
        content: Value(_memoController.text.trim()),
        amount: Value(amount),
      ),
    );
    AdService.instance.onRecordComplete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¥${_amountController.text} きろくしたよ！'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _category.color,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_category.icon, color: _category.color, size: 22),
            const SizedBox(width: 8),
            Text(_category.label),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SubTypeGrid(
                category: _category,
                selectedLabel: _selectedSubType,
                onSelected: (label) => setState(() => _selectedSubType = label),
              ),
              const SizedBox(height: 24),
              const Text('いくら？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '¥ ',
                  prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _category.color),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                maxLines: 2,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'メモ（おじいちゃんから等）',
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _amountController.text.isEmpty ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _category.color, foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('きろくする', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
