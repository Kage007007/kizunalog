import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';

class QuestionRecordScreen extends StatefulWidget {
  const QuestionRecordScreen({super.key});

  @override
  State<QuestionRecordScreen> createState() => _QuestionRecordScreenState();
}

class _QuestionRecordScreenState extends State<QuestionRecordScreen> {
  final _category = MemoryCategory.questions;
  String _selectedSubType = '';
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSubType = _category.subTypes.first;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_textController.text.trim().isEmpty) return;
    await AppDatabase.instance.insertMemory(
      MemoriesCompanion(
        category: Value(_category.name),
        subType: Value(_selectedSubType),
        content: Value(_textController.text.trim()),
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
                        onSelected: (_) => setState(() => _selectedSubType = st),
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
              const SizedBox(height: 20),
              const Text('なんて聞いてきた？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                autofocus: true,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 18, height: 1.6),
                decoration: InputDecoration(
                  hintText: '例：「なんで空は青いの？」',
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _textController.text.trim().isEmpty ? null : _save,
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
