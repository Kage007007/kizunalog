import 'package:flutter/material.dart';
import '../database/database.dart';
import '../models/category.dart';
import '../widgets/memory_card.dart';
import '../widgets/category_button.dart';
import 'record/word_record_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Memory? _randomMemory;
  int _memoryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRandomMemory();
  }

  Future<void> _loadRandomMemory() async {
    final memory = await AppDatabase.instance.getRandomMemory();
    final count = await AppDatabase.instance.getMemoryCount();
    if (mounted) {
      setState(() {
        _randomMemory = memory;
        _memoryCount = count;
      });
    }
  }

  void _onCategoryTap(MemoryCategory category) {
    switch (category) {
      case MemoryCategory.words:
        Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (_) => const WordRecordScreen(),
            ))
            .then((_) => _loadRandomMemory());
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.label}は次のフェーズで実装予定です'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  const Text(
                    'KizunaLog',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (_memoryCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_memoryCount件の思い出',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink.shade300,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Memory Card
              GestureDetector(
                onTap: _loadRandomMemory,
                child: MemoryCard(memory: _randomMemory),
              ),

              const Spacer(),

              // Category Grid
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'きろくする',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(
                height: 240,
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: MemoryCategory.values.map((cat) {
                    return CategoryButton(
                      category: cat,
                      onTap: () => _onCategoryTap(cat),
                    );
                  }).toList(),
                ),
              ),

              // 広告枠①のスペース（Phase 3で実装）
              Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'AD',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
