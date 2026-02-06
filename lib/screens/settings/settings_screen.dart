import 'package:flutter/material.dart';
import '../../services/backup_service.dart';
import '../../database/database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DateTime? _lastBackup;
  bool _isExporting = false;
  int _memoryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final lastBackup = await BackupService.instance.lastBackupDate();
    final count = await AppDatabase.instance.getMemoryCount();
    if (mounted) {
      setState(() {
        _lastBackup = lastBackup;
        _memoryCount = count;
      });
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      await BackupService.instance.exportAndShare();
      await _loadInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('エクスポートが完了しました'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートに失敗しました: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade400,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _createBackup() async {
    try {
      await BackupService.instance.autoBackup();
      await _loadInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('バックアップを作成しました'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップに失敗しました: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade400,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('せってい'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // データ概要
          _buildSection(
            title: 'データ',
            children: [
              _buildInfoRow(Icons.storage_rounded, '記録数', '$_memoryCount件'),
              _buildInfoRow(
                Icons.backup_rounded,
                '最終バックアップ',
                _lastBackup != null
                    ? '${_lastBackup!.year}/${_lastBackup!.month}/${_lastBackup!.day} ${_lastBackup!.hour}:${_lastBackup!.minute.toString().padLeft(2, '0')}'
                    : 'まだありません',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // バックアップ
          _buildSection(
            title: 'バックアップ',
            children: [
              _buildActionTile(
                icon: Icons.save_rounded,
                iconColor: Colors.blue,
                title: 'バックアップを作成',
                subtitle: 'アプリ内にバックアップファイルを保存します',
                onTap: _createBackup,
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.ios_share_rounded,
                iconColor: Colors.green,
                title: 'すべてのデータをJSONで書き出す',
                subtitle: '他のアプリやPCに送ることができます',
                onTap: _isExporting ? null : _exportData,
                trailing: _isExporting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // アプリ情報
          _buildSection(
            title: 'アプリ情報',
            children: [
              _buildInfoRow(Icons.apps_rounded, 'アプリ名', 'KizunaLog'),
              _buildInfoRow(Icons.tag_rounded, 'バージョン', '1.0.0'),
            ],
          ),
          const SizedBox(height: 20),

          // データポータビリティ説明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue.shade400, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'あなたのデータはすべて端末内に保存されています。いつでもJSON形式で書き出して、他のサービスに移行できます。',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
