import 'dart:convert';
import 'dart:io';
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
      'app': 'KizunaLog',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'total_records': memories.length,
      'memories': memories.map((m) => {
        'id': m.id,
        'category': m.category,
        'sub_type': m.subType,
        'content': m.content,
        'media_path': m.mediaPath,
        'amount': m.amount,
        'metadata': m.metadata,
        'created_at': m.createdAt.toIso8601String(),
      }).toList(),
    };
  }

  /// JSONファイルとしてエクスポートし、共有シートを表示
  Future<String> exportAndShare() async {
    final data = await _buildExportData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'kizunalog_backup_$timestamp.json'));
    await file.writeAsString(jsonStr);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'KizunaLog バックアップ',
      ),
    );

    return file.path;
  }

  /// 自動バックアップ用: Documentsディレクトリにバックアップを保存
  Future<String> autoBackup() async {
    final data = await _buildExportData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'kizunalog_backup.json'));
    await file.writeAsString(jsonStr);

    return file.path;
  }

  /// バックアップファイルが存在するか確認
  Future<DateTime?> lastBackupDate() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'kizunalog_backup.json'));
    if (await file.exists()) {
      return file.lastModified();
    }
    return null;
  }
}
