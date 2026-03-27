import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class DeliverySaleScreen extends StatefulWidget {
  const DeliverySaleScreen({super.key});

  @override
  State<DeliverySaleScreen> createState() => _DeliverySaleScreenState();
}

class _DeliverySaleScreenState extends State<DeliverySaleScreen> {
  bool _loading = true;
  List<DeliveryPartner> _partners = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = locator<DeliveryPartnerRepository>();
    final partners = await repo.getAll();
    if (!mounted) return;
    setState(() {
      _partners = partners;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Delivery Sale',
      appBarScreen: 'delivery',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  ..._partners.map((p) => _partnerTile(p.name)),
                  _partnerTile('NORMAL'),
                ],
              ),
            ),
    );
  }

  Widget _partnerTile(String name) {
    return InkWell(
      onTap: () => AppNavigator.pushNamed(
        Routes.counter,
        args: {'orderType': 'delivery', 'deliveryPartner': name},
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: AppColors.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name.toUpperCase(),
                style: AppStyles.getSemiBoldTextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
