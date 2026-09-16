import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Pill-shaped gold → bronze gradient CTA used on the redesigned dashboard.
class GoldGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const GoldGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.goldLight,
                AppColors.gold,
                AppColors.goldBronze,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.textOnGold),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textOnGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
