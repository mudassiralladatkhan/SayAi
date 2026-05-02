import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShareCard extends StatelessWidget {
  final int streakDays;
  final String quote;

  const ShareCard({
    Key? key,
    required this.streakDays,
    required this.quote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080 / 3, // Scaled down for UI preview
      height: 1920 / 3,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D1B69),
            AppTheme.backgroundMain,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.smart_toy_rounded, size: 60, color: AppTheme.primaryPurple),
          const SizedBox(height: 16),
          const Text(
            'SayNote AI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCardMedium.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold, width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 40),
                ),
                Text(
                  '$streakDays',
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gold,
                  ),
                ),
                const Text(
                  'Days Streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '"$quote"',
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: AppTheme.textLightGray,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          const Text(
            'Built with YOG',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}
