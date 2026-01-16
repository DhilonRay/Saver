import 'package:flutter/material.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/text_styles.dart';
import 'package:saver/components/widgets/space.dart';


/// Dashboard Stats Card Component
class DashboardStatsCard extends StatelessWidget {
  final String amount;
  final String label;
  final Color? amountColor;
  final Color? backgroundColor;

  const DashboardStatsCard({
    super.key,
    required this.amount,
    required this.label,
    this.amountColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              amount,
              style: AppTextStyles.extraLargeBodyLarge.copyWith(
                color: amountColor ?? AppColors.primary,
                fontSize: 20,
              ),
            ),
            const VerticalGap(4),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// New Order Button Component
class NewOrderButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const NewOrderButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryText),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
        child: Text(
          '+ New Order',
          style: AppTextStyles.bodyLargeMedium.copyWith(
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

/// Order Status Badge Component
class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  Color get _backgroundColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF2E5);
      case 'delivered':
        return const Color(0xFFE8F5E8);
      default:
        return AppColors.gray;
    }
  }

  Color get _textColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF79E1B);
      case 'delivered':
        return AppColors.success;
      default:
        return AppColors.primaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: AppTextStyles.bodySmallMedium.copyWith(color: _textColor),
      ),
    );
  }
}

/// Order List Item Component
class OrderListItem extends StatelessWidget {
  final String orderNumber;
  final String date;
  final String amount;
  final String company;
  final String status;
  final VoidCallback? onViewDetails;

  const OrderListItem({
    super.key,
    required this.orderNumber,
    required this.date,
    required this.amount,
    required this.company,
    required this.status,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$orderNumber | $date',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const VerticalGap(4),
                  Text(
                    amount,
                    style: AppTextStyles.bodyLargeBold.copyWith(
                      color: AppColors.primaryText,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              OrderStatusBadge(status: status),
            ],
          ),
          const VerticalGap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                company,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
              GestureDetector(
                onTap: onViewDetails,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const HorizontalGap(4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section Header Component
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bodyLargeSemibold),
        if (actionText != null && onActionPressed != null)
          GestureDetector(
            onTap: onActionPressed,
            child: Text(
              actionText!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
      ],
    );
  }
}

/// Pagination Component
class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalEntries;
  final int entriesPerPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalEntries,
    required this.entriesPerPage,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final startEntry = (currentPage - 1) * entriesPerPage + 1;
    final endEntry = (currentPage * entriesPerPage).clamp(0, totalEntries);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startEntry to $endEntry of $totalEntries entries',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: currentPage > 1 ? onPrevious : null,
              icon: Icon(
                Icons.chevron_left,
                color:
                    currentPage > 1
                        ? AppColors.primaryText
                        : AppColors.secondary,
              ),
              iconSize: 20,
            ),
            IconButton(
              onPressed: endEntry < totalEntries ? onNext : null,
              icon: Icon(
                Icons.chevron_right,
                color:
                    endEntry < totalEntries
                        ? AppColors.primaryText
                        : AppColors.secondary,
              ),
              iconSize: 20,
            ),
          ],
        ),
      ],
    );
  }
}
