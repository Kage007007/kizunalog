import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:share_plus/share_plus.dart';
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';

class WordRecordScreen extends StatefulWidget {
  const WordRecordScreen({super.key});

  @override
  State<WordRecordScreen> createState() => _WordRecordScreenState();
}

class _WordRecordScreenState extends State<WordRecordScreen> {
  int _step = 0; // 0: subType選択, 1: テキスト入力, 2: 完了
  String? _selectedSubType;
  final _textController = TextEditingController();
  final _category = MemoryCategory.words;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await AppDatabase.instance.insertMemory(
      MemoriesCompanion(
        category: Value(_category.name),
        subType: Value(_selectedSubType ?? ''),
        content: Value(_textController.text.trim()),
      ),
    );
    AdService.instance.onRecordComplete();
    if (mounted) {
      setState(() => _step = 2);
    }
  }

  Future<void> _share() async {
    final text = '${_category.label} - ${_selectedSubType ?? ''}\n${_textController.text.trim()}\n\n#KizunaLog';
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
                  if (_step == 0) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _step = _step - 1);
                  }
                },
              ),
        automaticallyImplyLeading: false,
        title: _step < 2
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                    width: i == _step ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _step
                          ? _category.color
                          : _category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
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

  // Step 0: サブタイプ選択
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
          const Text(
            'どんな言葉？',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'カテゴリを選んでください',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _category.subTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final subType = _category.subTypes[index];
                final isSelected = _selectedSubType == subType;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSubType = subType;
                      _step = 1;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _category.color.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? _category.color
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      subType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? _category.color
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: テキスト入力
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
            decoration: BoxDecoration(
              color: _category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _selectedSubType ?? '',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _category.color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'なんて言った？',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'お子さんの言葉をそのまま記録しましょう',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 18, height: 1.6),
            decoration: InputDecoration(
              hintText: '例：「ママ、おつきさまがついてくるよ」',
              hintStyle: TextStyle(color: Colors.grey.shade300),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _textController.text.trim().isEmpty ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _category.color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'きろくする',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Step 2: 完了演出
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
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _category.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: _category.color,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'きろくできたよ！',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '大切な思い出をありがとう',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
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
              backgroundColor: _category.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'ホームに戻る',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
