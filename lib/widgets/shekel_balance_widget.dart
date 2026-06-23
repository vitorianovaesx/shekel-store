import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

class ShekelBalanceWidget extends StatelessWidget {
  final int balance;
  final bool large;

  const ShekelBalanceWidget({
    super.key,
    required this.balance,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    if (large) {
      return Column(
        children: [
          Image.asset('assets/images/coin.png', width: large ? 48 : 24, height: large ? 48 : 24),
          const SizedBox(height: 4),
          Text(
            '$balance',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            'shekels',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ).animate().fadeIn().scale();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/coin.png', width: 16, height: 16),
          const SizedBox(width: 6),
          Text(
            '$balance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
