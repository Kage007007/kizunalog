import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../database/database.dart';

class BackupService {
  static final BackupService _instance = BackupService._();
  static BackupService get instance => _instance;
  BackupService._();

  Future<Map<String, dynamic>> _buildExportData() async {
    final memories = await AppDatabase.instance.getAllMemories();
    return {
      'app': 'おもいでノート',
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'total_records': memories.length,
      'memories': memories.map((m) {
        String? relativeMediaPath;
        if (m.mediaPath != null) {
          relativeMediaPath = 'photos/${p.basename(m.mediaPath!)}';
        }
        return {
          'id': m.id,
          'category': m.category,
          'sub_type': m.subType,
          'content': m.content,
          'media_path': relativeMediaPath,
          'amount': m.amount,
          'metadata': m.metadata,
          'created_at': m.createdAt.toIso8601String(),
        };
      }).toList(),
    };
  }

  /// ZIP形式でエクスポート（JSON + 写真）し、共有シートを表示
  Future<String> exportAndShare() async {
    final data = await _buildExportData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final memories = await AppDatabase.instance.getAllMemories();

    final archive = Archive();

    // JSONを追加
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('kizunalog_data.json', jsonBytes.length, jsonBytes));

    // 写真を追加
    for (final m in memories) {
      if (m.mediaPath != null) {
        try {
          final file = File(m.mediaPath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final fileName = 'photos/${p.basename(m.mediaPath!)}';
            archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          }
        } catch (_) {
          // 読み取り失敗した写真はスキップ
        }
      }
    }

    // ZIPエンコード
    final zipData = ZipEncoder().encode(archive);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = File(p.join(dir.path, 'kizunalog_backup_$timestamp.zip'));
    await zipFile.writeAsBytes(zipData);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zipFile.path)],
        subject: 'おもいでノート バックアップ',
      ),
    );

    return zipFile.path;
  }

  /// 自動バックアップ用: Documentsディレクトリにバックアップを保存
  Future<String> autoBackup() async {
    final data = await _buildExportData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final memories = await AppDatabase.instance.getAllMemories();

    final archive = Archive();

    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('kizunalog_data.json', jsonBytes.length, jsonBytes));

    for (final m in memories) {
      if (m.mediaPath != null) {
        try {
          final file = File(m.mediaPath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final fileName = 'photos/${p.basename(m.mediaPath!)}';
            archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          }
        } catch (_) {
          // 読み取り失敗した写真はスキップ
        }
      }
    }

    final zipData = ZipEncoder().encode(archive);

    final dir = await getApplicationDocumentsDirectory();
    final zipFile = File(p.join(dir.path, 'kizunalog_backup.zip'));
    await zipFile.writeAsBytes(zipData);

    return zipFile.path;
  }

  /// バックアップファイルが存在するか確認
  Future<DateTime?> lastBackupDate() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'kizunalog_backup.zip'));
    if (await file.exists()) {
      return file.lastModified();
    }
    // 旧形式のJSONバックアップもチェック
    final jsonFile = File(p.join(dir.path, 'kizunalog_backup.json'));
    if (await jsonFile.exists()) {
      return jsonFile.lastModified();
    }
    return null;
  }
}
