import 'dart:io';
import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/share_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';
import '../../widgets/banner_ad_widget.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  late Memory _memory;

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;
    AdService.instance.onDetailView();
  }

  Future<void> _refresh() async {
    final updated = await AppDatabase.instance.getMemoryById(_memory.id);
    if (updated != null && mounted) {
      setState(() => _memory = updated);
    }
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, {bool hasImage = false, bool isDelete = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: hasImage ? Colors.black.withValues(alpha: 0.35) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDelete
                ? (hasImage ? Colors.red.shade300 : Colors.red.shade400)
                : (hasImage ? Colors.white : null),
          ),
        ),
      ),
    );
  }

  MemoryCategory get _cat => MemoryCategory.values.firstWhere(
        (c) => c.name == _memory.category,
        orElse: () => MemoryCategory.words,
      );

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _EditMemoryScreen(memory: _memory, category: _cat)),
    );
    if (result == true) await _refresh();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この思い出は元に戻せません'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('削除', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AppDatabase.instance.deleteMemory(_memory.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _memory.mediaPath != null && File(_memory.mediaPath!).existsSync();
    final date = _memory.createdAt;
    final dateStr = '${date.year}年${date.month}月${date.day}日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: hasImage ? Colors.transparent : _cat.color.withValues(alpha: 0.15),
            expandedHeight: hasImage ? 300 : 0,
            pinned: true,
            foregroundColor: hasImage ? Colors.white : null,
            flexibleSpace: hasImage
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_memory.mediaPath!), fit: BoxFit.cover),
                        // グラデーションオーバーレイでボタンの視認性確保
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            actions: [
              _buildActionButton(Icons.edit_rounded, _edit, hasImage: hasImage),
              _buildActionButton(Icons.share_rounded, () => ShareService.instance.shareMemory(_memory), hasImage: hasImage),
              _buildActionButton(Icons.delete_rounded, _delete, hasImage: hasImage, isDelete: true),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + SubType
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _cat.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_cat.icon, color: _cat.color, size: 16),
                            const SizedBox(width: 6),
                            Text(_cat.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _cat.color)),
                          ],
                        ),
                      ),
                      if (_memory.subType.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _cat.color.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _cat.color.withValues(alpha: 0.2)),
                          ),
                          child: Text(_memory.subType, style: TextStyle(fontSize: 12, color: _cat.color)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content
                  if (_memory.content.isNotEmpty)
                    Text(
                      _memory.content,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.7),
                    ),

                  // Amount
                  if (_memory.amount != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: _cat.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.savings_rounded, color: _cat.color, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            '¥${_memory.amount}',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _cat.color),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 広告バナー
                  const SizedBox(height: 32),
                  Center(child: BannerAdWidget(adSize: AdSize.mediumRectangle))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 編集画面
class _EditMemoryScreen extends StatefulWidget {
  final Memory memory;
  final MemoryCategory category;

  const _EditMemoryScreen({required this.memory, required this.category});

  @override
  State<_EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<_EditMemoryScreen> {
  late TextEditingController _contentController;
  late TextEditingController _amountController;
  late String _selectedSubType;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.memory.content);
    _amountController = TextEditingController(text: widget.memory.amount?.toString() ?? '');
    _selectedSubType = widget.memory.subType;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await AppDatabase.instance.updateMemoryFields(
      widget.memory.id,
      content: _contentController.text.trim(),
      subType: _selectedSubType,
      amount: widget.memory.amount != null ? int.tryParse(_amountController.text) : null,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('編集'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cat.color)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // SubType selector
          Text('カテゴリ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cat.subTypes.map((sub) {
              final isSelected = _selectedSubType == sub;
              return GestureDetector(
                onTap: () => setState(() => _selectedSubType = sub),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? cat.color.withValues(alpha: 0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? cat.color : Colors.grey.shade200),
                  ),
                  child: Text(
                    sub,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? cat.color : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Content
          Text('内容', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 6,
            style: const TextStyle(fontSize: 16, height: 1.6),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),

          // Amount (if applicable)
          if (widget.memory.amount != null) ...[
            const SizedBox(height: 24),
            Text('金額', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: '¥ ',
                prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: cat.color),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
