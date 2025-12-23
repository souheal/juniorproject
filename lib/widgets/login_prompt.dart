import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/auth_screen.dart';
import '../config.dart';

/// Shows a bottom sheet prompting the user to log in or sign up.
///
/// Use this when a guest user tries to perform a restricted action.
///
/// Returns `true` if user successfully logged in, `false` otherwise.
Future<bool> showLoginPrompt(
  BuildContext context, {
  String? title,
  String? message,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LoginPromptSheet(
      title: title,
      message: message,
    ),
  );
  return result ?? false;
}

/// A reusable bottom sheet widget that prompts users to log in or sign up.
class LoginPromptSheet extends StatelessWidget {
  final String? title;
  final String? message;

  const LoginPromptSheet({
    super.key,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title ?? 'Login Required',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            message ?? 'Please log in or create an account to continue.',
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Login button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToAuth(context, AuthMode.signIn),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sign up button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _navigateToAuth(context, AuthMode.signUp),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAuth(BuildContext context, AuthMode mode) {
    // Exit guest mode before navigating to auth
    AuthHelper.exitGuestMode();

    Navigator.pop(context, false); // Close the bottom sheet

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          onCompleted: (ctx) {
            // User successfully logged in
            Navigator.pop(ctx, true);
          },
        ),
      ),
    );
  }
}

/// Helper function to check if user is guest and show login prompt if needed.
///
/// Returns `true` if action can proceed (user is authenticated),
/// `false` if user is guest and chose not to log in.
///
/// Usage:
/// ```dart
/// if (await requireAuth(context, message: 'Log in to buy tickets')) {
///   // Proceed with ticket purchase
/// }
/// ```
Future<bool> requireAuth(
  BuildContext context, {
  String? title,
  String? message,
}) async {
  if (AuthHelper.isAuthenticated) {
    return true;
  }

  if (AuthHelper.isGuest) {
    return await showLoginPrompt(
      context,
      title: title,
      message: message,
    );
  }

  // Not authenticated and not guest - shouldn't happen but handle it
  return await showLoginPrompt(context, title: title, message: message);
}
