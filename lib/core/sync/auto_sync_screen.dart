import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/sync_repository.dart';
import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/domain/models/kitchen_model.dart';

import 'dart:math';

class AutoSyncScreen extends StatefulWidget {
  const AutoSyncScreen({super.key});

  @override
  State<AutoSyncScreen> createState() => _AutoSyncScreenState();
}

class _AutoSyncScreenState extends State<AutoSyncScreen> with SingleTickerProviderStateMixin {
  late final StreamSubscription _sub;
  late final AnimationController _pulseController;

  String message = 'Preparing sync...';
  double progress = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _sub = SyncService.instance.stream.listen((event) async {
        setState(() {
          message = event.message;
          // Always calculate progress if total is provided
          if (event.total > 0) {
            progress = event.current / event.total;
          } else if (progress == 0 && event.phase != SyncPhase.failed) {
            // Keep previous progress if total is not yet known
            // progress remains at current value
          }
        });

        if (event.phase == SyncPhase.success) {
          await _goToDashboard();
        } else if (event.phase == SyncPhase.failed) {
          // Don't auto-navigate on failure - let user see the error and retry if needed
          // Add a delay before navigating to give user time to read the error
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _goToDashboard();
            }
          });
        }
      });

      await _startSync();
    });
  }

  Future<void> _startSync() async {
    final db = locator<AppDatabase>();
    await SyncService.instance.start(db);
  }

  Future<void> _goToDashboard() async {
    await _sub.cancel();
    AppNavigator.pushReplacementNamed("/dashboard");
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppPadding.screenAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Transform.scale(
                    scale: 1 + (_pulseController.value * 0.05),
                    child: SizedBox(
                      width: 130,
                      // height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PosReceiptLoader(progress: progress),
                          // AnimatedSwitcher(
                          //   duration: const Duration(milliseconds: 300),
                          //   child: Text(
                          //     '${(progress * 100).toInt()}%',
                          //     key: ValueKey(progress),
                          //     style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Text(
                  message,
                  key: ValueKey(message),
                  textAlign: TextAlign.center,
                  style: AppStyles.getRegularTextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please keep the app open',
                style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<SyncPayload> fetchSyncData() async {
  final repo = SyncRepository();
  final categories = await repo.fetchCategories();
  final kitchens = await repo.fetchKitchens();
  final items = await repo.fetchItems();
  final customers = await repo.fetchCustomers();
  return SyncPayload(categories, kitchens, items, customers);
}

class SyncPayload {
  final List<CategoryModel> categories;
  final List<KitchenModel> kitchens;
  final List<ItemModel> items;
  final List<CustomerModel> customers;

  SyncPayload(this.categories, this.kitchens, this.items, this.customers);
}

class PosReceiptLoader extends StatefulWidget {
  final double progress; // 0.0 – 1.0 (optional)

  const PosReceiptLoader({super.key, this.progress = 0});

  @override
  State<PosReceiptLoader> createState() => _PosReceiptLoaderState();
}

class _PosReceiptLoaderState extends State<PosReceiptLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 160,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black12,
                )
              ],
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Column(
                  children: List.generate(6, (i) {
                    final delay = i * 0.15;
                    final animValue = (_controller.value - delay).clamp(0.0, 1.0);

                    return Opacity(
                      opacity: sin(animValue * pi),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (widget.progress > 0)
            Text(
              '${(widget.progress * 100).toInt()}%',
              style: AppStyles.getBoldTextStyle(fontSize: 18),
            ),
        ],
      ),
    );
  }
}
