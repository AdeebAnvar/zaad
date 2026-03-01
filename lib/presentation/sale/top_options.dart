import 'package:flutter/material.dart';
import 'package:pos/presentation/sale/top_button.dart';

class TopOptions extends StatelessWidget {
  const TopOptions();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          TopButton("Hold"),
          TopButton("Hold List"),
          TopButton("Delivery"),
        ],
      ),
    );
  }
}
