import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';

/// Pagination bar: `< 1 2 3 4 >` with prev/next and clickable page numbers.
class NumberedPaginationBar extends StatelessWidget {
  const NumberedPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    this.onPrevious,
    this.onNext,
    this.maxVisiblePages = 7,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final int maxVisiblePages;

  /// Page numbers to show (1-based), with `null` = ellipsis gap.
  static List<int?> visiblePageNumbers({
    required int currentPage,
    required int totalPages,
    int maxVisible = 7,
  }) {
    if (totalPages <= 0) return const [1];
    if (totalPages <= maxVisible) {
      return List<int?>.generate(totalPages, (i) => i + 1);
    }

    final pages = <int?>[];
    const edge = 1;
    final window = maxVisible - 2 - edge * 2;
    var start = (currentPage - window ~/ 2).clamp(2, totalPages - 1);
    var end = start + window - 1;
    if (end >= totalPages) {
      end = totalPages - 1;
      start = (end - window + 1).clamp(2, totalPages - 1);
    }

    pages.add(1);
    if (start > 2) pages.add(null);
    for (var p = start; p <= end; p++) {
      pages.add(p);
    }
    if (end < totalPages - 1) pages.add(null);
    if (totalPages > 1) pages.add(totalPages);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalPages < 1 ? 1 : totalPages;
    final safeCurrent = currentPage.clamp(1, safeTotal);
    final pages = visiblePageNumbers(
      currentPage: safeCurrent,
      totalPages: safeTotal,
      maxVisible: maxVisiblePages,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavButton(
            icon: Icons.chevron_left,
            tooltip: 'Previous page',
            onPressed: onPrevious,
          ),
          ...pages.map((page) {
            if (page == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('…', style: TextStyle(fontSize: 14, color: AppColors.hintFontColor)),
              );
            }
            final selected = page == safeCurrent;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: selected ? AppColors.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: selected ? null : () => onPageSelected(page),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '$page',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          _NavButton(
            icon: Icons.chevron_right,
            tooltip: 'Next page',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: onPressed == null ? Colors.grey.shade400 : AppColors.primaryColor),
    );
  }
}
