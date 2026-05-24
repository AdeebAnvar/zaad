import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/core/print/kot_kitchen_update_diff.dart';
import 'package:pos/core/print/cash_drawer_on_payment.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/core/update/updater_manager.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(
    this.cartRepo,
    this.itemRepo,
    this.orderRepo,
    this.sessionDao,
    this.printService, {
    this.orderType = OrderType.takeAway,
    this.deliveryPartner,
    this.initialReferenceNumber,
    String? dineInFloorTableAnchor,
  }) : super(CartState([])) {
    _currentKOTReference = initialReferenceNumber;
    _dineInFloorTableAnchor = dineInFloorTableAnchor;
  }

  final OrderType orderType;
  final String? deliveryPartner;
  final String? initialReferenceNumber;
  final CartRepository cartRepo;
  final ItemRepository itemRepo;
  final OrderRepository orderRepo;
  final SessionDao sessionDao;
  final PrintService printService;
  int? _activeCartId;
  String? _invoiceNumber;
  String? _currentKOTReference;
  int? _currentKOTOrderId;
  /// Table/floor anchor from Dine In tap; persisted in hub metadata, not as [Order.referenceNumber] unless user enters text in the KOT dialog.
  String? _dineInFloorTableAnchor;
  int? _editingOrderId; // Track order ID when editing a paid order
  String? _editingOrderStatus; // Track order status when editing
  bool _openedForEdit = false; // True when screen was opened from Take Away Log (edit order)

  /// IDs of cart items added in this session. Used to skip delete/reason popup for newly added items.
  final Set<int> _newlyAddedCartItemIds = {};

  /// Cart line IDs already printed on a kitchen KOT (edit mode: existing lines from a KOT ticket are pre-filled).
  final Set<int> _kotPrintedCartItemIds = {};

  /// Snapshot of cart lines the kitchen was last aligned with (`null` = use full-cart KOT until first slip).
  List<CartItem>? _kotKitchenBaselineForDiff;

  List<CartItem> _kotSnapshotCart(List<CartItem> items) => items.map((e) => e.copyWith()).toList();

  /// True if the cart item was newly added in this session (no delete/reason popup).
  bool isNewlyAddedCartItem(int cartItemId) => _newlyAddedCartItemIds.contains(cartItemId);

  // Cart-level discount (mutually exclusive with item discounts)
  double _cartDiscountAmount = 0.0;
  String? _cartDiscountType; // 'amount' or 'percentage'

  String? get currentKOTReference => _currentKOTReference;
  bool get isEditingPaidOrder => _editingOrderId != null && (_editingOrderStatus == 'placed' || _editingOrderStatus == 'completed');

  /// True when this screen was opened for editing an order (e.g. from Take Away Log). Hide reference/KOT popup.
  bool get isOpenedForEdit => _openedForEdit;

  @override
  void emit(CartState state) {
    super.emit(state);
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.windows &&
        locator.isRegistered<UpdaterManager>()) {
      locator<UpdaterManager>().reportBillingGate(
        state.orderSubmitPending || state.totalItems > 0,
      );
    }
  }

  Future<Map<String, dynamic>?> getPaymentPrefillForEdit() async {
    if (!_openedForEdit || _editingOrderId == null) {
      return null;
    }

    final order = await orderRepo.getOrderById(_editingOrderId!);
    if (order == null) {
      return null;
    }

    Map<String, dynamic>? appliedOffer;
    try {
      final raw = order.hubMetadata;
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['applied_offer'] is Map) {
          appliedOffer = Map<String, dynamic>.from(decoded['applied_offer'] as Map<dynamic, dynamic>);
        }
      }
    } catch (_) {}

    return <String, dynamic>{
      "name": order.customerName,
      "phone": order.customerPhone,
      "email": order.customerEmail,
      "gender": order.customerGender,
      "onlineOrderNumber": order.referenceNumber,
      "cash": order.cashAmount,
      "credit": order.creditAmount,
      "card": order.cardAmount,
      "online": order.onlineAmount,
      "discountAmount": order.discountAmount,
      "discountType": order.discountType,
      if (appliedOffer != null) "appliedOffer": appliedOffer,
    };
  }

  double get cartDiscountAmount => _cartDiscountAmount;
  String? get cartDiscountType => _cartDiscountType;
  Future<void> addItemToCart(
    Item item, {
    ItemVariant? selectedVariant,
    int quantity = 1,
  }) async {
    // 1️⃣ Ensure cart exists
    await _ensureCart();

    // 2️⃣ Calculate unit price and total
    final unitPrice = selectedVariant?.price ?? item.price;
    final total = (unitPrice * quantity);

    // 3️⃣ Create cart item (order line)
    final cartItem = CartItem(
      id: 0,
      total: total,
      cartId: _activeCartId ?? 0, // auto increment in DB
      itemId: item.id,
      itemName: item.name,
      itemVariantId: selectedVariant?.id,
      itemToppingId: null,
      quantity: quantity,
      discount: 0,
    );

    // 4️⃣ Save to DB
    final newId = await cartRepo.addItemToCart(_activeCartId!, cartItem);
    _newlyAddedCartItemIds.add(newId);

    // 5️⃣ Reload cart items
    await _loadCartItems();

    // 6️⃣ Update KOT if exists
    await _updateKOTIfExists();
  }

  /// Drift and UI already hold the same lines; re-emitting identical data was causing full list/fab flicker.
  bool _cartLinesEqual(List<CartItem> a, List<CartItem> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _loadCartItems() async {
    if (_activeCartId == null) {
      if (state.items.isNotEmpty) {
        emit(CartState([]));
      }
      return;
    }

    final items = await cartRepo.getCartItemsByCartId(_activeCartId!);
    final next = items ?? <CartItem>[];
    if (_cartLinesEqual(state.items, next) && state.orderSubmitPending == false && state.orderSubmitError == null) {
      return;
    }
    emit(
      CartState(
        next,
        orderSubmitPending: state.orderSubmitPending,
        orderSubmitError: state.orderSubmitError,
      ),
    );
  }

  Future<void> increaseQty(int index) async {
    if (index < 0 || index >= state.items.length) return;
    await increaseQtyByCartItemId(state.items[index].id);
  }

  Future<void> increaseQtyByCartItemId(int cartItemId) async {
    final cartItem = state.items.firstWhere(
      (item) => item.id == cartItemId,
      orElse: () => throw StateError('Cart item not found'),
    );

    final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
    if (item == null) return;

    ItemVariant? variant;
    if (cartItem.itemVariantId != null) {
      variant = await itemRepo.fetchVariantById(cartItem.itemVariantId!);
    }

    final unitPrice = variant?.price ?? item.price;
    final newQuantity = cartItem.quantity + 1;
    final newTotal = (unitPrice * newQuantity) - cartItem.discount;

    final updatedItem = cartItem.copyWith(
      quantity: newQuantity,
      total: newTotal,
    );

    await cartRepo.updateCartItem(updatedItem);
    await _loadCartItems();
    await _updateKOTIfExists();
  }

  Future<void> decreaseQty(int index) async {
    if (index < 0 || index >= state.items.length) return;
    await decreaseQtyByCartItemId(state.items[index].id);
  }

  Future<void> decreaseQtyByCartItemId(int cartItemId) async {
    final cartItem = state.items.firstWhere(
      (item) => item.id == cartItemId,
      orElse: () => throw StateError('Cart item not found'),
    );

    if (cartItem.quantity == 1) {
      await removeItemByCartItemId(cartItemId);
      return;
    }

    final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
    if (item == null) return;

    ItemVariant? variant;
    if (cartItem.itemVariantId != null) {
      variant = await itemRepo.fetchVariantById(cartItem.itemVariantId!);
    }

    final unitPrice = variant?.price ?? item.price;
    final newQuantity = cartItem.quantity - 1;
    final newTotal = (unitPrice * newQuantity) - cartItem.discount;

    final updatedItem = cartItem.copyWith(
      quantity: newQuantity,
      total: newTotal,
    );

    await cartRepo.updateCartItem(updatedItem);
    await _loadCartItems();
    await _updateKOTIfExists();
  }

  /// Sets line quantity directly (tap-to-edit). Preserves effective unit price
  /// `(total + discount) / quantity`, including manual unit overrides and toppings.
  Future<void> setQuantityByCartItemId(int cartItemId, int newQuantity) async {
    if (newQuantity < 1) {
      await removeItemByCartItemId(cartItemId);
      return;
    }

    final cartItem = state.items.firstWhere(
      (item) => item.id == cartItemId,
      orElse: () => throw StateError('Cart item not found'),
    );
    if (newQuantity == cartItem.quantity) return;

    final perUnit = cartItem.quantity > 0
        ? (cartItem.total + cartItem.discount) / cartItem.quantity
        : 0.0;
    final newTotal = (perUnit * newQuantity - cartItem.discount).clamp(0.0, double.infinity);

    final updatedItem = cartItem.copyWith(
      quantity: newQuantity,
      total: newTotal,
    );

    await cartRepo.updateCartItem(updatedItem);
    await _loadCartItems();
    await _updateKOTIfExists();
  }

  Future<void> _ensureCart() async {
    if (_activeCartId != null) return;

    final r = await orderRepo.createCartWithReservedInvoice(
      orderType: orderType.value,
      deliveryPartner: deliveryPartner,
    );
    _activeCartId = r.cartId;
    _invoiceNumber = r.invoice;
  }

  /// Single invoice sequence per cart: `_ensureCart` reserves a number on the cart row;
  /// KOT and Pay must reuse it (no second `getNextInvoiceNumber` for the same sale).
  Future<String> _invoiceNumberForPersistedCart() async {
    final memo = _invoiceNumber?.trim();
    if (memo != null && memo.isNotEmpty) return memo;

    final cartId = _activeCartId;
    if (cartId != null) {
      final row = await cartRepo.getCartByCartId(cartId);
      final fromRow = row?.invoiceNumber.trim() ?? '';
      if (fromRow.isNotEmpty) {
        _invoiceNumber = fromRow;
        return fromRow;
      }
    }

    final next = await orderRepo.getNextInvoiceNumber(orderType.value);
    _invoiceNumber = next;
    return next;
  }

  Future<void> _clearPersistedCartId() async {
    await sessionDao.setActiveCartId(null);
  }

  /// Restore cart from session's active cart id (Drift as single source of truth).
  /// Call when opening Take Away screen without an orderId.
  Future<void> loadActiveCart() async {
    final cartId = await sessionDao.getActiveCartId();
    if (cartId == null) return;

    // We no longer restore persisted carts across screen rebuilds / app restarts.
    // Clear any previously saved active cart id so future sessions start fresh.
    await sessionDao.setActiveCartId(null);
  }

  Future<void> removeItem(int index, BuildContext? context) async {
    if (index < 0 || index >= state.items.length) return;
    await removeItemByCartItemId(state.items[index].id);
  }

  Future<void> removeItemByCartItemId(int cartItemId) async {
    _newlyAddedCartItemIds.remove(cartItemId);
    // Sync emit so Dismissible (and list) drops the row before the next frame.
    // Async DB work follows; _loadCartItems reconciles with Drift.
    final next = state.items.where((e) => e.id != cartItemId).toList();
    emit(
      CartState(
        next,
        orderSubmitPending: state.orderSubmitPending,
        orderSubmitError: state.orderSubmitError,
      ),
    );
    await cartRepo.removeCartItem(cartItemId);
    await _loadCartItems();
    await _updateKOTIfExists();
  }

  /// Update unit price for a cart item. Recalculates total: newTotal = newUnitPrice * quantity - discount.
  Future<void> updateUnitPrice(int cartItemId, double newUnitPrice) async {
    if (newUnitPrice < 0) return;
    final cartItem = state.items.firstWhere(
      (item) => item.id == cartItemId,
      orElse: () => throw StateError('Cart item not found'),
    );
    final newTotal = (newUnitPrice * cartItem.quantity - cartItem.discount).clamp(0.0, double.infinity);
    await cartRepo.updateCartItemTotal(cartItemId, newTotal);
    await _loadCartItems();
    await _updateKOTIfExists();
  }

  Future<void> clearCart() async {
    if (_activeCartId != null) {
      await cartRepo.deleteCart(_activeCartId!);
      _activeCartId = null;
      _invoiceNumber = null;
      await _clearPersistedCartId();
    }
    _currentKOTReference = null;
    _currentKOTOrderId = null;
    _dineInFloorTableAnchor = null;
    _editingOrderId = null;
    _editingOrderStatus = null;
    _openedForEdit = false;
    _newlyAddedCartItemIds.clear();
    _kotPrintedCartItemIds.clear();
    _kotKitchenBaselineForDiff = null;
    _cartDiscountAmount = 0.0;
    _cartDiscountType = null;
    emit(CartState([]));
  }

  /// Clears cart state without deleting cart/cart items from DB.
  /// Use when completing an order so items remain for order history (Recent Sales View).
  Future<void> _clearCartStateOnly() async {
    if (_activeCartId != null) {
      _activeCartId = null;
      _invoiceNumber = null;
      await _clearPersistedCartId();
    }
    _currentKOTReference = null;
    _currentKOTOrderId = null;
    _dineInFloorTableAnchor = null;
    _editingOrderId = null;
    _editingOrderStatus = null;
    _openedForEdit = false;
    _newlyAddedCartItemIds.clear();
    _kotPrintedCartItemIds.clear();
    _kotKitchenBaselineForDiff = null;
    _cartDiscountAmount = 0.0;
    _cartDiscountType = null;
    emit(CartState([]));
  }

  /// Staff-entered KOT label for [Order.referenceNumber] (not floor routing).
  String? _staffKotReferenceForDb(String? staffKotReference) {
    final staff = staffKotReference?.trim();
    return (staff != null && staff.isNotEmpty) ? staff : null;
  }

  String? _hubMetadataWithDineInAnchor(String? existingHub) {
    final anchor = _dineInFloorTableAnchor?.trim();
    if (orderType != OrderType.dineIn || anchor == null || anchor.isEmpty) return existingHub;
    try {
      Map<String, dynamic> map;
      if (existingHub != null && existingHub.trim().isNotEmpty) {
        final parsed = jsonDecode(existingHub);
        map = parsed is Map ? Map<String, dynamic>.from(parsed) : <String, dynamic>{};
      } else {
        map = <String, dynamic>{};
      }
      map[DineInRefParser.hubMetadataAnchorKey] = anchor;
      return jsonEncode(map);
    } catch (_) {
      return jsonEncode({DineInRefParser.hubMetadataAnchorKey: anchor});
    }
  }

  Future<List<String>> saveKOT(String referenceNumber) async {
    if (state.items.isEmpty || _activeCartId == null) return [];
    final normalizedInputReference = referenceNumber.trim();
    var effectiveReference = normalizedInputReference;
    if (effectiveReference.isEmpty) {
      final existing = _currentKOTReference?.trim();
      effectiveReference = (existing != null && existing.isNotEmpty) ? existing : '';
    }

    final totalAmount = state.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    Order? orderToUpdate;
    // Log edit (incl. SUB-originated hub mirrors): always update the opened row — never create a second invoice.
    if (_openedForEdit && _editingOrderId != null) {
      orderToUpdate = await orderRepo.getOrderById(_editingOrderId!);
    } else {
      Order? existingKOT;
      if (effectiveReference.isNotEmpty) {
        existingKOT = await orderRepo.getKOTByReference(effectiveReference);
      } else if (_currentKOTOrderId != null) {
        final self = await orderRepo.getOrderById(_currentKOTOrderId!);
        if (self != null &&
            self.status.toLowerCase() == 'kot' &&
            self.cartId == _activeCartId) {
          existingKOT = self;
        }
      }
      if (existingKOT != null && existingKOT.id == _currentKOTOrderId) {
        orderToUpdate = existingKOT;
      }
    }

    final refForDb = _staffKotReferenceForDb(
      effectiveReference.isEmpty ? null : effectiveReference,
    );
    final hubForDb = _hubMetadataWithDineInAnchor(null);
    // #region agent log
    if (orderType == OrderType.dineIn) {
      agentDebugLog(
        hypothesisId: 'H_kot',
        location: 'cart_cubit.dart:saveKOT',
        message: 'dine_in_kot_persist',
        data: <String, Object?>{
          'runId': 'post-fix',
          'effectiveReference': effectiveReference.isEmpty ? null : effectiveReference,
          'refForDb': refForDb,
          'floorAnchor': _dineInFloorTableAnchor,
          'hubHasRoutingAnchor': hubForDb != null && hubForDb.contains(DineInRefParser.hubMetadataAnchorKey),
        },
      );
    }
    // #endregion

    if (orderToUpdate != null) {
      final mergedHub = _hubMetadataWithDineInAnchor(orderToUpdate.hubMetadata);
      final updatedOrder = orderToUpdate.copyWith(
        totalAmount: totalAmount,
        finalAmount: totalAmount,
        cartId: _activeCartId!,
        referenceNumber: Value(refForDb),
        hubMetadata: mergedHub != null ? Value<String?>(mergedHub) : const Value.absent(),
      );
      await orderRepo.updateOrder(updatedOrder);
      _currentKOTOrderId = orderToUpdate.id;
    } else {
      // Same invoice as the active cart (reserved in _ensureCart).
      final cashierId = await _sessionUserId();
      final branchId = await _sessionBranchId();
      final order = Order(
        id: 0,
        cartId: _activeCartId!,
        invoiceNumber: await _invoiceNumberForPersistedCart(),
        referenceNumber: refForDb,
        totalAmount: totalAmount,
        discountAmount: 0,
        discountType: null,
        finalAmount: totalAmount,
        customerName: null,
        customerEmail: null,
        customerPhone: null,
        customerGender: null,
        cashAmount: 0,
        creditAmount: 0,
        cardAmount: 0,
        onlineAmount: 0,
        createdAt: DateTime.now(),
        status: orderType == OrderType.delivery ? 'pending' : 'kot',
        orderType: orderType.value,
        deliveryPartner: deliveryPartner,
        userId: cashierId,
        branchId: branchId,
        hubMetadata: hubForDb,
        hubSyncPending: false,
      );
      final orderId = await orderRepo.createOrder(order);
      _currentKOTOrderId = orderId;
    }

    _currentKOTReference = refForDb;

    Order? kotOrder;
    final kotId = _currentKOTOrderId;
    if (kotId != null) {
      kotOrder = await orderRepo.getOrderById(kotId);
    }

    final currentSnap = List<CartItem>.from(state.items);
    final kotRefPrint = kotOrder?.referenceNumber?.trim().isNotEmpty == true
        ? kotOrder!.referenceNumber!.trim()
        : (kotOrder?.invoiceNumber ?? effectiveReference);

    late final List<String> printFailed;

    if (_openedForEdit) {
      final inv = kotOrder?.invoiceNumber;
      final bid = kotOrder?.branchId;
      final ordAt = kotOrder?.createdAt;
      final oTypeRaw = kotOrder?.orderType ?? orderType.value;

      if (_kotKitchenBaselineForDiff != null) {
        final rows = KotKitchenUpdateDiff.compute(_kotKitchenBaselineForDiff!, currentSnap);
        printFailed = rows.isEmpty
            ? <String>[]
            : await printService.printKOTUpdatePerKitchen(
                rows: rows,
                orderTypeRaw: oTypeRaw,
                referenceNumber: kotRefPrint,
                invoiceNumber: inv,
                branchId: bid,
                orderedAt: ordAt,
              );
      } else {
        final itemsToPrint = state.items.where((i) => !_kotPrintedCartItemIds.contains(i.id)).toList();
        printFailed = itemsToPrint.isEmpty
            ? <String>[]
            : await printService.printKOTPerKitchen(
                cartItems: itemsToPrint,
                order: kotOrder,
                referenceNumber: kotRefPrint,
                invoiceNumber: inv,
                branchId: bid,
                orderedAt: ordAt,
              );
        for (final i in itemsToPrint) {
          _kotPrintedCartItemIds.add(i.id);
        }
      }
      // Mirror new-KOT behaviour: lines remain on the order in DB; clear session so counter is empty.
      await _clearCartStateOnly();
      return printFailed;
    }

    printFailed = currentSnap.isEmpty
        ? <String>[]
        : await printService.printKOTPerKitchen(
            cartItems: currentSnap,
            order: kotOrder,
            referenceNumber: kotRefPrint,
            invoiceNumber: kotOrder?.invoiceNumber,
            branchId: kotOrder?.branchId,
            orderedAt: kotOrder?.createdAt,
          );

    // Leave lines in DB (order.cartId owns them); clear active session + discounts so UI starts fresh next line.
    await _clearCartStateOnly();
    return printFailed;
  }

  Future<int?> _sessionUserId() async {
    final s = await sessionDao.getActiveSession();
    return s?.userId;
  }

  Future<int> _sessionBranchId() => sessionDao.requireActiveBranchId();

  Map<String, dynamic>? _offerFromDiscountPayload(Map<String, dynamic> discount) {
    final raw = discount['offer'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  String? _withOfferMetadata(String? hubMetadata, Map<String, dynamic>? offer) {
    if (offer == null) return hubMetadata;
    final cleanedOffer = <String, dynamic>{
      'name': offer['name']?.toString() ?? '',
      'uuid': offer['uuid']?.toString() ?? '',
      'type': offer['type']?.toString() ?? '',
      'value': (offer['value'] as num?)?.toDouble() ?? (double.tryParse(offer['value']?.toString() ?? '') ?? 0.0),
      'discountAmount': (offer['discountAmount'] as num?)?.toDouble() ??
          (double.tryParse(offer['discountAmount']?.toString() ?? '') ?? 0.0),
      'toDate': offer['toDate']?.toString() ?? '',
      if (offer['autoDayDiscount'] != null)
        'autoDayDiscount': (offer['autoDayDiscount'] as num?)?.toDouble() ??
            (double.tryParse(offer['autoDayDiscount']?.toString() ?? '') ?? 0.0),
      if (offer['autoDayOfferNames'] is List) 'autoDayOfferNames': offer['autoDayOfferNames'],
    };
    try {
      final root = (hubMetadata != null && hubMetadata.trim().isNotEmpty) ? jsonDecode(hubMetadata) : <String, dynamic>{};
      final map = root is Map ? Map<String, dynamic>.from(root) : <String, dynamic>{};
      map['applied_offer'] = cleanedOffer;
      return jsonEncode(map);
    } catch (_) {
      return jsonEncode({'applied_offer': cleanedOffer});
    }
  }

  /// Save KOT using the already defined reference (edit only). No reference dialog.
  Future<List<String>> saveKOTWithExistingReference() async {
    return saveKOT(_currentKOTReference ?? '');
  }

  Future<void> _updateKOTIfExists() async {
    if (_activeCartId == null) return;
    final hasKot = _currentKOTOrderId != null ||
        (_currentKOTReference != null && _currentKOTReference!.trim().isNotEmpty);
    if (!hasKot) return;

    if (state.items.isEmpty) {
      // Remove KOT if cart is emptyz
      if (_currentKOTOrderId != null) {
        await orderRepo.deleteOrder(_currentKOTOrderId!);
        _currentKOTOrderId = null;
        _currentKOTReference = null;
      }
      return;
    }

    // Update KOT with current cart
    final totalAmount = state.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    Order? existingKOT;
    if (_currentKOTOrderId != null) {
      existingKOT = await orderRepo.getOrderById(_currentKOTOrderId!);
    } else if (_currentKOTReference != null && _currentKOTReference!.trim().isNotEmpty) {
      existingKOT = await orderRepo.getKOTByReference(_currentKOTReference!.trim());
    }
    if (existingKOT != null &&
        existingKOT.status.toLowerCase() == 'kot' &&
        existingKOT.cartId == _activeCartId) {
      final mergedHub = _hubMetadataWithDineInAnchor(existingKOT.hubMetadata);
      final updatedOrder = existingKOT.copyWith(
        totalAmount: totalAmount,
        finalAmount: totalAmount,
        cartId: _activeCartId!,
        hubMetadata: mergedHub != null ? Value<String?>(mergedHub) : const Value.absent(),
      );
      await orderRepo.updateOrder(updatedOrder);
    }
  }

  /// Load cart for editing an order (e.g. from Take Away Log). Does not persist as active cart.
  Future<void> loadCartFromOrder(int orderId) async {
    final order = await orderRepo.getOrderById(orderId);
    if (order == null) {
      return;
    }

    // Editing an order is not "new item" flow — clear session's active cart so we don't restore this later
    await _clearPersistedCartId();

    final appDb = locator<AppDatabase>();
    final frozenLines = await OrderLogCartFallback.resolve(
      order: order,
      db: appDb,
      cartRepo: cartRepo,
    );
    final existingOnCart = await cartRepo.getCartItemsByCartId(order.cartId) ?? [];
    for (final line in existingOnCart) {
      await cartRepo.removeCartItem(line.id);
    }
    for (final line in frozenLines) {
      await cartRepo.addItemToCart(
        order.cartId,
        CartItem(
          id: 0,
          cartId: order.cartId,
          itemId: line.itemId,
          itemName: line.itemName,
          itemVariantId: line.itemVariantId,
          itemToppingId: line.itemToppingId,
          quantity: line.quantity,
          total: line.total,
          discount: line.discount,
          discountType: line.discountType,
          notes: line.notes,
        ),
      );
    }
    final fromDb = await cartRepo.getCartItemsByCartId(order.cartId) ?? [];
    final resolvedLines = fromDb.isNotEmpty ? fromDb : frozenLines;

    // Clear any existing cart state first - do this AFTER loading to avoid race conditions
    _activeCartId = null;
    _invoiceNumber = null;
    _currentKOTReference = null;
    _currentKOTOrderId = null;
    _editingOrderId = null;
    _editingOrderStatus = null;

    _openedForEdit = true;
    _newlyAddedCartItemIds.clear();
    _kotPrintedCartItemIds.clear();
    _kotKitchenBaselineForDiff = null;

    // Set active cart
    _activeCartId = order.cartId;
    _invoiceNumber = order.invoiceNumber;

    _dineInFloorTableAnchor = null;
    if ((order.orderType ?? '').trim().toLowerCase() == 'dine_in') {
      final hubA = DineInRefParser.dineInAnchorFromHubMetadata(order.hubMetadata);
      final r = order.referenceNumber?.trim() ?? '';
      if (hubA != null && hubA.isNotEmpty) {
        _dineInFloorTableAnchor = hubA;
      } else if (r.isNotEmpty && DineInRefParser.extractLeadingFloorId(r) != null) {
        _dineInFloorTableAnchor = r;
      }
    }

    if (order.status == 'kot') {
      _currentKOTReference = order.referenceNumber;
      _currentKOTOrderId = order.id;
      _editingOrderId = order.id; // Pay will update this order (not create new)
      _editingOrderStatus = order.status;
    } else if (order.status == 'placed' || order.status == 'completed' || order.orderType == 'delivery') {
      // Delivery-log edit should always update the existing order, regardless of status.
      // Paid take-away edits also update existing order.
      _editingOrderId = order.id;
      _editingOrderStatus = order.status;
    }

    // Lines already on an open KOT ticket are treated as printed to kitchen.
    if (order.status == 'kot' && resolvedLines.isNotEmpty) {
      for (final ci in resolvedLines) {
        _kotPrintedCartItemIds.add(ci.id);
      }
      _kotKitchenBaselineForDiff = _kotSnapshotCart(resolvedLines);
    }

    // Emit the loaded cart items - this will trigger widget rebuilds
    emit(CartState(resolvedLines));
  }

  Future<List<String>> placeOrderWithPayment({
    required Map<String, dynamic> customerDetails,
    required Map<String, dynamic> discount,
    required Map<String, double> payments,
    String? onlineOrderNumber,
    bool printInvoice = true,
    bool printKot = false,
  }) async {
    if (state.items.isEmpty || _activeCartId == null) return [];

    // Apply cart discount if provided
    final discountValue = (discount['value'] as num?)?.toDouble() ?? 0.0;
    if (discountValue > 0) {
      final isPercentage = discount['type'] == 'percentage';
      await applyCartDiscount(discountValue, isPercentage);
    }

    // Calculate total amount from items (after clearing item discounts if cart discount applied)
    final totalAmount = state.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    final discountType = _cartDiscountType ?? discount['type'] as String?;
    final manualDiscountInput = _cartDiscountAmount > 0 ? _cartDiscountAmount : discountValue;
    final manualDiscountAmount = discountType == 'percentage'
        ? (totalAmount * (manualDiscountInput / 100)).clamp(0.0, totalAmount).toDouble()
        : manualDiscountInput.clamp(0.0, totalAmount).toDouble();
    final offer = _offerFromDiscountPayload(discount);
    final offerDiscountAmount = (offer?['discountAmount'] as num?)?.toDouble() ??
        (double.tryParse(offer?['discountAmount']?.toString() ?? '') ?? 0.0);
    final discountAmount = (manualDiscountAmount + offerDiscountAmount).clamp(0.0, totalAmount).toDouble();
    final finalAmount = (totalAmount - discountAmount).clamp(0.0, double.infinity);

    // Create order record (same invoice as cart / KOT if any).
    final invoiceNum = await _invoiceNumberForPersistedCart();
    final String? refNumber;
    if (orderType == OrderType.delivery && onlineOrderNumber != null && onlineOrderNumber.trim().isNotEmpty) {
      refNumber = onlineOrderNumber.trim();
    } else if (orderType == OrderType.dineIn) {
      refNumber = _staffKotReferenceForDb(_currentKOTReference);
    } else {
      final k = _currentKOTReference?.trim();
      refNumber = (k != null && k.isNotEmpty) ? k : invoiceNum;
    }
    final offerMeta = _withOfferMetadata(null, offer);
    final hubMeta = _hubMetadataWithDineInAnchor(offerMeta);
    final cashierId = await _sessionUserId();
    final branchId = await _sessionBranchId();
    final order = Order(
      id: 0,
      cartId: _activeCartId!,
      invoiceNumber: invoiceNum,
      referenceNumber: refNumber,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      discountType: discountAmount > 0 ? 'amount' : discountType,
      finalAmount: finalAmount,
      customerName: customerDetails['name'] as String?,
      customerEmail: customerDetails['email'] as String?,
      customerPhone: customerDetails['phone'] as String?,
      customerGender: customerDetails['gender'] as String?,
      cashAmount: payments['cash'] ?? 0.0,
      creditAmount: payments['credit'] ?? 0.0,
      cardAmount: payments['card'] ?? 0.0,
      onlineAmount: (payments['online'] ?? 0.0) + (payments['other'] ?? 0.0),
      createdAt: DateTime.now(),
      status: orderType == OrderType.delivery ? 'pending' : 'completed',
      orderType: orderType.value,
      deliveryPartner: deliveryPartner,
      userId: cashierId,
      branchId: branchId,
      hubMetadata: hubMeta,
      hubSyncPending: false,
    );

    emit(CartState(state.items, orderSubmitPending: true, orderSubmitError: null));
    try {
      final newId = await orderRepo.createOrder(order);
      final saved = await orderRepo.getOrderById(newId) ?? order;

      final printFailed = <String>[];
      printFailed.addAll(
        await openCashDrawerForCashPayment(
          resolveCashTenderForDrawer(payments, orderCashAmount: saved.cashAmount),
        ),
      );
      final ref = saved.referenceNumber?.trim().isNotEmpty == true ? saved.referenceNumber! : saved.invoiceNumber;
      if (printKot && state.items.isNotEmpty) {
        printFailed.addAll(
          await printService.printKOTPerKitchen(
            cartItems: state.items,
            order: saved,
            referenceNumber: ref,
            invoiceNumber: saved.invoiceNumber,
            branchId: saved.branchId,
            orderedAt: saved.createdAt,
          ),
        );
      }
      if (printInvoice) {
        printFailed.addAll(
          await printService.printFinalBill(
            order: saved,
            cartItems: state.items,
            asTaxInvoice: printInvoice,
          ),
        );
      }

      await _clearCartStateOnly();
      return printFailed;
    } catch (e) {
      emit(CartState(state.items, orderSubmitPending: false, orderSubmitError: e.toString()));
      rethrow;
    }
  }

  /// Update existing order (for editing paid orders)
  Future<void> updateExistingOrder() async {
    if (state.items.isEmpty || _activeCartId == null || _editingOrderId == null) return;

    // Get the existing order
    final existingOrder = await orderRepo.getOrderById(_editingOrderId!);
    if (existingOrder == null) return;

    // Calculate total amount from items
    final totalAmount = state.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    // Calculate final amount with cart discount
    double finalAmount;
    if (_cartDiscountType == 'percentage') {
      finalAmount = (totalAmount * (1 - _cartDiscountAmount / 100)).clamp(0.0, double.infinity);
    } else {
      finalAmount = (totalAmount - _cartDiscountAmount).clamp(0.0, double.infinity);
    }

    // Update order with new totals using OrdersCompanion
    final updatedOrder = Order(
      id: existingOrder.id,
      cartId: _activeCartId!,
      invoiceNumber: existingOrder.invoiceNumber,
      referenceNumber: existingOrder.referenceNumber,
      totalAmount: totalAmount,
      discountAmount: _cartDiscountAmount > 0 ? _cartDiscountAmount : existingOrder.discountAmount,
      discountType: _cartDiscountType ?? existingOrder.discountType,
      finalAmount: finalAmount,
      customerName: existingOrder.customerName,
      customerEmail: existingOrder.customerEmail,
      customerPhone: existingOrder.customerPhone,
      customerGender: existingOrder.customerGender,
      cashAmount: existingOrder.cashAmount,
      creditAmount: existingOrder.creditAmount,
      cardAmount: existingOrder.cardAmount,
      onlineAmount: existingOrder.onlineAmount,
      createdAt: existingOrder.createdAt,
      status: existingOrder.status,
      orderType: existingOrder.orderType,
      deliveryPartner: existingOrder.deliveryPartner,
      userId: existingOrder.userId,
      branchId: existingOrder.branchId,
      serverOrderId: existingOrder.serverOrderId,
      hubMetadata: existingOrder.hubMetadata,
      hubSyncPending: existingOrder.hubSyncPending,
    );

    // Update order in database
    await orderRepo.updateOrder(updatedOrder);

    // Clear editing state but keep cart loaded
    _editingOrderId = null;
    _editingOrderStatus = null;
  }

  /// Update existing order with payment details (for editing paid orders)
  Future<List<String>> updateOrderWithPayment({
    required Map<String, dynamic> customerDetails,
    required Map<String, dynamic> discount,
    required Map<String, double> payments,
    String? onlineOrderNumber,
    bool printInvoice = true,
    bool printKot = false,
  }) async {
    if (state.items.isEmpty || _activeCartId == null || _editingOrderId == null) return [];

    // Apply cart discount if provided
    final discountValue = (discount['value'] as num?)?.toDouble() ?? 0.0;
    if (discountValue > 0) {
      final isPercentage = discount['type'] == 'percentage';
      await applyCartDiscount(discountValue, isPercentage);
    }

    // Get the existing order
    final existingOrder = await orderRepo.getOrderById(_editingOrderId!);
    if (existingOrder == null) return [];

    // Calculate total amount from items
    final totalAmount = state.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    final discountType = _cartDiscountType ?? discount['type'] as String?;
    final manualDiscountInput = _cartDiscountAmount > 0 ? _cartDiscountAmount : discountValue;
    final manualDiscountAmount = discountType == 'percentage'
        ? (totalAmount * (manualDiscountInput / 100)).clamp(0.0, totalAmount).toDouble()
        : manualDiscountInput.clamp(0.0, totalAmount).toDouble();
    final offer = _offerFromDiscountPayload(discount);
    final offerDiscountAmount = (offer?['discountAmount'] as num?)?.toDouble() ??
        (double.tryParse(offer?['discountAmount']?.toString() ?? '') ?? 0.0);
    final discountAmount = (manualDiscountAmount + offerDiscountAmount).clamp(0.0, totalAmount).toDouble();
    final finalAmount = (totalAmount - discountAmount).clamp(0.0, double.infinity);

    // Update order with new totals and payment details
    final refNumber = existingOrder.orderType == 'delivery' && onlineOrderNumber != null && onlineOrderNumber.isNotEmpty ? onlineOrderNumber : existingOrder.referenceNumber;
    final deliveryStatus =
        existingOrder.orderType == 'delivery' ? existingOrder.status : 'completed';

    final updatedOrder = Order(
      id: existingOrder.id,
      cartId: _activeCartId!,
      invoiceNumber: existingOrder.invoiceNumber,
      referenceNumber: refNumber,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      discountType: discountAmount > 0 ? 'amount' : discountType,
      finalAmount: finalAmount,
      customerName: customerDetails['name'] as String?,
      customerEmail: customerDetails['email'] as String?,
      customerPhone: customerDetails['phone'] as String?,
      customerGender: customerDetails['gender'] as String?,
      cashAmount: payments['cash'] ?? 0.0,
      creditAmount: payments['credit'] ?? 0.0,
      cardAmount: payments['card'] ?? 0.0,
      onlineAmount: (payments['online'] ?? 0.0) + (payments['other'] ?? 0.0),
      createdAt: existingOrder.createdAt,
      status: deliveryStatus,
      orderType: existingOrder.orderType,
      deliveryPartner: existingOrder.deliveryPartner,
      userId: existingOrder.userId,
      branchId: existingOrder.branchId,
      serverOrderId: existingOrder.serverOrderId,
      hubMetadata: _withOfferMetadata(existingOrder.hubMetadata, offer),
      hubSyncPending: existingOrder.hubSyncPending,
    );

    // Update order in database
    await orderRepo.updateOrder(updatedOrder);

    final printFailed = <String>[];
    printFailed.addAll(
      await openCashDrawerForCashPayment(
        resolveCashTenderForDrawer(payments, orderCashAmount: updatedOrder.cashAmount),
      ),
    );
    final ref = updatedOrder.referenceNumber?.trim().isNotEmpty == true ? updatedOrder.referenceNumber! : updatedOrder.invoiceNumber;
    if (printKot && state.items.isNotEmpty) {
      final snap = List<CartItem>.from(state.items);
      if (_kotKitchenBaselineForDiff != null) {
        final rows = KotKitchenUpdateDiff.compute(_kotKitchenBaselineForDiff!, snap);
        if (rows.isNotEmpty) {
          printFailed.addAll(
            await printService.printKOTUpdatePerKitchen(
              rows: rows,
              orderTypeRaw: updatedOrder.orderType,
              referenceNumber: ref,
              invoiceNumber: updatedOrder.invoiceNumber,
              branchId: updatedOrder.branchId,
              orderedAt: updatedOrder.createdAt,
            ),
          );
        }
      } else {
        printFailed.addAll(
          await printService.printKOTPerKitchen(
            cartItems: snap,
            order: updatedOrder,
            referenceNumber: ref,
            invoiceNumber: updatedOrder.invoiceNumber,
            branchId: updatedOrder.branchId,
            orderedAt: updatedOrder.createdAt,
          ),
        );
      }
      _kotKitchenBaselineForDiff = _kotSnapshotCart(snap);
    }
    if (printInvoice) {
      printFailed.addAll(
        await printService.printFinalBill(
          order: updatedOrder,
          cartItems: state.items,
          asTaxInvoice: printInvoice,
        ),
      );
    }

    // Clear state only - keep cart + items in DB for order history (Recent Sales View)
    _editingOrderId = null;
    _editingOrderStatus = null;
    await _clearCartStateOnly();
    return printFailed;
  }

  Future<void> applyDiscount(
    CartItem cartItem,
    double value,
    bool isPercentage, {
    String? notes,
  }) async {
    final index = state.items.indexWhere((e) => e.id == cartItem.id);
    if (index == -1) return;

    // Clear cart discount when item discount is applied
    if (_cartDiscountAmount > 0) {
      await clearCartDiscount();
    }

    final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
    if (item == null) return;

    ItemVariant? variant;
    if (cartItem.itemVariantId != null) {
      variant = await itemRepo.fetchVariantById(cartItem.itemVariantId!);
    }

    // Calculate from original price (without any existing discount)
    final unitPrice = variant?.price ?? item.price;

    // Get toppings total from notes if exists
    double toppingsTotal = 0;
    final toppingsData = getToppingsFromCartItem(cartItem);
    if (toppingsData != null && toppingsData.isNotEmpty) {
      for (var topping in toppingsData) {
        final price = (topping['price'] ?? 0.0) as double;
        final qty = (topping['qty'] ?? 1) as int;
        toppingsTotal += price * qty;
      }
    }

    final baseSubtotal = unitPrice + toppingsTotal;
    final subtotal = baseSubtotal * cartItem.quantity;
    final discount = isPercentage ? subtotal * (value / 100) : value;
    final newTotal = subtotal - discount;

    final updatedItem = cartItem.copyWith(
      discount: discount,
      discountType: Value(isPercentage ? 'percentage' : 'amount'),
      notes: Value(notes ?? cartItem.notes),
      total: newTotal,
    );

    await cartRepo.updateCartItem(updatedItem);
    await _loadCartItems();
  }

  /// Free-text line notes stored in [CartItem.notes] alongside toppings: either plain text, a JSON
  /// array of toppings, or `{"toppings":[...], "lineNote":"..."}` when both are set.
  Future<void> updateCartItemLineNotes(CartItem cartItem, String? text) async {
    final trimmed = text?.trim();
    final line = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    final existingToppings = getToppingsFromCartItem(cartItem);
    final newNotes = _serializeCartNotes(
      toppings: existingToppings,
      lineNote: line,
    );
    final updated = cartItem.copyWith(notes: Value(newNotes));
    await cartRepo.updateCartItem(updated);
    await _loadCartItems();
  }

  /// User-entered line note, or `null` if the field only holds toppings JSON with no [lineNote].
  String? getLineNoteFromCartItem(CartItem cartItem) {
    final n = cartItem.notes;
    if (n == null || n.isEmpty) return null;
    final t = n.trimLeft();
    if (t.startsWith('[')) return null;
    if (t.startsWith('{')) {
      try {
        final d = jsonDecode(n);
        if (d is Map) {
          final note = d['lineNote'];
          if (note is String && note.trim().isNotEmpty) return note.trim();
        }
      } catch (_) {
        return null;
      }
      return null;
    }
    return n.trim();
  }

  Future<void> applyCartDiscount(double value, bool isPercentage) async {
    // Clear all item discounts when cart discount is applied
    if (state.items.isNotEmpty) {
      await _clearAllItemDiscounts();
    }

    _cartDiscountAmount = value;
    _cartDiscountType = isPercentage ? 'percentage' : 'amount';

    await _loadCartItems();
  }

  Future<void> clearCartDiscount() async {
    _cartDiscountAmount = 0.0;
    _cartDiscountType = null;
  }

  Future<void> _clearAllItemDiscounts() async {
    if (_activeCartId == null) return;

    // Recalculate all items from original price without discounts
    for (final cartItem in state.items) {
      final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
      if (item == null) continue;

      ItemVariant? variant;
      if (cartItem.itemVariantId != null) {
        variant = await itemRepo.fetchVariantById(cartItem.itemVariantId!);
      }

      // Calculate from original price
      final unitPrice = variant?.price ?? item.price;

      // Get toppings total from notes
      double toppingsTotal = 0;
      final toppingsData = getToppingsFromCartItem(cartItem);
      if (toppingsData != null && toppingsData.isNotEmpty) {
        for (var topping in toppingsData) {
          final price = (topping['price'] ?? 0.0) as double;
          final qty = (topping['qty'] ?? 1) as int;
          toppingsTotal += price * qty;
        }
      }

      final baseSubtotal = unitPrice + toppingsTotal;
      final newTotal = baseSubtotal * cartItem.quantity;

      final updatedItem = cartItem.copyWith(
        discount: 0.0,
        discountType: const Value.absent(),
        total: newTotal,
      );

      await cartRepo.updateCartItem(updatedItem);
    }

    await _loadCartItems();
  }

  void addItemWithVariant(
    Item item,
    ItemVariant? variant,
    int qty,
  ) {
    // create cart item with variant + qty
  }

  Future<void> addItemWithVariantAndToppings(
    Item item,
    ItemVariant? variant,
    int qty,
    Map<ItemTopping, int> toppings,
  ) async {
    // 1️⃣ Ensure cart exists
    await _ensureCart();

    // 2️⃣ Calculate unit price
    final unitPrice = variant?.price ?? item.price;

    // 3️⃣ Calculate toppings total and store as JSON
    // Filter out toppings with qty <= 0
    final validToppings = Map<ItemTopping, int>.fromEntries(
      toppings.entries.where((e) => e.value > 0),
    );

    double toppingsTotal = 0;
    ItemTopping? firstTopping;
    String? toppingsJson;
    if (validToppings.isNotEmpty) {
      final toppingsList = validToppings.entries
          .map((e) => {
                'id': e.key.id,
                'name': e.key.name,
                'price': e.key.price,
                'qty': e.value,
              })
          .toList();
      toppingsJson = _serializeCartNotes(toppings: toppingsList, lineNote: null);

      validToppings.forEach((topping, toppingQty) {
        toppingsTotal += topping.price * toppingQty;
        firstTopping ??= topping;
      });
    } else {
      // If no valid toppings, don't store JSON
      toppingsJson = null;
    }

    // 4️⃣ Calculate total: (unitPrice + toppingsTotal) * quantity - discount
    final baseSubtotal = unitPrice + toppingsTotal;
    final total = (baseSubtotal * qty);

    // 5️⃣ Create cart item
    final cartItem = CartItem(
      id: 0,
      total: total,
      cartId: _activeCartId ?? 0,
      itemId: item.id,
      itemName: item.name,
      itemVariantId: variant?.id,
      itemToppingId: firstTopping?.id, // Store first topping's ID for backward compatibility
      quantity: qty,
      discount: 0,
      notes: toppingsJson, // Store all toppings as JSON in notes
    );

    // 6️⃣ Save to DB
    final newId = await cartRepo.addItemToCart(_activeCartId!, cartItem);
    _newlyAddedCartItemIds.add(newId);

    // 7️⃣ Reload cart items
    await _loadCartItems();

    // 8️⃣ Update KOT if exists
    await _updateKOTIfExists();
  }

  Future<void> updateCartItemToppings(
    int cartItemId,
    Map<ItemTopping, int> toppings,
  ) async {
    final cartItem = state.items.firstWhere(
      (item) => item.id == cartItemId,
      orElse: () => throw StateError('Cart item not found'),
    );
    final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
    if (item == null) return;

    final previousLine = getLineNoteFromCartItem(cartItem);

    ItemVariant? variant;
    if (cartItem.itemVariantId != null) {
      variant = await itemRepo.fetchVariantById(cartItem.itemVariantId!);
    }

    final unitPrice = variant?.price ?? item.price;

    // Calculate toppings total and store as JSON
    // Filter out toppings with qty <= 0
    final validToppings = Map<ItemTopping, int>.fromEntries(
      toppings.entries.where((e) => e.value > 0),
    );

    double toppingsTotal = 0;
    ItemTopping? firstTopping;
    String? toppingsJson;
    if (validToppings.isNotEmpty) {
      final toppingsList = validToppings.entries
          .map((e) => {
                'id': e.key.id,
                'name': e.key.name,
                'price': e.key.price,
                'qty': e.value,
              })
          .toList();
      toppingsJson = _serializeCartNotes(
        toppings: toppingsList,
        lineNote: previousLine,
      );

      validToppings.forEach((topping, toppingQty) {
        toppingsTotal += topping.price * toppingQty;
        firstTopping ??= topping;
      });
    } else {
      toppingsJson = (previousLine != null && previousLine.isNotEmpty) ? previousLine : null;
    }

    // Calculate new total: (unitPrice + toppingsTotal) * quantity - existing discount
    final baseSubtotal = unitPrice + toppingsTotal;
    final newTotal = (baseSubtotal * cartItem.quantity) - cartItem.discount;

    final updatedItem = cartItem.copyWith(
      itemToppingId: Value(firstTopping?.id),
      total: newTotal,
      notes: Value(toppingsJson),
    );

    await cartRepo.updateCartItem(updatedItem);
    await _loadCartItems();
    await _updateKOTIfExists();
  }

  String? _serializeCartNotes({
    required List<Map<String, dynamic>>? toppings,
    String? lineNote,
  }) {
    final trimmed = lineNote?.trim();
    final hasToppings = toppings != null && toppings.isNotEmpty;
    final hasLine = trimmed != null && trimmed.isNotEmpty;
    if (hasToppings && hasLine) {
      return jsonEncode({'toppings': toppings, 'lineNote': trimmed});
    }
    if (hasToppings) {
      return jsonEncode(toppings);
    }
    if (hasLine) {
      return trimmed;
    }
    return null;
  }

  List<Map<String, dynamic>>? _decodeToppingsJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        final toppingsList = decoded.cast<Map<String, dynamic>>().where((topping) => (topping['qty'] as int? ?? 0) > 0).toList();
        return toppingsList.isEmpty ? null : toppingsList;
      }
      if (decoded is Map) {
        final top = decoded['toppings'];
        if (top is List) {
          final toppingsList = top.cast<Map<String, dynamic>>().where((e) => (e['qty'] as int? ?? 0) > 0).toList();
          return toppingsList.isEmpty ? null : toppingsList;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>>? getToppingsFromCartItem(CartItem cartItem) {
    return _decodeToppingsJson(cartItem.notes);
  }
}
