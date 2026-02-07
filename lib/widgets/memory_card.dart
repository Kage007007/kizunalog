import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../models/category.dart';
import '../services/share_service.dart';

class MemoryCard extends StatelessWidget {
  final Memory? memory;

  const MemoryCard({super.key, this.memory});

  @override
  Widget build(BuildContext context) {
    if (memory == null) {
      return _buildEmptyCard(context);
    }
    final cat = MemoryCategory.values.firstWhere(
      (c) => c.name == memory!.category,
      orElse: () => MemoryCategory.words,
    );
    final hasImage = memory!.mediaPath != null && File(memory!.mediaPath!).existsSync();
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cat.color.withValues(alpha: 0.15),
            cat.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cat.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 写真サムネイル（左側）
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(23),
                bottomLeft: Radius.circular(23),
              ),
              child: Image.file(
                File(memory!.mediaPath!),
                width: 120,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120, height: 220,
                  color: cat.color.withValues(alpha: 0.1),
                  child: Icon(Icons.broken_image_rounded, color: cat.color.withValues(alpha: 0.3), size: 32),
                ),
              ),
            ),
          // テキストコンテンツ（右側）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          color: cat.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ShareService.instance.shareMemory(memory!),
                        child: Icon(Icons.share_rounded, size: 16, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(memory!.createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      memory!.content.isEmpty ? '(写真の思い出)' : memory!.content,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (memory!.subType.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        memory!.subType,
                        style: TextStyle(fontSize: 11, color: cat.color),
                      ),
                    ),
                  if (memory!.amount != null)
                    Text(
                      '¥${memory!.amount}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cat.color),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, color: Colors.pink.shade200, size: 40),
          const SizedBox(height: 12),
          Text(
            'まだ思い出がありません',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '下のボタンから記録をはじめましょう',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
