import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final String status;

  Color get _color {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.orangeAccent;
      case 'CONFIRMED':
        return AppColors.navyBlue;
      case 'PACKED':
        return const Color(0xFF6366F1);
      case 'OUT_FOR_DELIVERY':
        return const Color(0xFF0EA5E9);
      case 'DELIVERED':
        return AppColors.primaryGreen;
      case 'CANCELLED':
        return AppColors.errorRed;
      default:
        return AppColors.textGrey;
    }
  }

  String get _label {
    return status.replaceAll('_', ' ').toLowerCase().split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
