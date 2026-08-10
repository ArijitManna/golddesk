import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.status,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor ?? colors.$1,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _getStatusColors(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (AppColors.statusPending, AppColors.textOnDark);
      case 'assigned':
        return (AppColors.statusAssigned, AppColors.textOnDark);
      case 'in progress':
      case 'inprogress':
        return (AppColors.statusInProgress, AppColors.textOnDark);
      case 'ready':
        return (AppColors.statusReady, AppColors.textOnDark);
      case 'delivered':
        return (AppColors.statusDelivered, AppColors.textOnDark);
      case 'cancelled':
      case 'cancel':
        return (AppColors.statusCancelled, AppColors.textOnDark);
      case 'overdue':
        return (AppColors.statusOverdue, AppColors.textOnDark);
      default:
        return (AppColors.textSecondary, AppColors.textOnDark);
    }
  }
}
