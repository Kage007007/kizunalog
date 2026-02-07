import 'dart:io';
import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/share_service.dart';

class MemoryListScreen extends StatefulWidget {
  final MemoryCategory? filterCategory;

  const MemoryListScreen({super.key, this.filterCategory});

  @override
  State<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends State<MemoryListScreen> {
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _shareSelected(List<Memory> allItems) async {
    final selected = allItems.where((m) => _selectedIds.contains(m.id)).toList();
    if (selected.isEmpty) return;
    await ShareService.instance.shareMemories(selected);
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.filterCategory != null
        ? AppDatabase.instance.watchMemoriesByCategory(widget.filterCategory!.name)
        : AppDatabase.instance.watchAllMemories();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _selectMode
              ? '${_selectedIds.length}件選択中'
              : widget.filterCategory?.label ?? 'すべての思い出',
        ),
        actions: [
          if (_selectMode)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _toggleSelectMode,
            )
          else
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              onPressed: _toggleSelectMode,
              tooltip: 'まとめてシェア',
            ),
        ],
      ),
      body: StreamBuilder<List<Memory>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('まだ記録がありません', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
                ],
              ),
            );
          }
          final items = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final memory = items[index];
              final cat = MemoryCategory.values.firstWhere(
                (c) => c.name == memory.category,
                orElse: () => MemoryCategory.words,
              );
              final isSelected = _selectedIds.contains(memory.id);

              if (_selectMode) {
                return GestureDetector(
                  onTap: () => _toggleSelection(memory.id),
                  child: _buildMemoryTile(memory, cat, isSelected: isSelected),
                );
              }

              return Dismissible(
                key: Key(memory.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
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
                },
                onDismissed: (_) => AppDatabase.instance.deleteMemory(memory.id),
                child: _buildMemoryTile(memory, cat),
              );
            },
          );
        },
      ),
      floatingActionButton: _selectMode && _selectedIds.isNotEmpty
          ? StreamBuilder<List<Memory>>(
              stream: stream,
              builder: (context, snapshot) {
                return FloatingActionButton.extended(
                  onPressed: snapshot.hasData ? () => _shareSelected(snapshot.data!) : null,
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.share_rounded),
                  label: Text('${_selectedIds.length}件をシェア'),
                );
              },
            )
          : null,
    );
  }

  Widget _buildMemoryTile(Memory memory, MemoryCategory cat, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? cat.color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: cat.color, width: 1.5) : null,
        boxShadow: isSelected
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectMode)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? cat.color : Colors.grey.shade300,
                size: 24,
              ),
            ),
          if (memory.mediaPath != null && File(memory.mediaPath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(memory.mediaPath!), width: 60, height: 60, fit: BoxFit.cover),
            )
          else
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (memory.subType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(memory.subType, style: TextStyle(fontSize: 11, color: cat.color, fontWeight: FontWeight.w600)),
                      ),
                    const Spacer(),
                    Text(
                      '${memory.createdAt.month}/${memory.createdAt.day}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (memory.content.isNotEmpty)
                  Text(
                    memory.content,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (memory.amount != null)
                  Text(
                    '¥${memory.amount}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cat.color),
                  ),
              ],
            ),
          ),
          if (!_selectMode)
            GestureDetector(
              onTap: () => ShareService.instance.shareMemory(memory),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.share_rounded, size: 18, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }
}
