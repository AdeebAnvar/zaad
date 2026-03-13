import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_expansion_card/multi_expansion_card.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_item_tile.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key, this.scrollController});

  /// Optional scroll controller for use in DraggableScrollableSheet (mobile).
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final itemCount = state.items.length;

        final totalAmount = state.items.fold<double>(0, (s, e) => s + e.total);

        return Stack(
          children: [
            // ───────────── CART LIST ─────────────
            Container(
              padding: const EdgeInsets.fromLTRB(AppPadding.screenHorizontal, 12, AppPadding.screenHorizontal, 90),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: state.items.isEmpty
                  ? Center(
                      child: Text(
                        "Cart is empty",
                        style: AppStyles.getRegularTextStyle(fontSize: 16),
                      ),
                    )
                  : CustomScrollView(
                      controller: scrollController,
                      key: ValueKey('cart_list_${state.items.map((e) => e.id).join('_')}'),
                      slivers: [
                        // Total payable at top (always visible when list is at top)

                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cartItem = state.items[index];
                              return CartItemTile(
                                index: index,
                                key: ValueKey('cart_item_${cartItem.id}_${cartItem.total}_${cartItem.quantity}'),
                                cartItem: cartItem,
                              );
                            },
                            childCount: state.items.length,
                          ),
                        ),
                      ],
                    ),
            ),

            // ───────────── BOTTOM SUMMARY BAR ─────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.screenHorizontal, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // TOTAL PAYABLE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$itemCount item${itemCount == 1 ? '' : 's'}",
                            style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          Text(
                            "Total payable",
                            style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          Text(
                            "₹ ${totalAmount.toStringAsFixed(2)}",
                            style: AppStyles.getBoldTextStyle(fontSize: 18),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Show different buttons based on editing mode
                      BlocBuilder<CartCubit, CartState>(
                        builder: (context, cartState) {
                          final cartCubit = context.read<CartCubit>();
                          final isEditingPaidOrder = cartCubit.isEditingPaidOrder;
                          final isOpenedForEdit = cartCubit.isOpenedForEdit;

                          if (isEditingPaidOrder) {
                            // When editing a paid order, only show Save button
                            return CustomButton(
                              width: 150,
                              onPressed: state.items.isEmpty ? () {} : () => _showPaymentDialog(context, totalAmount, isEditing: true),
                              text: "Save",
                            );
                          }
                          // Edit and normal: show KOT and Pay. In edit, KOT/Pay don't show ref popup (use existing ref for KOT).
                          return Row(
                            children: [
                              CustomButton(
                                width: 120,
                                onPressed: state.items.isEmpty
                                    ? () {}
                                    : () async {
                                        if (isOpenedForEdit) {
                                          final hasRef = cartCubit.currentKOTReference != null && cartCubit.currentKOTReference!.trim().isNotEmpty;
                                          if (hasRef) {
                                            try {
                                              await cartCubit.saveKOTWithExistingReference();
                                              if (context.mounted) Navigator.pop(context);
                                            } catch (e) {
                                              if (context.mounted) showErrorDialog(context, e);
                                            }
                                          }
                                        } else {
                                          showKOTDialog(context);
                                        }
                                      },
                                text: "KOT",
                              ),
                              const SizedBox(width: 12),
                              CustomButton(
                                width: 150,
                                onPressed: state.items.isEmpty ? () {} : () => _showPaymentDialog(context, totalAmount, isEditing: isOpenedForEdit),
                                text: "Pay",
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showKOTDialog(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    final currentReference = cartCubit.currentKOTReference;
    final referenceController = TextEditingController(text: currentReference ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.of(context).size.width;

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width > 600 ? 420 : width * 0.95,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentReference == null ? 'Add KOT Reference' : 'Edit KOT Reference',
                                  style: AppStyles.getBoldTextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Used for kitchen order tracking',
                                  style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Input
                      CustomTextField(
                        controller: referenceController,
                        labelText: 'Reference Number',
                        // autoFocus: true,
                      ),

                      const SizedBox(height: 28),

                      /// Actions
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          CustomButton(
                            width: 120,
                            text: 'Save',
                            onPressed: () async {
                              final value = referenceController.text.trim();
                              if (value.isNotEmpty) {
                                try {
                                  await cartCubit.saveKOT(value);
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    showErrorDialog(context, e);
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, double totalAmount, {bool isEditing = false}) {
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentDialog(
        totalAmount: totalAmount,
        onSave: (customerDetails, discount, payments) async {
          try {
            final cartCubit = context.read<CartCubit>();
            if (isEditing) {
              await cartCubit.updateOrderWithPayment(
                customerDetails: customerDetails,
                discount: discount,
                payments: payments,
              );
            } else {
              await cartCubit.placeOrderWithPayment(
                customerDetails: customerDetails,
                discount: discount,
                payments: payments,
              );
            }
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
              if (isEditing && context.mounted) {
                Navigator.pop(context);
              }
            }
          } catch (e) {
            if (dialogContext.mounted) {
              showErrorDialog(dialogContext, e);
            }
          }
        },
      ),
    );
  }
}

// Payment Dialog Widget

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(
    Map<String, dynamic> customer,
    Map<String, dynamic> discount,
    Map<String, double> payments,
  ) onSave;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onSave,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _genderController = TextEditingController();

  final _discountAmountController = TextEditingController();
  final _discountPercentController = TextEditingController();

  final _cashController = TextEditingController();
  final _creditController = TextEditingController();
  final _cardController = TextEditingController();

  final _cashFocusNode = FocusNode();
  final _cardFocusNode = FocusNode();
  final _creditFocusNode = FocusNode();

  String _discountType = 'amount';
  double _discountValue = 0;
  double _finalAmount = 0;

  final CustomerRepository _customerRepo = locator<CustomerRepository>();
  List<CustomerModel> _allCustomers = [];
  bool _loadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _finalAmount = widget.totalAmount;
    _updateFinalAmount();
    _loadCustomers();
    _cashFocusNode.addListener(_onPaymentFocusCash);
    _cardFocusNode.addListener(_onPaymentFocusCard);
    _creditFocusNode.addListener(_onPaymentFocusCredit);
  }

  /// When a payment field gets focus, set its value to remaining amount (amount payable - other two).
  void _onPaymentFocusCash() {
    if (!_cashFocusNode.hasFocus) return;
    _setPaymentFieldToRemainder(_cashController, _cardController, _creditController);
  }

  void _onPaymentFocusCard() {
    if (!_cardFocusNode.hasFocus) return;
    _setPaymentFieldToRemainder(_cardController, _cashController, _creditController);
  }

  void _onPaymentFocusCredit() {
    if (!_creditFocusNode.hasFocus) return;
    _setPaymentFieldToRemainder(_creditController, _cashController, _cardController);
  }

  void _setPaymentFieldToRemainder(
    TextEditingController target,
    TextEditingController other1,
    TextEditingController other2,
  ) {
    final o1 = double.tryParse(other1.text.trim()) ?? 0;
    final o2 = double.tryParse(other2.text.trim()) ?? 0;
    final remainder = (_finalAmount - o1 - o2).clamp(0.0, double.infinity);
    target.text = remainder.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);
    try {
      final customers = await _customerRepo.getAllLocalCustomers();
      setState(() {
        _allCustomers = customers;
        _loadingCustomers = false;
      });
    } catch (e) {
      setState(() => _loadingCustomers = false);
    }
  }

  void _prefillCustomer(CustomerModel customer) {
    setState(() {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _genderController.text = customer.gender ?? '';
    });
  }

  /// Save customer only if at least one customer field has data.
  Future<void> _saveNewCustomerIfNeeded() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final gender = _genderController.text.trim();

    if (name.isEmpty && phone.isEmpty && email.isEmpty) return;

    bool customerExists = false;
    if (phone.isNotEmpty) {
      final existingByPhone = await _customerRepo.getCustomersByPhone(phone);
      customerExists = existingByPhone.isNotEmpty;
    }
    if (!customerExists && email.isNotEmpty) {
      final existingByEmail = await _customerRepo.getCustomersByEmail(email);
      customerExists = existingByEmail.isNotEmpty;
    }

    if (!customerExists) {
      final newCustomer = CustomerModel(
        name: name.isEmpty ? (phone.isNotEmpty ? phone : 'Customer') : name,
        phone: phone.isNotEmpty ? phone : null,
        email: email.isNotEmpty ? email : null,
        gender: gender.isNotEmpty ? gender : null,
        isSynced: false,
      );
      await _customerRepo.saveCustomer(newCustomer);
      await _loadCustomers();
    }
  }

  void _updateFinalAmount() {
    setState(() {
      if (_discountType == 'percentage') {
        final percent = double.tryParse(_discountPercentController.text) ?? 0;
        _discountValue = widget.totalAmount * (percent / 100);
      } else {
        _discountValue = double.tryParse(_discountAmountController.text) ?? 0;
      }
      _finalAmount = (widget.totalAmount - _discountValue).clamp(0, double.infinity);
    });
  }

  bool _validatePayments() {
    final cash = double.tryParse(_cashController.text) ?? 0;
    final credit = double.tryParse(_creditController.text) ?? 0;
    final card = double.tryParse(_cardController.text) ?? 0;
    return ((cash + credit + card) - _finalAmount).abs() < 0.01;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: width > 1000
              ? 720
              : width > 700
                  ? 620
                  : width * 0.96,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(blurRadius: 40, color: Colors.black26),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                const Divider(height: 1),
                Expanded(child: _content()),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ───────── HEADER (like image: dark blue bar, TOTAL, AED, amount) ───────── */

  static const String _currencyLabel = 'INR';

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TOTAL',
            style: AppStyles.getBoldTextStyle(fontSize: 14, color: Colors.white).copyWith(
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currencyLabel,
                style: AppStyles.getRegularTextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                widget.totalAmount.toStringAsFixed(2),
                style: AppStyles.getBoldTextStyle(fontSize: 32, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ───────── CONTENT (expandable cards) ───────── */

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MultipleExpansionCard(
            titles: [
              Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 10),
                  Text('Customer Details', style: AppStyles.getSemiBoldTextStyle(fontSize: 15)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.discount_outlined, size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 10),
                  Text('Discount', style: AppStyles.getSemiBoldTextStyle(fontSize: 15)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.payment, size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 10),
                  Text('Payment Methods', style: AppStyles.getSemiBoldTextStyle(fontSize: 15)),
                ],
              ),
            ],
            childrens: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _customerFields(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _discountFields(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paymentFields(),
                    if (!_validatePayments() && (_cashController.text.isNotEmpty || _creditController.text.isNotEmpty || _cardController.text.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Payment total must match payable amount',
                          style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            initialExpanded: const {0: true, 1: true, 2: true},
          ),
        ],
      ),
    );
  }

  Widget _customerFields() {
    if (_loadingCustomers) {
      return const Center(child: CircularProgressIndicator());
    }

    final phoneSuggestions = _allCustomers.where((c) => c.phone != null && c.phone!.isNotEmpty).map((c) => c.phone!).toSet().toList();
    final nameSuggestions = _allCustomers.map((c) => c.name).toSet().toList();
    final emailSuggestions = _allCustomers.where((c) => c.email != null && c.email!.isNotEmpty).map((c) => c.email!).toSet().toList();
    final genderOptions = ['Male', 'Female', 'Other'];
    final customersByName = _allCustomers.where((c) => c.name.toLowerCase().contains(_nameController.text.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row: Contact Number, Name, Email (like image)
        Row(
          children: [
            Expanded(
              child: AutoCompleteTextField<String>(
                items: phoneSuggestions,
                displayStringFunction: (item) => item,
                defaultText: '',
                labelText: 'Contact Number',
                controller: _phoneController,
                filterType: FilterType.contains,
                onSelected: (selectedPhone) {
                  final customer = _allCustomers.firstWhere(
                    (c) => c.phone == selectedPhone,
                    orElse: () => CustomerModel(name: '', phone: selectedPhone),
                  );
                  if (customer.id != null) _prefillCustomer(customer);
                },
              ),
            ),
            Expanded(
              child: AutoCompleteTextField<String>(
                items: nameSuggestions,
                displayStringFunction: (item) => item,
                defaultText: '',
                labelText: 'Name',
                controller: _nameController,
                filterType: FilterType.contains,
                onSelected: (selectedName) {
                  final customer = _allCustomers.firstWhere(
                    (c) => c.name == selectedName,
                    orElse: () => CustomerModel(name: selectedName),
                  );
                  if (customer.id != null) _prefillCustomer(customer);
                },
                onChanged: (value) {
                  final matching = customersByName.where((c) => c.name.toLowerCase() == value.toLowerCase()).toList();
                  if (matching.isNotEmpty) _prefillCustomer(matching.first);
                },
              ),
            ),
            Expanded(
              child: AutoCompleteTextField<String>(
                items: emailSuggestions,
                displayStringFunction: (item) => item,
                defaultText: '',
                labelText: 'Email',
                controller: _emailController,
                filterType: FilterType.contains,
                onSelected: (selectedEmail) {
                  final customer = _allCustomers.firstWhere(
                    (c) => c.email == selectedEmail,
                    orElse: () => CustomerModel(name: '', email: selectedEmail),
                  );
                  if (customer.id != null) _prefillCustomer(customer);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Choose Gender dropdown (like image)
        DropdownButtonFormField<String>(
          value: genderOptions.contains(_genderController.text) ? _genderController.text : null,
          decoration: InputDecoration(
            labelStyle: TextStyle(
              color: AppColors.hintFontColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: false,
            hintText: 'Choose Gender',
            fillColor: Colors.white,
            hintStyle: TextStyle(
              color: AppColors.hintFontColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            isDense: true,
            isCollapsed: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 13,
            ),
            errorStyle: const TextStyle(
              fontSize: 10,
              height: 1,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
          ),
          items: genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) {
            setState(() => _genderController.text = v ?? '');
          },
        ),
      ],
    );
  }

  Widget _discountFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discount by Amount',
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _discountAmountController,
                labelText: '',
                keyBoardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                onTap: () {
                  _discountType = 'amount';
                  _discountPercentController.clear();
                  _updateFinalAmount();
                },
                onChanged: (_) => _updateFinalAmount(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discount by %',
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _discountPercentController,
                labelText: '',
                keyBoardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                onTap: () {
                  _discountType = 'percentage';
                  _discountAmountController.clear();
                  _updateFinalAmount();
                },
                onChanged: (_) => _updateFinalAmount(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Amount Payable (right side, like image)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Amount Payable',
              style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
            ),
            const SizedBox(height: 6),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  '$_currencyLabel ${_finalAmount.toStringAsFixed(2)}',
                  style: AppStyles.getBoldTextStyle(fontSize: 18, color: AppColors.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _paymentFields() {
    return Row(
      children: [
        Expanded(child: _paymentField('CASH', _cashController, _cashFocusNode)),
        const SizedBox(width: 12),
        Expanded(child: _paymentField('CARD', _cardController, _cardFocusNode)),
        const SizedBox(width: 12),
        Expanded(child: _paymentField('CREDIT', _creditController, _creditFocusNode)),
        const SizedBox(width: 8),
        // // + button like image
        // Material(
        //   color: Colors.grey.shade200,
        //   borderRadius: BorderRadius.circular(8),
        //   child: InkWell(
        //     onTap: () {}, // Optional: add more credit row
        //     borderRadius: BorderRadius.circular(8),
        //     child: const SizedBox(
        //       width: 48,
        //       height: 48,
        //       child: Icon(Icons.add, color: AppColors.primaryColor, size: 28),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _paymentField(String label, TextEditingController controller, FocusNode focusNode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
        ),
        const SizedBox(height: 6),
        CustomTextField(
          controller: controller,
          focusNode: focusNode,
          labelText: '',
          keyBoardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  /* ───────── FOOTER (CLOSE + SUBMIT like image) ───────── */

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black12,
            offset: Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // CLOSE - light grey bg, dark blue border and text
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'CLOSE',
              style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: AppColors.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          // SUBMIT - only when amount payable is 0 (payments match). Show SnackBar on error.
          CustomButton(
            width: 120,
            text: 'SUBMIT',
            onPressed: () async {
              if (!_validatePayments()) {
                final cash = double.tryParse(_cashController.text) ?? 0;
                final card = double.tryParse(_cardController.text) ?? 0;
                final credit = double.tryParse(_creditController.text) ?? 0;
                final total = cash + card + credit;
                final remaining = _finalAmount - total;
                if (remaining > 0.01) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Amount payable must be 0. Add ${remaining.toStringAsFixed(2)} more.',
                        ),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                } else if (total > _finalAmount + 0.01) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Payment total (${total.toStringAsFixed(2)}) exceeds amount payable (${_finalAmount.toStringAsFixed(2)}).',
                        ),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment total must match amount payable.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                return;
              }
              await _saveNewCustomerIfNeeded();
              widget.onSave(
                {
                  'name': _nameController.text,
                  'phone': _phoneController.text,
                  'email': _emailController.text,
                  'gender': _genderController.text,
                },
                {
                  'type': _discountType,
                  'value': _discountValue,
                },
                {
                  'cash': double.tryParse(_cashController.text) ?? 0,
                  'credit': double.tryParse(_creditController.text) ?? 0,
                  'card': double.tryParse(_cardController.text) ?? 0,
                },
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cashFocusNode.removeListener(_onPaymentFocusCash);
    _cardFocusNode.removeListener(_onPaymentFocusCard);
    _creditFocusNode.removeListener(_onPaymentFocusCredit);
    _cashFocusNode.dispose();
    _cardFocusNode.dispose();
    _creditFocusNode.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _discountAmountController.dispose();
    _discountPercentController.dispose();
    _cashController.dispose();
    _creditController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}
