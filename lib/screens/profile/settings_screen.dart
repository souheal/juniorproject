import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../utils/page_transitions.dart';
import 'change_password_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  String _selectedLanguage = 'English';

  final List<String> _languages = [
    'English',
    'Arabic',
    'French',
    'Spanish',
    'German',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Appearance'),
                const SizedBox(height: 12),
                _buildLanguageTile(),
                const SizedBox(height: 24),

                _buildSectionTitle('Notifications'),
                const SizedBox(height: 12),
                _buildNotificationTile(provider),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Email Notifications',
                  subtitle: 'Receive email updates',
                  value: _emailNotifications,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _emailNotifications = value);
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Privacy & Security'),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, SlidePageRoute(page: const ChangePasswordScreen()));
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, SlidePageRoute(page: const PrivacyPolicyScreen()));
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, SlidePageRoute(page: const TermsOfServiceScreen()));
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Data'),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: Icons.download_outlined,
                  title: 'Download My Data',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preparing your data download...')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Clear Cache',
                  subtitle: '25.4 MB',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showClearCacheDialog();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(ProfileProvider provider) {
    final isEnabled = provider.profile?.notificationsEnabled ?? true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.notifications_outlined, color: AppTheme.primaryColor, size: 22),
        ),
        title: const Text(
          'Push Notifications',
          style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
        ),
        subtitle: const Text(
          'Receive push notifications',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: provider.isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
              )
            : Switch(
                value: isEnabled,
                onChanged: (value) async {
                  HapticFeedback.lightImpact();
                  final result = await provider.updateNotifications(value);
                  if (mounted && !result.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.message), backgroundColor: AppTheme.errorColor),
                    );
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.language, color: AppTheme.primaryColor, size: 22),
        ),
        title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        subtitle: Text(_selectedLanguage, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: () {
          HapticFeedback.lightImpact();
          _showLanguageSelector();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._languages.map((language) {
                  final isSelected = language == _selectedLanguage;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(_getLanguageFlag(language), style: const TextStyle(fontSize: 20))),
                    ),
                    title: Text(
                      language,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedLanguage = language);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLanguageFlag(String language) {
    switch (language) {
      case 'English': return '🇬🇧';
      case 'Arabic': return '🇸🇦';
      case 'French': return '🇫🇷';
      case 'Spanish': return '🇪🇸';
      case 'German': return '🇩🇪';
      default: return '🌍';
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_sweep_rounded, color: AppTheme.warningColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Clear Cache'),
          ],
        ),
        content: const Text(
          'This will clear 25.4 MB of cached data including images and temporary files. Your account data will not be affected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully!'), backgroundColor: AppTheme.successColor),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
