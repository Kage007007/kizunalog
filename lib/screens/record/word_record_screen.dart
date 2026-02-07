import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';
import '../../widgets/sub_type_grid.dart';

class WordRecordScreen extends StatefulWidget {
  const WordRecordScreen({super.key});

  @override
  State<WordRecordScreen> createState() => _WordRecordScreenState();
}

class _WordRecordScreenState extends State<WordRecordScreen> {
  final _category = MemoryCategory.words;
  String _selectedSubType = '';
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSubType = _category.subTypes.first.label;
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
              const SizedBox(height: 20),
              const Text('なんて言った？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 18, height: 1.6),
                decoration: InputDecoration(
                  hintText: '例：「ママ、おつきさまがついてくるよ」',
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
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
