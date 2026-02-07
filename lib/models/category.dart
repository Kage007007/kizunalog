import 'package:flutter/material.dart';

enum MemoryCategory {
  words,
  album,
  money,
  questions,
  growth;

  String get label {
    switch (this) {
      case MemoryCategory.words:
        return 'ことば';
      case MemoryCategory.album:
        return 'アルバム';
      case MemoryCategory.money:
        return 'おさいふ';
      case MemoryCategory.questions:
        return 'しつもん';
      case MemoryCategory.growth:
        return 'せいちょう';
    }
  }

  IconData get icon {
    switch (this) {
      case MemoryCategory.words:
        return Icons.chat_bubble_rounded;
      case MemoryCategory.album:
        return Icons.photo_album_rounded;
      case MemoryCategory.money:
        return Icons.savings_rounded;
      case MemoryCategory.questions:
        return Icons.help_rounded;
      case MemoryCategory.growth:
        return Icons.trending_up_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MemoryCategory.words:
        return const Color(0xFFFF8A9E);
      case MemoryCategory.album:
        return const Color(0xFF7EC8E3);
      case MemoryCategory.money:
        return const Color(0xFFFFD700);
      case MemoryCategory.questions:
        return const Color(0xFFA8E6CF);
      case MemoryCategory.growth:
        return const Color(0xFFD4A5FF);
    }
  }

  List<SubType> get subTypes {
    switch (this) {
      case MemoryCategory.words:
        return [
          SubType('言い間違い', '🙊'),
          SubType('変な名前', '👽'),
          SubType('嬉しい言葉', '🥰'),
          SubType('おもしろ発言', '🤣'),
          SubType('はじめての言葉', '👶'),
          SubType('その他', '💬'),
        ];
      case MemoryCategory.album:
        return [
          SubType('日常', '📸'),
          SubType('イベント', '🎉'),
          SubType('作品', '🎨'),
          SubType('その他', '📷'),
        ];
      case MemoryCategory.money:
        return [
          SubType('お年玉', '🧧'),
          SubType('おこづかい', '💰'),
          SubType('お祝い', '🎁'),
          SubType('その他', '💴'),
        ];
      case MemoryCategory.questions:
        return [
          SubType('なぜなぜ期', '🤔'),
          SubType('素朴な疑問', '🌱'),
          SubType('鋭い質問', '⚡'),
          SubType('その他', '❓'),
        ];
      case MemoryCategory.growth:
        return [
          SubType('身長', '📏'),
          SubType('体重', '⚖️'),
          SubType('靴のサイズ', '👟'),
          SubType('できたね！', '🏆'),
          SubType('その他', '🌟'),
        ];
    }
  }
}

class SubType {
  final String label;
  final String emoji;

  const SubType(this.label, this.emoji);
}
