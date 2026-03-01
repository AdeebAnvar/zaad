import 'dart:async';
import 'dart:isolate';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pos/core/sync/auto_sync_screen.dart';

import '../../data/local/drift_database.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/network_utils.dart';
import '../../core/constants/enums.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  // _repo removed as we fetch customers from payload now

  final StreamController<SyncStatus> _controller = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get stream => _controller.stream;

  SyncStatus currentStatus = const SyncStatus(phase: SyncPhase.idle, message: 'Idle');

  DateTime? lastSyncedAt;
  Future<void> start(AppDatabase db) async {
    const int totalPhases = 100; // Total progress phases
    int currentPhase = 0;

    // Check network connection before starting sync (5% of total)
    _emit(SyncStatus(
      phase: SyncPhase.categories,
      message: 'Checking network connection...',
      current: currentPhase,
      total: totalPhases,
    ));

    final hasConnection = await NetworkUtils.hasInternetConnection();
    if (!hasConnection) {
      _emit(const SyncStatus(
        phase: SyncPhase.failed,
        message: 'No internet connection. Please check your network settings.',
      ));
      return;
    }

    currentPhase = 5; // Network check completed (5%)

    // Fetching data (10% of total)
    _emit(SyncStatus(
      phase: SyncPhase.categories,
      message: 'Fetching data...',
      current: currentPhase,
      total: totalPhases,
    ));

    try {
      // ✅ Network in isolate
      final payload = await Isolate.run(fetchSyncData);

      currentPhase = 15; // Fetching completed (15% total)

      // ---------- CATEGORIES ---------- (5% of total, from 15% to 20%)
      int categoryIndex = 0;
      final categoryTotal = payload.categories.length;
      for (final c in payload.categories) {
        categoryIndex++;
        final categoryProgress = (categoryIndex / categoryTotal) * 5; // 5% for all categories

        _emit(SyncStatus(
          phase: SyncPhase.categories,
          message: 'Syncing categories ($categoryIndex / $categoryTotal)',
          current: (15 + categoryProgress).toInt(),
          total: totalPhases,
        ));

        await db.categoryDao.insertOrUpdateCategory(
          CategoriesCompanion.insert(
            id: Value(c.id),
            name: c.name,
            otherName: c.otherName,
          ),
        );
      }

      currentPhase = 20; // Categories completed (20% total)

      // ---------- CUSTOMERS ---------- (10% of total, from 20% to 30%)
      _emit(SyncStatus(
        phase: SyncPhase.items,
        message: 'Also fetching customers...',
        current: 20,
        total: totalPhases,
      ));

      final customers = payload.customers;
      currentPhase = 25; // Customers fetched (25% total)

      int customerIndex = 0;
      final customerTotal = customers.length;
      for (final c in customers) {
        customerIndex++;
        final customerProgress = (customerIndex / customerTotal) * 5; // 5% for all customers

        _emit(SyncStatus(
          phase: SyncPhase.items,
          message: 'Also fetching customers... ($customerIndex / $customerTotal)',
          current: (25 + customerProgress).toInt(),
          total: totalPhases,
        ));

        await db.customersDao.insertOrUpdateCustomer(
          CustomersCompanion.insert(
            serverId: Value(c.serverId),
            name: c.name,
            email: Value(c.email),
            phone: Value(c.phone),
            gender: Value(c.gender),
            createdAt: Value(c.createdAt ?? DateTime.now()),
            updatedAt: Value(c.updatedAt ?? DateTime.now()),
            isSynced: const Value(true),
          ),
        );
      }

      currentPhase = 30; // Customers completed (30% total)

      // ---------- ITEMS ---------- (70% of total, from 30% to 100%)
      int index = 0;
      final itemsTotal = payload.items.length;
      for (final i in payload.items) {
        index++;
        await Future.delayed(Duration.zero);

        // Calculate progress: 30% + (70% * (index / itemsTotal))
        final itemProgress = 30 + (70 * (index / itemsTotal));

        _emit(SyncStatus(
          phase: SyncPhase.items,
          current: itemProgress.toInt(),
          total: totalPhases,
          message: 'Syncing items ($index / $itemsTotal)',
        ));

        String? localPath = '';
        try {
          localPath = await ImageUtils.downloadImage(
            i.imagePath,
            buildSafeImageName(i.id, i.imagePath),
          );
        } catch (e) {
          print(e);
        }

        await db.itemDao.upsertItem(
          ItemsCompanion.insert(
            id: Value(i.id),
            name: i.name,
            otherName: i.otherName,
            sku: i.sku,
            price: i.price,
            stock: i.stock,
            localImagePath: Value(localPath),
            categoryName: i.categoryName,
            barcode: i.barcode,
            categoryOtherName: i.categoryOtherName,
            imagePath: Value(i.imagePath),
            categoryId: i.categoryId,
          ),
        );
        await Future.wait([
          for (var v in i.variants)
            db.itemDao.upsertVariant(
              ItemVariantsCompanion.insert(
                itemId: i.id,
                name: v.name,
                price: v.price,
              ),
            ),
          for (var t in i.toppings)
            db.itemDao.upsertTopping(
              ItemToppingsCompanion.insert(
                itemId: i.id,
                name: t.name,
                price: t.price,
                maxQty: Value(t.maxQty),
              ),
            ),
        ]);
      }

      lastSyncedAt = DateTime.now();
      _emit(const SyncStatus(
        phase: SyncPhase.success,
        message: 'Sync completed',
        current: 100,
        total: 100,
      ));
    } catch (e, s) {
      debugPrint('SYNC FAILED: $e');
      debugPrintStack(stackTrace: s);

      // Determine error message based on error type
      String errorMessage = 'Sync failed';
      if (e.toString().contains('SocketException') || e.toString().contains('network') || e.toString().contains('connection') || e.toString().contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('No address associated with hostname')) {
        errorMessage = 'Unable to reach server. Please check your internet connection.';
      } else {
        errorMessage = 'Sync failed: ${e.toString()}';
      }

      _emit(SyncStatus(
        phase: SyncPhase.failed,
        message: errorMessage,
      ));
    }
  }

  void _emit(SyncStatus status) {
    currentStatus = status;
    if (!_controller.isClosed) {
      _controller.add(status);
    }
  }

  void dispose() {
    _controller.close();
  }

  String buildSafeImageName(int id, String url) {
    final uri = Uri.parse(url);

    // Try to extract extension
    final ext = p.extension(uri.path).isNotEmpty ? p.extension(uri.path) : '.jpg';

    return 'item_$id$ext';
  }

  /// Upload sales history (orders) to server
  Future<void> uploadSalesHistory(AppDatabase db) async {
    try {
      _emit(SyncStatus(
        phase: SyncPhase.categories,
        message: 'Checking network connection...',
        current: 0,
        total: 100,
      ));

      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        _emit(const SyncStatus(
          phase: SyncPhase.failed,
          message: 'No internet connection. Please check your network settings.',
        ));
        return;
      }

      _emit(SyncStatus(
        phase: SyncPhase.categories,
        message: 'Preparing sales data...',
        current: 10,
        total: 100,
      ));

      // Get all placed and completed orders (exclude kot)
      final allOrders = await db.ordersDao.getAllOrders();
      final ordersToUpload = allOrders.where((order) => 
        order.status != 'kot' && 
        (order.status == 'placed' || order.status == 'completed')
      ).toList();

      if (ordersToUpload.isEmpty) {
        _emit(const SyncStatus(
          phase: SyncPhase.success,
          message: 'No sales to upload',
          current: 100,
          total: 100,
        ));
        return;
      }

      _emit(SyncStatus(
        phase: SyncPhase.items,
        message: 'Uploading ${ordersToUpload.length} orders...',
        current: 20,
        total: 100,
      ));

      // Get unsynced customers to upload along with orders
      final unsyncedCustomers = await db.customersDao.getUnsyncedCustomers();

      // Upload unsynced customers first
      if (unsyncedCustomers.isNotEmpty) {
        _emit(SyncStatus(
          phase: SyncPhase.items,
          message: 'Uploading ${unsyncedCustomers.length} new customers...',
          current: 15,
          total: 100,
        ));

        int customerUploaded = 0;
        for (final customer in unsyncedCustomers) {
          try {
            final customerData = {
              'name': customer.name,
              'email': customer.email,
              'phone': customer.phone,
              'gender': customer.gender,
              'createdAt': customer.createdAt.toIso8601String(),
            };

            // Upload customer to server (using isolate for network operations)
            await Isolate.run(() => _uploadCustomerToServer(customerData));

            // Mark as synced
            await db.customersDao.markAsSynced(customer.id);

            customerUploaded++;
            final customerProgress = 15 + ((customerUploaded / unsyncedCustomers.length) * 5).toInt();
            
            _emit(SyncStatus(
              phase: SyncPhase.items,
              message: 'Uploading customers ($customerUploaded / ${unsyncedCustomers.length})',
              current: customerProgress,
              total: 100,
            ));
          } catch (e) {
            debugPrint('Failed to upload customer ${customer.name}: $e');
            // Continue with next customer
          }
        }
      }

      // Upload orders in batches
      int uploaded = 0;
      final uploadStartProgress = unsyncedCustomers.isNotEmpty ? 20 : 20;
      for (final order in ordersToUpload) {
        try {
          // Get cart items for this order
          final cartItems = await db.cartsDao.getItemsByCart(order.cartId);
          
          // Prepare order data for upload
          final orderData = {
            'id': order.id,
            'cartId': order.cartId,
            'invoiceNumber': order.invoiceNumber,
            'referenceNumber': order.referenceNumber,
            'totalAmount': order.totalAmount,
            'discountAmount': order.discountAmount,
            'discountType': order.discountType,
            'finalAmount': order.finalAmount,
            'customerName': order.customerName,
            'customerEmail': order.customerEmail,
            'customerPhone': order.customerPhone,
            'customerGender': order.customerGender,
            'cashAmount': order.cashAmount,
            'creditAmount': order.creditAmount,
            'cardAmount': order.cardAmount,
            'status': order.status,
            'createdAt': order.createdAt.toIso8601String(),
            'items': cartItems.map((item) => {
              'id': item.id,
              'itemId': item.itemId,
              'itemVariantId': item.itemVariantId,
              'itemToppingId': item.itemToppingId,
              'quantity': item.quantity,
              'total': item.total,
              'discount': item.discount,
              'discountType': item.discountType,
              'notes': item.notes,
            }).toList(),
          };

          // Upload to server (using isolate for network operations)
          await Isolate.run(() => _uploadOrderToServer(orderData));

          uploaded++;
          final progress = uploadStartProgress + (((uploaded / ordersToUpload.length) * (100 - uploadStartProgress)).toInt());
          
          _emit(SyncStatus(
            phase: SyncPhase.items,
            message: 'Uploading orders ($uploaded / ${ordersToUpload.length})',
            current: progress,
            total: 100,
          ));
        } catch (e) {
          debugPrint('Failed to upload order ${order.invoiceNumber}: $e');
          // Continue with next order
        }
      }

      _emit(const SyncStatus(
        phase: SyncPhase.success,
        message: 'Sales history uploaded successfully',
        current: 100,
        total: 100,
      ));
    } catch (e, s) {
      debugPrint('UPLOAD SALES FAILED: $e');
      debugPrintStack(stackTrace: s);

      String errorMessage = 'Upload failed';
      if (e.toString().contains('SocketException') || 
          e.toString().contains('network') || 
          e.toString().contains('connection') || 
          e.toString().contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else {
        errorMessage = 'Upload failed: ${e.toString()}';
      }

      _emit(SyncStatus(
        phase: SyncPhase.failed,
        message: errorMessage,
      ));
    }
  }

  // Static function for isolate - Upload order to server
  static Future<void> _uploadOrderToServer(Map<String, dynamic> orderData) async {
    // TODO: Implement actual server upload logic
    // This is a placeholder - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Example: Use HTTP client to upload
    // final response = await http.post(
    //   Uri.parse('$serverUrl/api/orders'),
    //   body: jsonEncode(orderData),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // if (response.statusCode != 200) {
    //   throw Exception('Upload failed: ${response.statusCode}');
    // }
  }

  // Static function for isolate - Upload customer to server
  static Future<void> _uploadCustomerToServer(Map<String, dynamic> customerData) async {
    // TODO: Implement actual server upload logic
    // This is a placeholder - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Example: Use HTTP client to upload
    // final response = await http.post(
    //   Uri.parse('$serverUrl/api/customers'),
    //   body: jsonEncode(customerData),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // if (response.statusCode != 200) {
    //   throw Exception('Upload failed: ${response.statusCode}');
    // }
  }
}
