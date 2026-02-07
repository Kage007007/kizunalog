import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../database/database.dart';
import '../../models/category.dart';
import '../../services/ad_service.dart';
import '../../widgets/sub_type_grid.dart';

class AlbumRecordScreen extends StatefulWidget {
  const AlbumRecordScreen({super.key});

  @override
  State<AlbumRecordScreen> createState() => _AlbumRecordScreenState();
}

class _AlbumRecordScreenState extends State<AlbumRecordScreen> {
  final _category = MemoryCategory.album;
  String _selectedSubType = '';
  final _textController = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedSubType = _category.subTypes.first.label;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1920, imageQuality: 85);
    if (picked != null) setState(() => _imageFile = File(picked.path));
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
    if (_imageFile == null) return;
    final mediaPath = await _saveImageLocally();
    await AppDatabase.instance.insertMemory(
      MemoriesCompanion(
        category: Value(_category.name),
        subType: Value(_selectedSubType),
        content: Value(_textController.text.trim()),
        mediaPath: Value(mediaPath),
      ),
    );
    AdService.instance.onRecordComplete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('きろくできたよ！'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _category.color,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_category.icon, color: _category.color, size: 22),
            const SizedBox(width: 8),
            Text(_category.label),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SubTypeGrid(
                category: _category,
                selectedLabel: _selectedSubType,
                onSelected: (label) => setState(() => _selectedSubType = label),
              ),
              const SizedBox(height: 20),
              if (_imageFile != null)
                GestureDetector(
                  onTap: () => setState(() => _imageFile = null),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(child: _buildImageButton(Icons.camera_alt_rounded, 'カメラ', () => _pickImage(ImageSource.camera))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildImageButton(Icons.photo_library_rounded, 'アルバム', () => _pickImage(ImageSource.gallery))),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLines: 2,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'ひとことメモ（なくてもOK）',
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _imageFile == null ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _category.color, foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('きろくする', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: _category.color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
