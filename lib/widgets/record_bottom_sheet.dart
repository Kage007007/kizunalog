import 'package:flutter/material.dart';
import '../models/category.dart';

/// 全カテゴリ共通のボトムシート外枠。中身は各カテゴリのステップビルダーが担当。
Future<T?> showRecordBottomSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => child,
  );
}

/// ボトムシートの共通レイアウト（ドラッグハンドル + 閉じるボタン + ステップインジケータ）
class RecordSheetScaffold extends StatelessWidget {
  final MemoryCategory category;
  final int currentStep;
  final int totalSteps;
  final bool showClose;
  final VoidCallback onClose;
  final Widget child;

  const RecordSheetScaffold({
    super.key,
    required this.category,
    required this.currentStep,
    required this.totalSteps,
    required this.showClose,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // ヘッダー（閉じる + ステップインジケータ）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showClose)
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close_rounded, size: 20, color: Colors.grey.shade500),
                    ),
                  )
                else
                  const SizedBox(width: 36),
                const Spacer(),
                // ステップインジケータ
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(totalSteps, (i) => Container(
                    width: i == currentStep ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == currentStep
                          ? category.color
                          : category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // コンテンツ
          Flexible(child: child),
        ],
      ),
    );
  }
}
