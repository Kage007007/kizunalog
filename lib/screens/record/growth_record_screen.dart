import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';

class GrowthRecordScreen extends StatefulWidget {
  const GrowthRecordScreen({super.key});

  @override
  State<GrowthRecordScreen> createState() => _GrowthRecordScreenState();
}

class _GrowthRecordScreenState extends State<GrowthRecordScreen> {
  final _category = MemoryCategory.growth;
  String _selectedSubType = '';
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSubType = _category.subTypes.first;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  bool get _isNumericType => ['身長', '体重', '靴のサイズ'].contains(_selectedSubType);

  String get _unitLabel {
    switch (_selectedSubType) {
      case '身長': return 'cm';
      case '体重': return 'kg';
      case '靴のサイズ': return 'cm';
      default: return '';
    }
  }

  Future<void> _save() async {
    if (_valueController.text.trim().isEmpty) return;
    final Map<String, dynamic> meta = {};
    if (_isNumericType) {
      meta['value'] = double.tryParse(_valueController.text) ?? 0;
      meta['unit'] = _unitLabel;
    }
    await AppDatabase.instance.insertMemory(
      MemoriesCompanion(
        category: Value(_category.name),
        subType: Value(_selectedSubType),
        content: Value(_isNumericType ? '${_valueController.text}$_unitLabel' : _valueController.text.trim()),
        metadata: Value(jsonEncode(meta)),
      ),
    );
    AdService.instance.onRecordComplete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('きろくできたよ！'),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _category.subTypes.map((st) {
                    final selected = _selectedSubType == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(st),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedSubType = st;
                          _valueController.clear();
                        }),
                        selectedColor: _category.color.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected ? _category.color : Colors.grey.shade600,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(color: selected ? _category.color : Colors.grey.shade200),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isNumericType ? '数値を入力' : 'どんなことができた？',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (_isNumericType)
                TextField(
                  controller: _valueController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: _unitLabel,
                    suffixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _category.color),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                )
              else
                TextField(
                  controller: _valueController,
                  autofocus: true,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 18, height: 1.6),
                  decoration: InputDecoration(
                    hintText: '例：「自転車に乗れた！」',
                    hintStyle: TextStyle(color: Colors.grey.shade300),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _valueController.text.trim().isEmpty ? null : _save,
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
