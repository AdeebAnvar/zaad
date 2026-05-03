import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/custom_button.dart';

class TopButton extends StatelessWidget {
  final String text;
  const TopButton(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CustomButton(
        width: 140,
        onPressed: () {},
        text: text,
      ),
    );
  }
}
