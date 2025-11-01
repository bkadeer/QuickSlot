import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BiometricButton extends StatelessWidget {
  const BiometricButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          // TODO: Implement biometric authentication
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Biometric authentication coming soon'),
              backgroundColor: AppTheme.primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          side: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 24,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 12),
            Text(
              'Sign in with Biometrics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
