import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/data/repository/item_repository.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(
    this.cartRepo,
    this.itemRepo,
    this.orderRepo,
    this.sessionDao,
    this.printService,
  ) : super(CartState([]));
  final CartRepository cartRepo;
  final ItemRepository itemRepo;
  final OrderRepository orderRepo;
  final SessionDao sessionDao;
  final PrintService printService;
  int? _activeCartId;
  String? _invoiceNumber;
  String? _currentKOTReference;
  int? _currentKOTOrderId;
  int? _editingOrderId; // Track order ID when editing a paid order
  String? _editingOrderStatus; // Track order status when editing
  bool _openedForEdit = false; // True when screen was opened from Take Away Log (edit order)

  // Cart-level discount (mutually exclusive with item discounts)
  double _cartDiscountAmount = 0.0;
  String? _cartDiscountType; // 'amount' or 'percentage'

  String? get currentKOTReference => _currentKOTReference;
  bool get isEditingPaidOrder => _editingOrderId != null && (_editingOrderStatus == 'placed' || _editingOrderStatus == 'completed');

  /// True when this screen was opened for editing an order (e.g. from Take Away Log). Hide reference/KOT popup.
  bool get isOpenedForEdit => _openedForEdit;

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
      itemVariantId: selectedVariant?.id,
      itemToppingId: null,
      quantity: quantity,
      discount: 0,
    );

    // 4️⃣ Save to DB
    await cartRepo.addItemToCart(_activeCartId!, cartItem);

    // 5️⃣ Reload cart items
    await _loadCartItems();

    // 6️⃣ Update KOT if exists
    await _updateKOTIfExists();
  }

  Future<void> _loadCartItems() async {
    if (_activeCartId == null) {
      emit(CartState([]));
      return;
    }

    final items = await cartRepo.getCartItemsByCartId(_activeCartId!);
    emit(CartState(items ?? []));
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

  Future<void> _ensureCart() async {
    if (_activeCartId != null) return;

    final invoice = _generateInvoiceNumber();

    _activeCartId = await cartRepo.createCart(invoice);
    _invoiceNumber = invoice;
    await _persistActiveCartId(_activeCartId!);
  }

  Future<void> _persistActiveCartId(int cartId) async {
    await sessionDao.setActiveCartId(cartId);
  }

  Future<void> _clearPersistedCartId() async {
    await sessionDao.setActiveCartId(null);
  }

  /// Restore cart from session's active cart id (Drift as single source of truth).
  /// Call when opening Take Away screen without an orderId.
  Future<void> loadActiveCart() async {
    final cartId = await sessionDao.getActiveCartId();
    if (cartId == null) return;

    final cart = await cartRepo.getCartByCartId(cartId);
    if (cart == null) {
      await sessionDao.setActiveCartId(null);
      return;
    }

    _activeCartId = cart.id;
    _invoiceNumber = cart.invoiceNumber;
    await _loadCartItems();
  }

  Future<void> removeItem(int index, BuildContext? context) async {
    if (index < 0 || index >= state.items.length) return;
    await removeItemByCartItemId(state.items[index].id);
  }

  Future<void> removeItemByCartItemId(int cartItemId) async {
    await cartRepo.removeCartItem(cartItemId);
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
    _editingOrderId = null;
    _editingOrderStatus = null;
    _openedForEdit = false;
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
    _editingOrderId = null;
    _editingOrderStatus = null;
    _openedForEdit = false;
    _cartDiscountAmount = 0.0;
    _cartDiscountType = null;
    emit(CartState([]));
  }

  Future<void> saveKOT(String referenceNumber) async {
    if (state.items.isEmpty || _activeCartId == null) return;

    // Calculate total amount
    final totalAmount = state.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    // Check if KOT already exists with this reference
    final existingKOT = await orderRepo.getKOTByReference(referenceNumber);

    if (existingKOT != null && existingKOT.id == _currentKOTOrderId) {
      // Update existing KOT (same reference, same order)
      final updatedOrder = existingKOT.copyWith(
        totalAmount: totalAmount,
        finalAmount: totalAmount,
        cartId: _activeCartId!,
      );
      await orderRepo.updateOrder(updatedOrder);
      _currentKOTOrderId = existingKOT.id;
    } else {
      // Create new KOT - always generate new invoice number for new KOT
      final order = Order(
        id: 0,
        cartId: _activeCartId!,
        invoiceNumber: _generateInvoiceNumber(),
        referenceNumber: referenceNumber,
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
        createdAt: DateTime.now(),
        status: 'kot',
      );
      final orderId = await orderRepo.createOrder(order);
      _currentKOTOrderId = orderId;
    }

    _currentKOTReference = referenceNumber;

    // Print KOT to each kitchen's printer (before clearing cart)
    await printService.printKOTPerKitchen(
      cartItems: state.items,
      referenceNumber: referenceNumber,
    );

    // Clear the cart state but keep cart in DB for editing
    _activeCartId = null;
    _invoiceNumber = null;
    emit(CartState([]));
  }

  /// Save KOT using the already defined reference (edit only). No reference dialog.
  Future<void> saveKOTWithExistingReference() async {
    if (_currentKOTReference == null || _currentKOTReference!.isEmpty) return;
    await saveKOT(_currentKOTReference!);
  }

  Future<void> _updateKOTIfExists() async {
    if (_currentKOTReference == null || _activeCartId == null) return;

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

    final existingKOT = await orderRepo.getKOTByReference(_currentKOTReference!);
    if (existingKOT != null) {
      final updatedOrder = existingKOT.copyWith(
        totalAmount: totalAmount,
        finalAmount: totalAmount,
        cartId: _activeCartId!,
      );
      await orderRepo.updateOrder(updatedOrder);
    }
  }

  /// Load cart for editing an order (e.g. from Take Away Log). Does not persist as active cart.
  Future<void> loadCartFromOrder(int orderId) async {
    final order = await orderRepo.getOrderById(orderId);
    if (order == null) return;

    // Editing an order is not "new item" flow — clear session's active cart so we don't restore this later
    await _clearPersistedCartId();

    // Load cart items first
    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);

    // Clear any existing cart state first - do this AFTER loading to avoid race conditions
    _activeCartId = null;
    _invoiceNumber = null;
    _currentKOTReference = null;
    _currentKOTOrderId = null;
    _editingOrderId = null;
    _editingOrderStatus = null;

    _openedForEdit = true;

    // Set active cart
    _activeCartId = order.cartId;
    _invoiceNumber = order.invoiceNumber;

    if (order.status == 'kot') {
      _currentKOTReference = order.referenceNumber;
      _currentKOTOrderId = order.id;
      _editingOrderId = order.id; // Pay will update this order (not create new)
      _editingOrderStatus = order.status;
    } else if (order.status == 'placed' || order.status == 'completed') {
      // Track that we're editing a paid order
      _editingOrderId = order.id;
      _editingOrderStatus = order.status;
    }

    // Emit the loaded cart items - this will trigger widget rebuilds
    emit(CartState(cartItems ?? []));
  }

  Future<void> placeOrderWithPayment({
    required Map<String, dynamic> customerDetails,
    required Map<String, dynamic> discount,
    required Map<String, double> payments,
  }) async {
    if (state.items.isEmpty || _activeCartId == null) return;

    // Apply cart discount if provided
    final discountValue = discount['value'] as double;
    if (discountValue > 0) {
      final isPercentage = discount['type'] == 'percentage';
      await applyCartDiscount(discountValue, isPercentage);
    }

    // Calculate total amount from items (after clearing item discounts if cart discount applied)
    final totalAmount = state.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    // Calculate final amount with cart discount
    final discountAmount = _cartDiscountAmount > 0 ? _cartDiscountAmount : discountValue;
    double finalAmount;
    if (_cartDiscountType == 'percentage') {
      finalAmount = (totalAmount * (1 - discountAmount / 100)).clamp(0.0, double.infinity);
    } else {
      finalAmount = (totalAmount - discountAmount).clamp(0.0, double.infinity);
    }

    // Create order record
    final invoiceNum = _invoiceNumber ?? _generateInvoiceNumber();
    final order = Order(
      id: 0,
      cartId: _activeCartId!,
      invoiceNumber: invoiceNum,
      referenceNumber: _currentKOTReference ?? invoiceNum, // Use KOT ref if paying KOT, else invoice for display
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      discountType: _cartDiscountType ?? discount['type'] as String?,
      finalAmount: finalAmount,
      customerName: customerDetails['name'] as String?,
      customerEmail: customerDetails['email'] as String?,
      customerPhone: customerDetails['phone'] as String?,
      customerGender: customerDetails['gender'] as String?,
      cashAmount: payments['cash'] ?? 0.0,
      creditAmount: payments['credit'] ?? 0.0,
      cardAmount: payments['card'] ?? 0.0,
      createdAt: DateTime.now(),
      status: 'completed',
    );

    // Save order to database
    await orderRepo.createOrder(order);

    // Print final bill to bill printer
    await printService.printFinalBill(order: order, cartItems: state.items);

    // Clear state only - keep cart + items in DB for order history (Recent Sales View)
    await _clearCartStateOnly();
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
      createdAt: existingOrder.createdAt,
      status: existingOrder.status,
    );

    // Update order in database
    await orderRepo.updateOrder(updatedOrder);

    // Clear editing state but keep cart loaded
    _editingOrderId = null;
    _editingOrderStatus = null;
  }

  /// Update existing order with payment details (for editing paid orders)
  Future<void> updateOrderWithPayment({
    required Map<String, dynamic> customerDetails,
    required Map<String, dynamic> discount,
    required Map<String, double> payments,
  }) async {
    if (state.items.isEmpty || _activeCartId == null || _editingOrderId == null) return;

    // Apply cart discount if provided
    final discountValue = discount['value'] as double;
    if (discountValue > 0) {
      final isPercentage = discount['type'] == 'percentage';
      await applyCartDiscount(discountValue, isPercentage);
    }

    // Get the existing order
    final existingOrder = await orderRepo.getOrderById(_editingOrderId!);
    if (existingOrder == null) return;

    // Calculate total amount from items
    final totalAmount = state.items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    // Calculate final amount with cart discount
    final discountAmount = _cartDiscountAmount > 0 ? _cartDiscountAmount : discountValue;
    double finalAmount;
    if (_cartDiscountType == 'percentage') {
      finalAmount = (totalAmount * (1 - discountAmount / 100)).clamp(0.0, double.infinity);
    } else {
      finalAmount = (totalAmount - discountAmount).clamp(0.0, double.infinity);
    }

    // Update order with new totals and payment details
    final updatedOrder = Order(
      id: existingOrder.id,
      cartId: _activeCartId!,
      invoiceNumber: existingOrder.invoiceNumber,
      referenceNumber: existingOrder.referenceNumber,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      discountType: _cartDiscountType ?? discount['type'] as String?,
      finalAmount: finalAmount,
      customerName: customerDetails['name'] as String?,
      customerEmail: customerDetails['email'] as String?,
      customerPhone: customerDetails['phone'] as String?,
      customerGender: customerDetails['gender'] as String?,
      cashAmount: payments['cash'] ?? 0.0,
      creditAmount: payments['credit'] ?? 0.0,
      cardAmount: payments['card'] ?? 0.0,
      createdAt: existingOrder.createdAt,
      status: 'completed', // Payment completed = move to Recent Sales (out of Take Away Log)
    );

    // Update order in database
    await orderRepo.updateOrder(updatedOrder);

    // Print final bill (updated order)
    await printService.printFinalBill(order: updatedOrder, cartItems: state.items);

    // Clear state only - keep cart + items in DB for order history (Recent Sales View)
    _editingOrderId = null;
    _editingOrderStatus = null;
    await _clearCartStateOnly();
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    // Add a random component to ensure uniqueness even when called in quick succession
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'INV-${now.millisecondsSinceEpoch}-$random';
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
      toppingsJson = _encodeToppingsJson(toppingsList);

      validToppings.forEach((topping, toppingQty) {
        toppingsTotal += topping.price * toppingQty;
        if (firstTopping == null) {
          firstTopping = topping;
        }
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
      itemVariantId: variant?.id,
      itemToppingId: firstTopping?.id, // Store first topping's ID for backward compatibility
      quantity: qty,
      discount: 0,
      notes: toppingsJson, // Store all toppings as JSON in notes
    );

    // 6️⃣ Save to DB
    await cartRepo.addItemToCart(_activeCartId!, cartItem);

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
      toppingsJson = _encodeToppingsJson(toppingsList);

      validToppings.forEach((topping, toppingQty) {
        toppingsTotal += topping.price * toppingQty;
        if (firstTopping == null) {
          firstTopping = topping;
        }
      });
    } else {
      // If all toppings are removed, clear the notes field
      toppingsJson = null;
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

  String? _encodeToppingsJson(List<Map<String, dynamic>> toppings) {
    try {
      return jsonEncode(toppings);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>>? _decodeToppingsJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        // Filter out toppings with qty <= 0
        final toppingsList = decoded.cast<Map<String, dynamic>>().where((topping) => (topping['qty'] as int? ?? 0) > 0).toList();
        return toppingsList.isEmpty ? null : toppingsList;
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
