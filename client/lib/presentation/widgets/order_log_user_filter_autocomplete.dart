import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';

/// Dropdown-style filter listing synced staff from the local DB (not placeholders).
/// [onSelectedUserId] is `null` when "All users" is chosen.
class OrderLogUserFilterAutocomplete extends StatefulWidget {
  const OrderLogUserFilterAutocomplete({
    super.key,
    required this.controller,
    required this.onSelectedUserId,
    this.labelText = 'User',
    this.allUsersLabel = 'All users',
  });

  final TextEditingController controller;
  final void Function(int? userId) onSelectedUserId;
  final String labelText;
  final String allUsersLabel;

  @override
  State<OrderLogUserFilterAutocomplete> createState() =>
      _OrderLogUserFilterAutocompleteState();
}

class _OrderPick {
  const _OrderPick({required this.id, required this.label});
  final int? id;
  final String label;
}

class _OrderLogUserFilterAutocompleteState
    extends State<OrderLogUserFilterAutocomplete> {
  List<_OrderPick> _picks = [
    _OrderPick(id: null, label: ''), // replaced after load
  ];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _picks = [_OrderPick(id: null, label: widget.allUsersLabel)];
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final db = locator<AppDatabase>();
      final session = await db.sessionDao.getActiveSession();
      final branchId = session?.branchId ?? 1;
      var users = await db.usersDao.getUsersForBranch(branchId);
      if (users.isEmpty) {
        final ids = await db.ordersDao.getDistinctCashierUserIdsForBranch(branchId);
        for (final id in ids) {
          final u = await db.usersDao.findUserById(id);
          if (u != null && u.branchId == branchId) users.add(u);
        }
      }
      if (users.isEmpty) {
        final selfId = session?.userId;
        if (selfId != null) {
          final self = await db.usersDao.findUserById(selfId);
          if (self != null && self.branchId == branchId) users.add(self);
        }
      }
      users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _picks = [
          _OrderPick(id: null, label: widget.allUsersLabel),
          ...users.map((u) => _OrderPick(id: u.id, label: u.name)),
        ];
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _picks = [_OrderPick(id: null, label: widget.allUsersLabel)];
        _loaded = true;
      });
    }
  }

  static String _display(_OrderPick o) => o.label;

  @override
  Widget build(BuildContext context) {
    return AutoCompleteTextField<_OrderPick>(
      defaultText: widget.allUsersLabel,
      labelText: widget.labelText,
      items: _picks,
      isLoading: !_loaded,
      displayStringFunction: _display,
      onSelected: (pick) {
        widget.controller.text = pick.label;
        widget.onSelectedUserId(pick.id);
      },
      onChanged: (v) {
        if (v.isEmpty || v.trim().isEmpty) {
          widget.controller.text = widget.allUsersLabel;
          widget.onSelectedUserId(null);
        }
      },
      controller: widget.controller,
    );
  }
}
