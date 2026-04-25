import 'package:flutter/material.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_panel.dart';
import 'package:pos/presentation/sale/desktop/desktop_category_button.dart';
import 'package:pos/presentation/sale/items_panel.dart';

class DesktopSaleLayout extends StatelessWidget {
  const DesktopSaleLayout({super.key, this.openPaymentOnLoad = false});

  final bool openPaymentOnLoad;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final categoryWidth = width < 1100 ? 150.0 : (width < 1300 ? 170.0 : 190.0);
        return Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: width < 1100 ? 3 : 2, child: CartPanel(openPaymentOnLoad: openPaymentOnLoad)),
                  SizedBox(width: categoryWidth, child: CategoryPanel()),
                  Expanded(flex: width < 1100 ? 5 : 4, child: ItemsPanel()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
