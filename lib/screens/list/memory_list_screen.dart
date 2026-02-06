import 'dart:io';
import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../models/category.dart';

class MemoryListScreen extends StatelessWidget {
  final MemoryCategory? filterCategory;

  const MemoryListScreen({super.key, this.filterCategory});

  @override
  Widget build(BuildContext context) {
    final stream = filterCategory != null
        ? AppDatabase.instance.watchMemoriesByCategory(filterCategory!.name)
        : AppDatabase.instance.watchAllMemories();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(filterCategory?.label ?? 'すべての思い出'),
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
