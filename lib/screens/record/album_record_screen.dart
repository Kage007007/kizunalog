import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';

class AlbumRecordScreen extends StatefulWidget {
  const AlbumRecordScreen({super.key});

  @override
  State<AlbumRecordScreen> createState() => _AlbumRecordScreenState();
}

class _AlbumRecordScreenState extends State<AlbumRecordScreen> {
  int _step = 0;
  String? _selectedSubType;
  final _textController = TextEditingController();
  final _category = MemoryCategory.album;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1920, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _step = 2;
      });
    }
  }

  Future<String?> _saveImageLocally() async {
    if (_imageFile == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final albumDir = Directory(p.join(dir.path, 'albums'));
    if (!await albumDir.exists()) {
      await albumDir.create(recursive: true);
    }
    final ext = p.extension(_imageFile!.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final saved = await _imageFile!.copy(p.join(albumDir.path, fileName));
    return saved.path;
  }

  Future<void> _save() async {
    final mediaPath = await _saveImageLocally();
    await AppDatabase.instance.insertMemory(
      MemoriesCompanion(
        category: Value(_category.name),
        subType: Value(_selectedSubType ?? ''),
        content: Value(_textController.text.trim()),
        mediaPath: Value(mediaPath),
      ),
    );
    AdService.instance.onRecordComplete();
    if (mounted) setState(() => _step = 3);
  }

  Future<void> _share() async {
    final List<XFile> files = [];
    if (_imageFile != null && _imageFile!.existsSync()) {
      files.add(XFile(_imageFile!.path));
    }
    final text = '${_category.label} - ${_selectedSubType ?? ''}${_textController.text.trim().isNotEmpty ? '\n${_textController.text.trim()}' : ''}\n\n#KizunaLog';
    await SharePlus.instance.share(ShareParams(text: text, files: files.isEmpty ? null : files));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _step == 3
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
        title: _step < 3
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (i) {
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
            1 => _buildStepPickImage(),
            2 => _buildStepCaption(),
            3 => _buildStepComplete(),
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
          const Text('どんな写真？', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('カテゴリを選んでください', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _category.subTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final subType = _category.subTypes[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSubType = subType;
                      _step = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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

  Widget _buildStepPickImage() {
    return Padding(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('写真を選ぼう', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('カメラで撮るか、アルバムから選んでください', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 48),
          _buildImageSourceButton(
            icon: Icons.camera_alt_rounded,
            label: 'カメラで撮る',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 16),
          _buildImageSourceButton(
            icon: Icons.photo_library_rounded,
            label: 'アルバムから選ぶ',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _category.color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: _category.color, size: 40),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCaption() {
    return Padding(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          const Text('ひとことメモ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 3,
            style: const TextStyle(fontSize: 16, height: 1.5),
            decoration: InputDecoration(
              hintText: '（なくてもOK）',
              hintStyle: TextStyle(color: Colors.grey.shade300),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _category.color,
                foregroundColor: Colors.white,
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
      key: const ValueKey('step3'),
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
              child: Icon(Icons.photo_rounded, color: _category.color, size: 48),
            ),
          ),
          const SizedBox(height: 24),
          const Text('きろくできたよ！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('すてきな写真をありがとう', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
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
