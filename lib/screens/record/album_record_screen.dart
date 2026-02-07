import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';
import '../../widgets/record_bottom_sheet.dart';

class AlbumRecordSheet extends StatefulWidget {
  const AlbumRecordSheet({super.key});

  @override
  State<AlbumRecordSheet> createState() => _AlbumRecordSheetState();
}

class _AlbumRecordSheetState extends State<AlbumRecordSheet> {
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
      setState(() { _imageFile = File(picked.path); _step = 2; });
    }
  }

  Future<String?> _saveImageLocally() async {
    if (_imageFile == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final albumDir = Directory(p.join(dir.path, 'albums'));
    if (!await albumDir.exists()) await albumDir.create(recursive: true);
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

  void _close() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step = _step - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecordSheetScaffold(
      category: _category,
      currentStep: _step,
      totalSteps: 4,
      showClose: _step < 3,
      onClose: _close,
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
    );
  }

  Widget _buildStepSubType() {
    return Padding(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Icon(_category.icon, color: _category.color, size: 36),
          const SizedBox(height: 12),
          const Text('どんな写真？', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          ...List.generate(_category.subTypes.length, (index) {
            final subType = _category.subTypes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() { _selectedSubType = subType; _step = 1; }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: Text(subType, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('写真を選ぼう', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _category.color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Column(children: [
                Icon(Icons.camera_alt_rounded, color: _category.color, size: 36),
                const SizedBox(height: 6),
                Text('カメラで撮る', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _category.color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Column(children: [
                Icon(Icons.photo_library_rounded, color: _category.color, size: 36),
                const SizedBox(height: 6),
                Text('アルバムから選ぶ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepCaption() {
    return Padding(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          if (_imageFile != null)
            ClipRRect(borderRadius: BorderRadius.circular(16),
              child: Image.file(_imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 12),
          const Text('ひとことメモ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _textController, maxLines: 2,
            style: const TextStyle(fontSize: 16, height: 1.5),
            decoration: InputDecoration(hintText: '（なくてもOK）', hintStyle: TextStyle(color: Colors.grey.shade300),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 56,
            child: ElevatedButton(onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: _category.color, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('きろくする', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildStepComplete() {
    return Padding(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 600), curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(width: 80, height: 80,
              decoration: BoxDecoration(color: _category.color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.photo_rounded, color: _category.color, size: 40))),
          const SizedBox(height: 20),
          const Text('きろくできたよ！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('すてきな写真をありがとう', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: _category.color, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('とじる', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        ],
      ),
    );
  }
}
