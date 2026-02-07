import 'package:flutter/material.dart';
import '../models/category.dart';

class SubTypeGrid extends StatelessWidget {
  final MemoryCategory category;
  final String selectedLabel;
  final ValueChanged<String> onSelected;

  const SubTypeGrid({
    super.key,
    required this.category,
    required this.selectedLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final types = category.subTypes;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final st = types[index];
        final selected = selectedLabel == st.label;
        return GestureDetector(
          onTap: () => onSelected(st.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? category.color.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? category.color : Colors.grey.shade200,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(st.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  st.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? category.color : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
