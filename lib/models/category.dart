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

  List<String> get subTypes {
    switch (this) {
      case MemoryCategory.words:
        return ['言い間違い', '変な名前', '嬉しい言葉', 'おもしろ発言', 'はじめての言葉', 'その他'];
      case MemoryCategory.album:
        return ['日常', 'イベント', '作品', 'その他'];
      case MemoryCategory.money:
        return ['お年玉', 'おこづかい', 'お祝い', 'その他'];
      case MemoryCategory.questions:
        return ['なぜなぜ期', '素朴な疑問', '鋭い質問', 'その他'];
      case MemoryCategory.growth:
        return ['身長', '体重', '靴のサイズ', 'できたね！', 'その他'];
    }
  }
}
