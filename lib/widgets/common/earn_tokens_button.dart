import 'package:flutter/material.dart';
import 'package:aichat/core/services/subscription_state_manager.dart';

class EarnTokensButton extends StatelessWidget {
  const EarnTokensButton({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionManager = SubscriptionStateManager();

    // Don't show for Pro users
    if (subscriptionManager.isPro) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, '/ads');
      },
      icon: const Icon(Icons.play_circle_outline, size: 16),
      label: const Text('Earn Free Tokens'),
      style: TextButton.styleFrom(foregroundColor: Colors.green),
    );
  }
}
