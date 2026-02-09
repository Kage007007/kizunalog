import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:share_plus/share_plus.dart';
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';

class GrowthRecordScreen extends StatefulWidget {
  const GrowthRecordScreen({super.key});

  @override
  State<GrowthRecordScreen> createState() => _GrowthRecordScreenState();
}

class _GrowthRecordScreenState extends State<GrowthRecordScreen> {
  int _step = 0;
  String? _selectedSubType;
  final _valueController = TextEditingController();
  final _memoController = TextEditingController();
  final _category = MemoryCategory.growth;

  @override
  void dispose() {
    _valueController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  String get _unitLabel {
    switch (_selectedSubType) {
      case '身長': return 'cm';
      case '体重': return 'kg';
      case '靴のサイズ': return 'cm';
      default: return '';
    }
  }

  bool get _isNumericType => ['身長', '体重', '靴のサイズ'].contains(_selectedSubType);

  Future<void> _save() async {
    final Map<String, dynamic> meta = {};
    if (_isNumericType) {
      meta['value'] = double.tryParse(_valueController.text) ?? 0;
      meta['unit'] = _unitLabel;
    }
    await AppDatabase.instance.insertMemory(
      MemoriesCompanion(
        category: Value(_category.name),
        subType: Value(_selectedSubType ?? ''),
        content: Value(_isNumericType ? '${_valueController.text}$_unitLabel' : _valueController.text.trim()),
        metadata: Value(jsonEncode(meta)),
      ),
    );
    AdService.instance.onRecordComplete();
    if (mounted) setState(() => _step = 2);
  }

  Future<void> _share() async {
    final content = _isNumericType ? '${_valueController.text}$_unitLabel' : _valueController.text.trim();
    final text = '${_category.label} - ${_selectedSubType ?? ''}\n$content\n\n#こども思い出ノート';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _step == 2
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  if (_step == 0) Navigator.of(context).pop();
                  else setState(() => _step = _step - 1);
                },
              ),
        automaticallyImplyLeading: false,
        title: _step < 2
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Container(
                  width: i == _step ? 24 : 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _step ? _category.color : _category.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_step) {
            0 => _buildStepSubType(),
            1 => _buildStepInput(),
            2 => _buildStepComplete(),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildStepSubType() {
    return Padding(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(_category.icon, color: _category.color, size: 40),
          const SizedBox(height: 16),
          const Text('なにが成長した？', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('記録タイプを選んでください', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _category.subTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final subType = _category.subTypes[index];
                return GestureDetector(
                  onTap: () => setState(() { _selectedSubType = subType; _step = 1; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(subType, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepInput() {
    return Padding(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _category.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_selectedSubType ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _category.color)),
          ),
          const SizedBox(height: 16),
          Text(
            _isNumericType ? '数値を入力' : 'どんなことができた？',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
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
    );
  }

  Widget _buildStepComplete() {
    return Center(
      key: const ValueKey('step2'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: _category.color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.emoji_events_rounded, color: _category.color, size: 48),
            ),
          ),
          const SizedBox(height: 24),
          const Text('きろくできたよ！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('すくすく成長してるね', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 48),
          OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share_rounded),
            label: const Text('シェアする', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _category.color,
              side: BorderSide(color: _category.color),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _category.color, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('ホームに戻る', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
