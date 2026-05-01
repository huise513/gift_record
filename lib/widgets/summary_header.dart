import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryHeader extends StatelessWidget {
  final int totalAmountFen;
  final int guestCount;

  const SummaryHeader({
    super.key,
    required this.totalAmountFen,
    required this.guestCount,
  });

  String _formatAmount(int amountFen) {
    final yuan = amountFen / 100;
    if (yuan >= 10000) {
      return '¥${(yuan / 10000).toStringAsFixed(1)}万';
    }
    return '¥${yuan.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '礼金合计',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.accent.withOpacity(0.8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatAmount(totalAmountFen),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Text(
              '共 $guestCount 人',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
