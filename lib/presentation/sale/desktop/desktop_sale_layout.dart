import 'package:flutter/material.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_panel.dart';
import 'package:pos/presentation/sale/desktop/desktop_category_button.dart';
import 'package:pos/presentation/sale/items_panel.dart';

class DesktopSaleLayout extends StatelessWidget {
  const DesktopSaleLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // const TopBar(),
        Expanded(
          child: Row(
            children: const [
              SizedBox(width: 500, child: CartPanel()),
              SizedBox(width: 200, child: CategoryPanel()),
              Expanded(child: ItemsPanel()),
            ],
          ),
        ),
      ],
    );
  }
}
