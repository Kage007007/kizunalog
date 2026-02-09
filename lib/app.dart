import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class KizunaLogApp extends StatelessWidget {
  const KizunaLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'こども思い出ノート',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
