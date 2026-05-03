import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/presentation/widgets/relative_time_text.dart';

class LogCardAction {
  const LogCardAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
}

class CommonLogCard extends StatefulWidget {
  const CommonLogCard({
    super.key,
    required this.tag,
    required this.amount,
    required this.invoiceNumber,
    required this.referenceNumber,
    required this.createdAt,
    this.onDelete,
    required this.actions,
    this.leadingHeader,
    this.extraContent,
    this.orderTakerName,
  });

  final String tag;
  final String amount;
  final String invoiceNumber;
  final String referenceNumber;
  final DateTime createdAt;
  final VoidCallback? onDelete;
  final List<LogCardAction> actions;
  final Widget? leadingHeader;
  final Widget? extraContent;
  final String? orderTakerName;

  @override
  State<CommonLogCard> createState() => _CommonLogCardState();
}

class _CommonLogCardState extends State<CommonLogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.12 : 0.05),
              blurRadius: _hovered ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.invoiceNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.textColor),
                  ),
                  Text(
                    'Ref: ${widget.referenceNumber.trim().isEmpty ? '-' : widget.referenceNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              RelativeTimeText(
                at: widget.createdAt,
                style: AppStyles.getRegularTextStyle(fontSize: 10.5, color: AppColors.hintFontColor),
              ),
              if (widget.extraContent != null) ...[
                const SizedBox(height: 6),
                widget.extraContent!,
              ],
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.divider.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: widget.actions.map(_actionButton).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        if (widget.leadingHeader != null) ...[
          widget.leadingHeader!,
          const SizedBox(width: 4),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF2F3A56),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.tag,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.getBoldTextStyle(fontSize: 16, color: AppColors.textColor),
          ),
        ),
        if (widget.orderTakerName != null && widget.orderTakerName!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            widget.orderTakerName!.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.getRegularTextStyle(fontSize: 10.5, color: AppColors.hintFontColor),
          ),
        ],
        if (widget.onDelete != null) ...[
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 18),
            tooltip: 'Delete order',
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
          ),
        ],
      ],
    );
  }

  Widget _actionButton(LogCardAction action) {
    return Tooltip(
      message: action.tooltip,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Icon(action.icon, size: 16, color: AppColors.textColor),
        ),
      ),
    );
  }
}
