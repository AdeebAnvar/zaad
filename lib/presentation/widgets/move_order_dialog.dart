import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/order/move_order_logic.dart';
import 'package:pos/core/settings/app_settings_prefs.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/driver_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/presentation/widgets/app_snackbar.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/app_dropdown_field.dart';
import 'package:pos/presentation/widgets/custom_outlined_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

/// Same source as [PaymentDialog] / delivery sale: [CustomerRepository], [DeliveryPartnerRepository], [DriverRepository], and local [AppDatabase] dining tables.

/// Move an order to another service type (Take Away / Delivery / Dine In). [sourceOrderType] is where the user opened the dialog from.
Future<void> showMoveOrderDialog(
  BuildContext context, {
  required Order order,
  required String sourceOrderType,
  VoidCallback? onSuccess,
}) async {
  if (!orderCanMoveBetweenLogs(order)) {
    showAppSnackBar(context, 'This order cannot be moved.', isError: true);
    return;
  }

  await showAppAdaptiveSheetOrDialog<void>(
    context: context,
    // Always use dialog (same as desktop); bottom sheet was redundant on mobile.
    breakpoint: 0,
    sheetHeightFraction: 0.88,
    title: _moveOrderTitle(),
    dialogActions: (dCtx) => [
      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
    ],
    child: _MoveOrderBody(
      order: order,
      sourceOrderType: sourceOrderType,
      onSuccess: onSuccess,
    ),
  );
}

Widget _moveOrderTitle() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: const BoxDecoration(
      color: Color(0xFF1E2A4A),
      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
    ),
    child: Text(
      'MOVE ORDER',
      textAlign: TextAlign.center,
      style: AppStyles.getSemiBoldTextStyle(fontSize: 16, color: Colors.white),
    ),
  );
}

class _MoveOrderBody extends StatefulWidget {
  const _MoveOrderBody({
    required this.order,
    required this.sourceOrderType,
    this.onSuccess,
  });

  final Order order;
  final String sourceOrderType;
  final VoidCallback? onSuccess;

  @override
  State<_MoveOrderBody> createState() => _MoveOrderBodyState();
}

class _MoveOrderBodyState extends State<_MoveOrderBody> {
  final _db = locator<AppDatabase>();
  final _orderRepo = locator<OrderRepository>();
  final _cartRepo = locator<CartRepository>();
  final _driverRepo = locator<DriverRepository>();
  final _customerRepo = locator<CustomerRepository>();
  final _deliveryPartnerRepo = locator<DeliveryPartnerRepository>();

  String? _target;
  bool _loading = true;
  String? _loadError;

  List<DiningFloor> _floors = [];
  List<Driver> _drivers = [];
  List<CustomerModel> _allCustomers = [];
  List<String> _deliveryPartnerNames = [];
  bool _loadingCustomers = true;

  final _refTakeAway = TextEditingController();
  final _phone = TextEditingController();
  final _custName = TextEditingController();
  final _email = TextEditingController();
  final _onlineOrderRef = TextEditingController();
  final _pax = TextEditingController(text: '1');

  String? _gender;
  String? _deliveryPartner;
  int? _driverId;
  int? _floorId;
  int? _tableId;

  List<DiningTable> _tables = [];

  bool _submitting = false;
  bool _seatHandlingEnabled = true;

  static const _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _prefill();
    _load();
  }

  void _prefill() {
    final o = widget.order;
    _refTakeAway.text = o.referenceNumber ?? '';
    _phone.text = o.customerPhone ?? '';
    _custName.text = o.customerName ?? '';
    _email.text = o.customerEmail ?? '';
    final g = o.customerGender?.trim();
    _gender = (g != null && g.isNotEmpty && _genderOptions.contains(g)) ? g : null;
    if (o.orderType == 'delivery') {
      _onlineOrderRef.text = o.referenceNumber ?? '';
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final seatHandling = await AppSettingsPrefs.getDineInSeatHandlingEnabled();
      final floors = await _db.diningTablesDao.getFloors();
      final drivers = await _driverRepo.getAll();
      final customers = await _customerRepo.getAllLocalCustomers();
      final partnerRows = await _deliveryPartnerRepo.getAll();
      final names = partnerRows.map((e) => e.name).toList();
      if (!names.any((n) => n.trim().toUpperCase() == 'NORMAL')) {
        names.add('NORMAL');
      }
      names.sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

      if (!mounted) return;
      setState(() {
        _seatHandlingEnabled = seatHandling;
        _floors = floors;
        _drivers = drivers;
        _allCustomers = customers;
        _deliveryPartnerNames = names;
        _loadingCustomers = false;
        _loading = false;
        if (_floors.isNotEmpty) {
          _floorId = _floors.first.id;
        }
      });
      await _loadTablesForFloor();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingCustomers = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _loadTablesForFloor() async {
    final fid = _floorId;
    if (fid == null) {
      setState(() {
        _tables = [];
        _tableId = null;
      });
      return;
    }
    final tables = await _db.diningTablesDao.getTablesByFloor(fid);
    if (!mounted) return;
    setState(() {
      _tables = tables;
      _tableId = tables.isNotEmpty ? tables.first.id : null;
    });
  }

  void _prefillCustomer(CustomerModel customer) {
    setState(() {
      _custName.text = customer.name;
      _phone.text = customer.phone ?? '';
      _email.text = customer.email ?? '';
      final g = customer.gender?.trim();
      _gender = (g != null && g.isNotEmpty && _genderOptions.contains(g)) ? g : null;
    });
  }

  @override
  void dispose() {
    _refTakeAway.dispose();
    _phone.dispose();
    _custName.dispose();
    _email.dispose();
    _onlineOrderRef.dispose();
    _pax.dispose();
    super.dispose();
  }

  List<String> get _destKeys {
    switch (widget.sourceOrderType) {
      case 'take_away':
        return ['delivery', 'dine_in'];
      case 'delivery':
        return ['take_away', 'dine_in'];
      case 'dine_in':
        return ['take_away', 'delivery'];
      default:
        return ['take_away', 'delivery', 'dine_in'];
    }
  }

  String _labelFor(String key) {
    switch (key) {
      case 'take_away':
        return 'TAKE AWAY';
      case 'delivery':
        return 'DELIVERY';
      case 'dine_in':
        return 'DINE IN';
      default:
        return key;
    }
  }

  Future<void> _submit() async {
    if (_target == null || _submitting) return;
    setState(() => _submitting = true);
    String? err;
    try {
      switch (_target!) {
        case 'take_away':
          err = await moveOrderToTakeAway(
            orderRepo: _orderRepo,
            cartRepo: _cartRepo,
            order: widget.order,
            referenceNumber: _refTakeAway.text,
          );
          break;
        case 'delivery':
          final partner = _deliveryPartner ?? '';
          if (partner.isEmpty) {
            err = 'Select delivery type';
            break;
          }
          final drv = _drivers.where((d) => d.id == _driverId).firstOrNull;
          final gender = _gender?.trim();
          err = await moveOrderToDelivery(
            orderRepo: _orderRepo,
            cartRepo: _cartRepo,
            order: widget.order,
            deliveryPartner: partner,
            contactNumber: _phone.text,
            customerName: _custName.text,
            email: _email.text.isEmpty ? null : _email.text,
            gender: (gender == null || gender.isEmpty) ? null : gender,
            driverId: partner.toUpperCase() == 'NORMAL' ? _driverId : null,
            driverName: partner.toUpperCase() == 'NORMAL' ? drv?.name : null,
            onlineOrderNumber: _onlineOrderRef.text.trim().isEmpty ? null : _onlineOrderRef.text.trim(),
          );
          break;
        case 'dine_in':
          final tid = _tableId;
          final fid = _floorId;
          if (fid == null || tid == null) {
            err = 'Select floor and table';
            break;
          }
          final table = _tables.where((t) => t.id == tid).firstOrNull;
          if (table == null) {
            err = 'Invalid table';
            break;
          }
          final pax = int.tryParse(_pax.text.trim()) ?? 0;
          err = await moveOrderToDineIn(
            orderRepo: _orderRepo,
            cartRepo: _cartRepo,
            order: widget.order,
            floorId: fid,
            table: table,
            pax: pax,
          );
          break;
      }
    } catch (e) {
      err = e.toString();
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (err != null) {
      showAppSnackBar(context, err, isError: true);
      return;
    }
    if (_target == 'take_away') {
      showAppSnackBar(context, 'Order moved to Take Away');
    } else if (_target == 'delivery') {
      showAppSnackBar(context, 'Order moved to Delivery');
    } else {
      showAppSnackBar(context, 'Order moved to Dine In');
    }
    widget.onSuccess?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_loadError!, style: const TextStyle(color: Colors.red)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MOVE TO',
            style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: _destKeys
                .map(
                  (k) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _destPill(
                        label: _labelFor(k),
                        selected: _target == k,
                        onTap: () => setState(() => _target = k),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (_target != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (_target == 'take_away') _takeAwayForm(),
            if (_target == 'delivery') _deliveryForm(context),
            if (_target == 'dine_in') _dineInForm(),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomOutlinedButton(
                width: 100,
                text: 'CANCEL',
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              CustomButton(
                width: 120,
                text: _submitting ? '…' : 'SUBMIT',
                onPressed: (_submitting || _target == null) ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _destPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFF1E2A4A) : const Color(0xFF1E2A4A).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _takeAwayForm() {
    return CustomTextField(
      controller: _refTakeAway,
      labelText: 'Reference No#:',
    );
  }

  /// Customer fields aligned with [PaymentDialog] / `desktop_cart_panel.dart` (local customers + autocomplete).
  Widget _paymentStyleCustomerSection(BuildContext context) {
    if (_loadingCustomers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final phoneSuggestions =
        _allCustomers.where((c) => c.phone != null && c.phone!.isNotEmpty).map((c) => c.phone!).toSet().toList();
    final nameSuggestions = _allCustomers.map((c) => c.name).toSet().toList();
    final emailSuggestions =
        _allCustomers.where((c) => c.email != null && c.email!.isNotEmpty).map((c) => c.email!).toSet().toList();
    final narrow = MediaQuery.sizeOf(context).width < 560;

    Widget row3() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AutoCompleteTextField<String>(
              items: phoneSuggestions,
              displayStringFunction: (item) => item,
              defaultText: '',
              labelText: 'Contact Number',
              controller: _phone,
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
          const SizedBox(width: 8),
          Expanded(
            child: AutoCompleteTextField<String>(
              items: nameSuggestions,
              displayStringFunction: (item) => item,
              defaultText: '',
              labelText: 'Name',
              controller: _custName,
              filterType: FilterType.contains,
              onSelected: (selectedName) {
                final customer = _allCustomers.firstWhere(
                  (c) => c.name == selectedName,
                  orElse: () => CustomerModel(name: selectedName),
                );
                if (customer.id != null) _prefillCustomer(customer);
              },
              onChanged: (value) {
                setState(() {});
                final matching =
                    _allCustomers.where((c) => c.name.toLowerCase() == value.toLowerCase()).toList();
                if (matching.isNotEmpty) _prefillCustomer(matching.first);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AutoCompleteTextField<String>(
              items: emailSuggestions,
              displayStringFunction: (item) => item,
              defaultText: '',
              labelText: 'Email',
              controller: _email,
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
      );
    }

    Widget col3() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutoCompleteTextField<String>(
            items: phoneSuggestions,
            displayStringFunction: (item) => item,
            defaultText: '',
            labelText: 'Contact Number',
            controller: _phone,
            filterType: FilterType.contains,
            onSelected: (selectedPhone) {
              final customer = _allCustomers.firstWhere(
                (c) => c.phone == selectedPhone,
                orElse: () => CustomerModel(name: '', phone: selectedPhone),
              );
              if (customer.id != null) _prefillCustomer(customer);
            },
          ),
          const SizedBox(height: 10),
          AutoCompleteTextField<String>(
            items: nameSuggestions,
            displayStringFunction: (item) => item,
            defaultText: '',
            labelText: 'Name',
            controller: _custName,
            filterType: FilterType.contains,
            onSelected: (selectedName) {
              final customer = _allCustomers.firstWhere(
                (c) => c.name == selectedName,
                orElse: () => CustomerModel(name: selectedName),
              );
              if (customer.id != null) _prefillCustomer(customer);
            },
            onChanged: (value) {
              setState(() {});
              final matching =
                  _allCustomers.where((c) => c.name.toLowerCase() == value.toLowerCase()).toList();
              if (matching.isNotEmpty) _prefillCustomer(matching.first);
            },
          ),
          const SizedBox(height: 10),
          AutoCompleteTextField<String>(
            items: emailSuggestions,
            displayStringFunction: (item) => item,
            defaultText: '',
            labelText: 'Email',
            controller: _email,
            filterType: FilterType.contains,
            onSelected: (selectedEmail) {
              final customer = _allCustomers.firstWhere(
                (c) => c.email == selectedEmail,
                orElse: () => CustomerModel(name: '', email: selectedEmail),
              );
              if (customer.id != null) _prefillCustomer(customer);
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        narrow ? col3() : row3(),
        const SizedBox(height: 12),
        AppDropdownField<String>(
          labelText: 'Gender',
          value: _genderOptions.contains(_gender) ? _gender : null,
          items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
      ],
    );
  }

  Widget _deliveryForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DELIVERY TYPE',
          textAlign: TextAlign.center,
          style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.hintFontColor),
        ),
        const SizedBox(height: 8),
        if (_deliveryPartnerNames.isEmpty)
          Text(
            'No delivery types configured.',
            style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.orange),
          )
        else
          AppDropdownField<String>(
            labelText: 'Delivery type',
            value: _deliveryPartnerNames.any((p) => p.toUpperCase() == (_deliveryPartner ?? '').toUpperCase())
                ? _deliveryPartnerNames.firstWhere(
                    (p) => p.toUpperCase() == (_deliveryPartner ?? '').toUpperCase(),
                  )
                : null,
            items: _deliveryPartnerNames
                .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() {
              _deliveryPartner = v;
              if ((v ?? '').toUpperCase() != 'NORMAL') _driverId = null;
            }),
          ),
        const SizedBox(height: 16),
        Text(
          'CUSTOMER DETAILS',
          textAlign: TextAlign.center,
          style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.hintFontColor),
        ),
        const SizedBox(height: 8),
        _paymentStyleCustomerSection(context),
        if ((_deliveryPartner ?? '').isNotEmpty && (_deliveryPartner ?? '').toUpperCase() != 'NORMAL') ...[
          const SizedBox(height: 12),
          CustomTextField(
            controller: _onlineOrderRef,
            labelText: 'Online order number (optional)',
          ),
        ],
        if ((_deliveryPartner ?? '').toUpperCase() == 'NORMAL') ...[
          const SizedBox(height: 16),
          Text(
            'SELECT DRIVER',
            textAlign: TextAlign.center,
            style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 8),
          if (_drivers.isEmpty)
            Text(
              'No drivers available.',
              style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.orange),
            )
          else
            AppDropdownField<int>(
              labelText: 'Driver',
              value: _drivers.any((d) => d.id == _driverId) ? _driverId : null,
              items: _drivers
                  .map((d) => DropdownMenuItem<int>(value: d.id, child: Text('${d.name} (${d.id})')))
                  .toList(),
              onChanged: (v) => setState(() => _driverId = v),
            ),
        ],
      ],
    );
  }

  Widget _dineInForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_floors.isEmpty)
          Text(
            'No floors configured.',
            style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.orange),
          )
        else
          AppDropdownField<int>(
            labelText: 'Floor',
            value: _floors.any((f) => f.id == _floorId) ? _floorId : null,
            items: _floors
                .map((f) => DropdownMenuItem<int>(value: f.id, child: Text(f.name)))
                .toList(),
            onChanged: (v) async {
              if (v == null) return;
              setState(() {
                _floorId = v;
                _tableId = null;
              });
              await _loadTablesForFloor();
            },
          ),
        const SizedBox(height: 12),
        if (_tables.isEmpty)
          Text(
            _floorId == null ? 'Select a floor.' : 'No tables on this floor.',
            style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.orange),
          )
        else
          AppDropdownField<int>(
            labelText: 'Table',
            value: _tables.any((t) => t.id == _tableId) ? _tableId : null,
            items: _tables
                .map(
                  (t) => DropdownMenuItem<int>(
                    value: t.id,
                    child: Text('${t.code} (${t.chairs} seats)'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _tableId = v),
          ),
        if (_seatHandlingEnabled) ...[
          const SizedBox(height: 12),
          CustomTextField(
            controller: _pax,
            labelText: 'Pax',
            keyBoardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final i = iterator;
    if (!i.moveNext()) return null;
    return i.current;
  }
}
