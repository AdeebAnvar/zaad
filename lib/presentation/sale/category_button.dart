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
    return Padding(
      padding: const EdgeInsets.all(1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: 44,
          width: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
