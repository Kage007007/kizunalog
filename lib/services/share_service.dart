import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../database/database.dart';
import '../models/category.dart';

class ShareService {
  static final ShareService instance = ShareService._();
  ShareService._();

  String _formatMemory(Memory memory) {
    final cat = MemoryCategory.values.firstWhere(
      (c) => c.name == memory.category,
      orElse: () => MemoryCategory.words,
    );
    final date = '${memory.createdAt.year}/${memory.createdAt.month}/${memory.createdAt.day}';
    final buf = StringBuffer();

    buf.writeln('${cat.label}${memory.subType.isNotEmpty ? ' - ${memory.subType}' : ''}');
    buf.writeln(date);

    if (memory.content.isNotEmpty) {
      buf.writeln(memory.content);
    }
    if (memory.amount != null) {
      buf.writeln('¥${memory.amount}');
    }

    return buf.toString().trimRight();
  }

  /// 個別の思い出をシェア
  Future<void> shareMemory(Memory memory) async {
    final text = '${_formatMemory(memory)}\n\n#こども思い出ノート';
    final List<XFile> files = [];

    if (memory.mediaPath != null && File(memory.mediaPath!).existsSync()) {
      files.add(XFile(memory.mediaPath!));
    }

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: files.isEmpty ? null : files,
      ),
    );
  }

  /// 複数の思い出をまとめてシェア
  Future<void> shareMemories(List<Memory> memories) async {
    if (memories.isEmpty) return;

    final buf = StringBuffer();
    buf.writeln('こども思い出ノート - ${memories.length}件の思い出');
    buf.writeln('${'─' * 20}');

    final List<XFile> files = [];

    for (final memory in memories) {
      buf.writeln();
      buf.writeln(_formatMemory(memory));

      if (memory.mediaPath != null && File(memory.mediaPath!).existsSync()) {
        files.add(XFile(memory.mediaPath!));
      }
    }

    buf.writeln();
    buf.writeln('#こども思い出ノート');

    await SharePlus.instance.share(
      ShareParams(
        text: buf.toString(),
        files: files.isEmpty ? null : files,
      ),
    );
  }
}
