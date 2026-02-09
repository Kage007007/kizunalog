import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  /// trueの場合は設定画面からの再表示（閉じるボタンを表示）
  final bool fromSettings;

  const OnboardingScreen({super.key, this.fromSettings = false});

  static const _seenKey = 'onboarding_seen';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_seenKey) ?? false);
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFF8A9E),
      title: 'こども思い出ノートへようこそ',
      subtitle: 'お子さんの大切な思い出を\nかんたんに記録できるアプリです',
    ),
    _PageData(
      icon: Icons.grid_view_rounded,
      color: Color(0xFF7EC8E3),
      title: '5つのカテゴリ',
      subtitle: 'ことば・アルバム・おさいふ\nしつもん・せいちょう\nホーム画面下のボタンから記録できます',
    ),
    _PageData(
      icon: Icons.touch_app_rounded,
      color: Color(0xFFA8E6CF),
      title: 'かんたん3ステップ',
      subtitle: 'カテゴリを選ぶ → 内容を入力 → 完了！\n記録した後すぐシェアもできます',
    ),
    _PageData(
      icon: Icons.list_alt_rounded,
      color: Color(0xFFD4A5FF),
      title: '一覧・グラフ・おさいふ',
      subtitle: 'ホーム中段のボタンから\n記録の一覧表示やグラフを確認できます\nフィルタで絞り込みも可能です',
    ),
    _PageData(
      icon: Icons.share_rounded,
      color: Color(0xFFFFD700),
      title: 'シェア＆バックアップ',
      subtitle: '思い出はSNSにシェアできます\n設定画面からバックアップの\nエクスポートも可能です',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await OnboardingScreen.markSeen();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: widget.fromSettings
          ? AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, color: page.color, size: 56),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _pages[_currentPage].color
                        : _pages[_currentPage].color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Text('もどる', style: TextStyle(color: Colors.grey.shade500)),
                    )
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'はじめる' : 'つぎへ',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _PageData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
