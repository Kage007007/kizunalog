import 'dart:async';
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
import 'detail/memory_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Memory> _recentMemories = [];
  int _memoryCount = 0;
  final PageController _pageController = PageController();
  Timer? _autoTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadMemories();
    _checkOnboarding();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoRotation() {
    _autoTimer?.cancel();
    if (_recentMemories.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % _recentMemories.length;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
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

  Future<void> _loadMemories() async {
    final memories = await AppDatabase.instance.getRecentMemories(limit: 10);
    final count = await AppDatabase.instance.getMemoryCount();
    if (mounted) {
      setState(() {
        _recentMemories = memories;
        _memoryCount = count;
      });
      _startAutoRotation();
    }
  }

  void _onCardTap(Memory memory) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: memory)))
        .then((_) => _loadMemories());
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
        .then((_) => _loadMemories());
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
                    'おもいでノート',
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
                            .then((_) => _loadMemories());
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

              // Swipeable Memory Cards
              SizedBox(
                height: 220,
                child: _recentMemories.isEmpty
                    ? MemoryCard(memory: null)
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _recentMemories.length,
                        onPageChanged: (i) {
                          setState(() => _currentPage = i);
                          _startAutoRotation();
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _onCardTap(_recentMemories[index]),
                            child: MemoryCard(memory: _recentMemories[index]),
                          );
                        },
                      ),
              ),

              // Page indicator dots
              if (_recentMemories.length > 1) ...[
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_recentMemories.length.clamp(0, 10), (i) {
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(i,
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _currentPage ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _currentPage ? Colors.pink.shade300 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],

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
                        .then((_) => _loadMemories()),
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
                        .then((_) => _loadMemories()),
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
