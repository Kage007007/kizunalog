import 'package:flutter/material.dart';
import '../database/database.dart';
import '../models/category.dart';
import '../widgets/memory_card.dart';
import '../widgets/category_button.dart';
import '../widgets/banner_ad_widget.dart';
import 'record/word_record_screen.dart';
import 'record/album_record_screen.dart';
import 'record/money_record_screen.dart';
import 'record/question_record_screen.dart';
import 'record/growth_record_screen.dart';
import 'list/memory_list_screen.dart';
import 'list/growth_chart_screen.dart';
import 'settings/settings_screen.dart';
import 'onboarding/onboarding_screen.dart';

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
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    if (await OnboardingScreen.shouldShow()) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
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
    Widget screen;
    switch (category) {
      case MemoryCategory.words:
        screen = const WordRecordScreen();
      case MemoryCategory.album:
        screen = const AlbumRecordScreen();
      case MemoryCategory.money:
        screen = const MoneyRecordScreen();
      case MemoryCategory.questions:
        screen = const QuestionRecordScreen();
      case MemoryCategory.growth:
        screen = const GrowthRecordScreen();
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => _loadRandomMemory());
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
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const MemoryListScreen()))
                            .then((_) => _loadRandomMemory());
                      },
                      child: Container(
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
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.settings_rounded, size: 20, color: Colors.grey.shade500),
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

              const SizedBox(height: 16),

              // Quick access row
              Row(
                children: [
                  _buildQuickLink(
                    icon: Icons.list_rounded,
                    label: '一覧',
                    color: Colors.grey.shade600,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const MemoryListScreen()))
                        .then((_) => _loadRandomMemory()),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickLink(
                    icon: Icons.show_chart_rounded,
                    label: 'グラフ',
                    color: MemoryCategory.growth.color,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GrowthChartScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickLink(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'おさいふ',
                    color: MemoryCategory.money.color,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => MemoryListScreen(filterCategory: MemoryCategory.money)))
                        .then((_) => _loadRandomMemory()),
                  ),
                ],
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

              // 広告枠① バナー広告
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: BannerAdWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLink({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
