import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';

/// [cartLineEdit] = compact table layout (navy header, CLOSE/SAVE) — use only from cart line.
enum ToppingsDialogStyle { standard, cartLineEdit }

class ToppingsDialog extends StatefulWidget {
  final Item item;
  final ItemVariant? variant;
  final int qty;
  final List<ItemTopping> toppings;
  final List<ToppingGroup> toppingGroups;
  final CartCubit? cartCubit; // Optional - can be passed or accessed via context
  final Map<ItemTopping, int>? initialSelectedToppings; // Pre-fill existing selections
  final int? cartItemId; // If updating existing cart item
  final ToppingsDialogStyle style;

  const ToppingsDialog({
    super.key,
    required this.item,
    required this.variant,
    required this.qty,
    required this.toppings,
    this.toppingGroups = const [],
    this.cartCubit,
    this.initialSelectedToppings,
    this.cartItemId,
    this.style = ToppingsDialogStyle.standard,
  });

  @override
  State<ToppingsDialog> createState() => _ToppingsDialogState();
}

class _ToppingsDialogState extends State<ToppingsDialog> {
  late Map<ItemTopping, int> selected;
  ItemTopping? hoveredTopping;
  String? _inlineNotice;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    selected = widget.initialSelectedToppings?.map((k, v) => MapEntry(k, v)) ?? {};
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  void _showTopRightNotice(String message) {
    if (!mounted) return;
    _noticeTimer?.cancel();
    setState(() => _inlineNotice = message);
    _noticeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _inlineNotice = null);
      }
    });
  }

  double get _noticeTopOffset {
    if (widget.style == ToppingsDialogStyle.cartLineEdit) {
      return 50;
    }
    // Standard dialog: clear the title row + divider so the pill sits top-right of the list area.
    return 72;
  }

  /// SnackBar-style message anchored to the top-right of the dialog card (not the screen).
  Widget _topRightNoticePill() {
    final m = _inlineNotice;
    if (m == null) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final capW = math.min(300.0, (mq.size.width * 0.5).clamp(200.0, 320.0));
    return Positioned(
      top: _noticeTopOffset,
      right: 8,
      child: Material(
        color: const Color(0xFF2D2D2D).withValues(alpha: 0.95),
        elevation: 8,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: capW),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              m,
              style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.white).copyWith(height: 1.35),
            ),
          ),
        ),
      ),
    );
  }

  Map<int, ToppingGroup> get _groupById {
    final out = <int, ToppingGroup>{};
    for (final g in widget.toppingGroups) {
      out[g.id] = g;
    }
    return out;
  }

  /// Same key as [ToppingGroup.id] for this item: [itemId]*100000 + [toppingsCategoryId].
  int _groupKey(ItemTopping t) {
    if (t.maximum != null) return t.maximum!;
    final cid = t.toppingsCategoryId;
    if (cid != null) {
      return widget.item.id * 100000 + cid;
    }
    return -t.id;
  }

  /// True when local rows never stored category or group id (one UI block, still one [ToppingGroup]).
  bool get _isLegacyUngroupedToppings =>
      widget.toppingGroups.length == 1 && widget.toppings.isNotEmpty && widget.toppings.every((t) => t.maximum == null && t.toppingsCategoryId == null);

  List<({int key, String name, List<ItemTopping> toppings})> get _groupedToppings {
    final byId = _groupById;

    // Legacy rows: no [maximum] and no [toppingsCategoryId] → every topping became its own group.
    // If the item only has one server category, fold into that group.
    if (widget.toppingGroups.length == 1 && widget.toppings.isNotEmpty) {
      final g = widget.toppingGroups.first;
      final noCategoryLink = widget.toppings.every(
        (t) => t.maximum == null && t.toppingsCategoryId == null,
      );
      if (noCategoryLink) {
        return [(key: g.id, name: g.name, toppings: List<ItemTopping>.from(widget.toppings))];
      }
    }

    final buckets = <int, List<ItemTopping>>{};
    for (final t in widget.toppings) {
      final key = _groupKey(t);
      buckets.putIfAbsent(key, () => <ItemTopping>[]).add(t);
    }
    final out = <({int key, String name, List<ItemTopping> toppings})>[];
    for (final entry in buckets.entries) {
      final group = byId[entry.key];
      final name = group?.name ?? 'Toppings';
      out.add((key: entry.key, name: name, toppings: entry.value));
    }
    return out;
  }

  int _groupSelectedQty(int groupKey) {
    if (_isLegacyUngroupedToppings && widget.toppingGroups.isNotEmpty && groupKey == widget.toppingGroups.first.id) {
      var sum = 0;
      for (final t in widget.toppings) {
        if ((selected[t] ?? 0) > 0) sum += 1;
      }
      return sum;
    }
    var sum = 0;
    for (final t in widget.toppings) {
      final key = _groupKey(t);
      if (key != groupKey) continue;
      if ((selected[t] ?? 0) > 0) sum += 1;
    }
    return sum;
  }

  int _groupMax(int groupKey) {
    final g = _groupById[groupKey];
    return g?.max ?? 0;
  }

  int _groupMin(int groupKey) {
    final g = _groupById[groupKey];
    return g?.min ?? 0;
  }

  String _groupDisplayName(int groupKey) {
    final n = _groupById[groupKey]?.name;
    if (n == null || n.trim().isEmpty) return 'Toppings';
    return n.trim();
  }

  bool _canIncrementTopping(int sectionGroupKey) {
    final gMax = _groupMax(sectionGroupKey);
    final currentG = _groupSelectedQty(sectionGroupKey);
    return gMax <= 0 || currentG < gMax;
  }

  void _warnCannotIncrementTopping(int sectionGroupKey) {
    final gMax = _groupMax(sectionGroupKey);
    final currentG = _groupSelectedQty(sectionGroupKey);
    if (gMax > 0 && currentG >= gMax) {
      if (!context.mounted) return;
      _showTopRightNotice('Maximum $gMax topping(s) for "${_groupDisplayName(sectionGroupKey)}".');
    }
  }

  /// From synced [ToppingGroup] (API `min_select` / `max_select`); [max] 0 = no cap in API.
  String? _minMaxTextForGroupKey(int groupKey) {
    final g = _groupById[groupKey];
    if (g == null) return null;
    final maxStr = g.max > 0 ? '${g.max}' : '—';
    return 'Min ${g.min} · Max $maxStr';
  }

  double get unitBasePrice => widget.variant?.price ?? widget.item.price;

  double get total {
    double sum = unitBasePrice;
    selected.forEach((t, q) => sum += t.price * q);
    return sum * widget.qty;
  }

  /* ───────────────── DIALOG ───────────────── */

  @override
  Widget build(BuildContext context) {
    if (widget.style == ToppingsDialogStyle.cartLineEdit) {
      return _buildCartLineDialog();
    }
    return _buildStandardDialog();
  }

  Widget _buildStandardDialog() {
    final m = MediaQuery.of(context);
    final safeW = m.size.width - m.padding.left - m.padding.right;
    final availableH = m.size.height - m.padding.top - m.padding.bottom - m.viewInsets.bottom;
    final maxW = math.min(600.0, math.max(280.0, safeW * 0.96));
    final maxH = math.min(720.0, math.max(300.0, availableH * 0.9));
    final theme = Theme.of(context);
    final isNarrow = maxW < 420;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: math.max(8.0, safeW * 0.02).clamp(8.0, 24.0),
        vertical: 12,
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: maxW,
          height: maxH,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isNarrow ? 18 : 26),
            boxShadow: const [
              BoxShadow(
                blurRadius: 35,
                color: Colors.black26,
              )
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  _header(theme, isNarrow: isNarrow),
                  const Divider(height: 1),
                  Expanded(child: _content()),
                  _footer(theme, isNarrow: isNarrow),
                ],
              ),
              _topRightNoticePill(),
            ],
          ),
        ),
      ),
    );
  }

  static const Color _cartHeaderNavy = Color(0xFF1C273C);

  Widget _buildCartLineDialog() {
    final m = MediaQuery.of(context);
    final safeW = m.size.width - m.padding.left - m.padding.right;
    final availableH = m.size.height - m.padding.top - m.padding.bottom - m.viewInsets.bottom;
    final maxW = math.min(720.0, math.max(300.0, safeW * 0.96));
    final maxH = math.min(680.0, math.max(280.0, availableH * 0.9));
    final isNarrow = maxW < 400;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: math.max(8.0, safeW * 0.02).clamp(8.0, 24.0),
        vertical: math.max(8.0, 20.0),
      ),
      child: Center(
        child: Container(
          width: maxW,
          height: maxH,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isNarrow ? 6 : 8),
            boxShadow: const [BoxShadow(blurRadius: 24, color: Colors.black26)],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  _headerCartLine(isCompact: isNarrow),
                  Expanded(child: _contentCartLine()),
                  _footerCartLine(isNarrow: isNarrow),
                ],
              ),
              _topRightNoticePill(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCartLine({bool isCompact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14, horizontal: 12),
      color: _cartHeaderNavy,
      child: Text(
        'TOPPINGS',
        textAlign: TextAlign.center,
        style: AppStyles.getBoldTextStyle(fontSize: isCompact ? 14 : 16, color: Colors.white).copyWith(
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _categoryHeaderCartLine(String name) {
    final n = name.trim().isEmpty ? 'Toppings' : name;
    return n.toUpperCase();
  }

  Widget _contentCartLine() {
    if (widget.toppings.isEmpty) {
      return Center(
        child: Text(
          'No toppings available',
          style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor),
        ),
      );
    }
    final narrow = MediaQuery.sizeOf(context).width < 400;
    final groups = _groupedToppings;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(narrow ? 10 : 16, 16, narrow ? 10 : 16, 8),
      itemCount: groups.length,
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      itemBuilder: (context, index) {
        final group = groups[index];
        final minMaxLine = _minMaxTextForGroupKey(group.key);
        final gMax = _groupMax(group.key);
        final selectedInGroup = _groupSelectedQty(group.key);
        final titleLine = gMax > 0 ? '${_categoryHeaderCartLine(group.name)} ($selectedInGroup/$gMax)' : _categoryHeaderCartLine(group.name);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titleLine,
              style: AppStyles.getBoldTextStyle(fontSize: 12, color: AppColors.textColor).copyWith(letterSpacing: 0.4),
            ),
            if (minMaxLine != null) ...[
              const SizedBox(height: 2),
              Text(
                minMaxLine,
                style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
              ),
            ],
            if (_groupMin(group.key) > 0 && selectedInGroup > 0 && selectedInGroup < _groupMin(group.key)) ...[
              const SizedBox(height: 4),
              Text(
                'Select at least ${_groupMin(group.key)} in this category.',
                style: AppStyles.getRegularTextStyle(fontSize: 10, color: Colors.orange.shade800),
              ),
            ],
            const SizedBox(height: 8),
            ...group.toppings.map((topping) {
              final qty = selected[topping] ?? 0;
              return _cartToppingRow(topping, qty, group.key);
            }),
          ],
        );
      },
    );
  }

  Widget _cartToppingRow(ItemTopping topping, int qty, int sectionGroupKey) {
    Widget rowMain(bool stacked) {
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Checkbox(
                    value: qty > 0,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    activeColor: AppColors.primaryColor,
                    onChanged: (v) {
                      if (v == true) {
                        if (!_canIncrementTopping(sectionGroupKey)) {
                          _warnCannotIncrementTopping(sectionGroupKey);
                          return;
                        }
                        setState(() => selected[topping] = 1);
                      } else {
                        setState(() => selected.remove(topping));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    topping.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.textColor),
                  ),
                ),
                Text(
                  topping.price.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: _stepper(topping, qty, sectionGroupKey, compact: true),
            ),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: qty > 0,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  activeColor: AppColors.primaryColor,
                  onChanged: (v) {
                    if (v == true) {
                      if (!_canIncrementTopping(sectionGroupKey)) {
                        _warnCannotIncrementTopping(sectionGroupKey);
                        return;
                      }
                      setState(() => selected[topping] = 1);
                    } else {
                      setState(() => selected.remove(topping));
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              topping.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.textColor),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              topping.price.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.textColor),
            ),
          ),
          const SizedBox(width: 6),
          _stepper(topping, qty, sectionGroupKey, compact: true),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 340;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: rowMain(stacked),
        );
      },
    );
  }

  Widget _footerCartLine({bool isNarrow = false}) {
    final pad = isNarrow ? const EdgeInsets.fromLTRB(12, 10, 12, 12) : const EdgeInsets.fromLTRB(20, 14, 20, 16);
    final body = isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TOTAL: ${RuntimeAppSettings.money(total)}',
                textAlign: TextAlign.center,
                style: AppStyles.getBoldTextStyle(fontSize: 15, color: AppColors.textColor),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('CLOSE', style: AppStyles.getBoldTextStyle(fontSize: 12, color: AppColors.primaryColor)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('SAVE', style: AppStyles.getBoldTextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'TOTAL: ${RuntimeAppSettings.money(total)}',
                style: AppStyles.getBoldTextStyle(fontSize: 15, color: AppColors.textColor),
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('CLOSE', style: AppStyles.getBoldTextStyle(fontSize: 12, color: AppColors.primaryColor)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('SAVE', style: AppStyles.getBoldTextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          );

    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: pad,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: body,
      ),
    );
  }

  /* ───────────────── HEADER ───────────────── */

  Widget _header(ThemeData theme, {bool isNarrow = false}) {
    final titleSize = isNarrow ? 18.0 : 22.0;
    final subSize = isNarrow ? 12.0 : 14.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(isNarrow ? 14 : 24, isNarrow ? 12 : 22, 8, isNarrow ? 10 : 16),
      child: Row(
        children: [
          Icon(Icons.tapas, size: isNarrow ? 22 : 26),
          SizedBox(width: isNarrow ? 6 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Customize Toppings",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.getBoldTextStyle(fontSize: titleSize),
                ),
                Text(
                  widget.item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.getRegularTextStyle(fontSize: subSize, color: Colors.grey.shade600),
                )
              ],
            ),
          ),
          IconButton(
            padding: isNarrow ? const EdgeInsets.all(4) : null,
            constraints: isNarrow ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  /* ───────────────── CONTENT ───────────────── */

  Widget _content() {
    if (widget.toppings.isEmpty) {
      return Center(child: Text("No toppings available", style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey)));
    }

    final narrow = MediaQuery.sizeOf(context).width < 420;
    final pad = narrow ? 12.0 : 20.0;
    final groups = _groupedToppings;
    return ListView.builder(
      padding: EdgeInsets.all(pad),
      itemCount: groups.length,
      itemBuilder: (_, index) {
        final group = groups[index];
        final minMaxLine = _minMaxTextForGroupKey(group.key);
        return Container(
          margin: EdgeInsets.only(bottom: index == groups.length - 1 ? 0 : 14),
          padding: EdgeInsets.fromLTRB(narrow ? 8 : 12, 12, narrow ? 8 : 12, 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          group.name,
                          style: AppStyles.getSemiBoldTextStyle(fontSize: 15),
                        ),
                        if (_groupMin(group.key) > 0 && _groupSelectedQty(group.key) > 0 && _groupSelectedQty(group.key) < _groupMin(group.key))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Required',
                              style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: Colors.orange.shade900),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_groupMax(group.key) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_groupSelectedQty(group.key)} / ${_groupMax(group.key)}',
                        style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.primaryColor),
                      ),
                    ),
                ],
              ),
              if (minMaxLine != null) ...[
                const SizedBox(height: 4),
                Text(
                  minMaxLine,
                  style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 8),
              ...group.toppings.map((topping) {
                final qty = selected[topping] ?? 0;
                return MouseRegion(
                  onEnter: (_) => setState(() => hoveredTopping = topping),
                  onExit: (_) => setState(() => hoveredTopping = null),
                  child: _toppingCard(topping, qty, group.key),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /* ───────────────── TOPPING CARD ───────────────── */

  Widget _toppingCard(ItemTopping topping, int qty, int sectionGroupKey) {
    final bool isSelected = qty > 0;
    final bool isHovered = hoveredTopping == topping;

    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 340;
        final pad = stacked ? 12.0 : 18.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 14),
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.85)
                : isHovered
                    ? Colors.grey.shade100
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(stacked ? 14 : 18),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            ),
            boxShadow: isHovered
                ? const [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black12,
                    )
                  ]
                : [],
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      topping.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.getSemiBoldTextStyle(
                        fontSize: 15,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      RuntimeAppSettings.money(topping.price),
                      style: AppStyles.getRegularTextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _stepper(topping, qty, sectionGroupKey, compact: true),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topping.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.getSemiBoldTextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            RuntimeAppSettings.money(topping.price),
                            style: AppStyles.getRegularTextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.white70 : Colors.grey.shade700,
                            ),
                          )
                        ],
                      ),
                    ),
                    _stepper(topping, qty, sectionGroupKey),
                  ],
                ),
        );
      },
    );
  }

  /* ───────────────── STEPPER ───────────────── */

  Widget _stepper(ItemTopping topping, int qty, int sectionGroupKey, {bool compact = false}) {
    final btn = compact ? 30.0 : 42.0;
    final padH = compact ? 8.0 : 16.0;
    final iconSz = compact ? 16.0 : 20.0;
    final fontQty = compact ? 14.0 : 17.0;
    final radius = compact ? 6.0 : 16.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            icon: Icons.remove,
            enabled: qty > 0,
            onTap: () {
              setState(() {
                if (qty <= 1) {
                  selected.remove(topping);
                } else {
                  selected[topping] = qty - 1;
                }
              });
            },
            size: btn,
            iconSize: iconSz,
            borderRadius: radius,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH),
            child: Text(
              "$qty",
              style: AppStyles.getBoldTextStyle(fontSize: fontQty),
            ),
          ),
          _stepperButton(
            icon: Icons.add,
            enabled: true,
            onTap: () {
              // if (!canAdd) {
              //   _warnCannotIncrementTopping(sectionGroupKey);
              //   return;
              // }
              setState(() {
                selected[topping] = qty + 1;
              });
            },
            iconColor: Colors.black,
            size: btn,
            iconSize: iconSz,
            borderRadius: radius,
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    Color? iconColor,
    double size = 42,
    double iconSize = 20,
    double borderRadius = 14,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? (enabled ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  /* ───────────────── FOOTER ───────────────── */

  Widget _footer(ThemeData theme, {bool isNarrow = false}) {
    final br = isNarrow ? 18.0 : 26.0;
    final totalFs = isNarrow ? 18.0 : 22.0;
    final padding = isNarrow ? const EdgeInsets.fromLTRB(14, 12, 14, 14) : const EdgeInsets.fromLTRB(20, 18, 20, 20);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(br)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black12,
            offset: Offset(0, -4),
          )
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total",
                          style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          RuntimeAppSettings.money(total),
                          style: AppStyles.getBoldTextStyle(fontSize: totalFs),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: AppStyles.getMediumTextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          widget.cartItemId != null ? "Update" : "Add to cart",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.getMediumTextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total",
                      style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      RuntimeAppSettings.money(total),
                      style: AppStyles.getBoldTextStyle(fontSize: totalFs),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: AppStyles.getMediumTextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.cartItemId != null ? "Update Item" : "Add To Cart",
                    style: AppStyles.getMediumTextStyle(fontSize: 13, color: Colors.white),
                  ),
                )
              ],
            ),
    );
  }

  void _onSave() {
    // Try to get CartCubit from passed parameter or context
    CartCubit? cubit = widget.cartCubit;
    if (cubit == null) {
      try {
        cubit = context.read<CartCubit>();
      } catch (e) {
        // If not available in context, try to get from navigator context
        final navigatorContext = Navigator.of(context, rootNavigator: true).context;
        if (navigatorContext.mounted) {
          try {
            cubit = navigatorContext.read<CartCubit>();
          } catch (_) {
            // If still not found, return without saving
            Navigator.pop(context);
            return;
          }
        } else {
          Navigator.pop(context);
          return;
        }
      }
    }

    for (final group in _groupedToppings) {
      final selectedQty = _groupSelectedQty(group.key);
      final min = _groupMin(group.key);
      final max = _groupMax(group.key);
      if (min > 0 && selectedQty > 0 && selectedQty < min) {
        if (!context.mounted) return;
        _showTopRightNotice(
          '"${group.name}": select at least $min topping(s) (you selected $selectedQty).',
        );
        return;
      }
      if (max > 0 && selectedQty > max) {
        if (!context.mounted) return;
        _showTopRightNotice(
          '"${group.name}": at most $max topping(s) allowed (you selected $selectedQty).',
        );
        return;
      }
    }

    // If updating existing cart item, use updateCartItemToppings
    if (widget.cartItemId != null) {
      cubit.updateCartItemToppings(widget.cartItemId!, selected);
    } else {
      // Adding new item with toppings
      cubit.addItemWithVariantAndToppings(
        widget.item,
        widget.variant,
        widget.qty,
        selected,
      );
    }
    Navigator.pop(context);
  }
}
