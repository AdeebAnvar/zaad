import 'package:flutter/material.dart';

class CategoryButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 560;
    final minWidth = isNarrow ? 82.0 : 92.0;
    final maxWidth = isNarrow ? 136.0 : 156.0;
    return Padding(
      padding: const EdgeInsets.all(1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
          height: isNarrow ? 42 : 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: isNarrow ? 12 : 13,
            ),
          ),
        ),
      ),
    );
  }
}
