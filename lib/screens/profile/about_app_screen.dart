import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../theme/app_theme.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  // Rate Us - Open app store
  Future<void> _rateApp(BuildContext context) async {
    // You'll need to replace these with your actual app IDs when published
    final String androidPackageName = 'com.yourcompany.juniorproject';
    final String iOSAppId = 'YOUR_IOS_APP_ID';

    try {
      if (Platform.isAndroid) {
        final Uri playStoreUri = Uri.parse('market://details?id=$androidPackageName');
        final Uri playStoreWebUri = Uri.parse('https://play.google.com/store/apps/details?id=$androidPackageName');

        if (await canLaunchUrl(playStoreUri)) {
          await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(playStoreWebUri, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        final Uri appStoreUri = Uri.parse('https://apps.apple.com/app/id$iOSAppId');
        await launchUrl(appStoreUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open app store')),
        );
      }
    }
  }

  // Share App
  Future<void> _shareApp(BuildContext context) async {
    try {
      const String appName = 'Event App';
      const String appDescription = 'Discover and manage events with Event App!';
      const String playStoreLink = 'https://play.google.com/store/apps/details?id=com.yourcompany.juniorproject';

      await Share.share(
        '$appName\n\n$appDescription\n\nDownload now:\n$playStoreLink',
        subject: 'Check out $appName',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share app')),
        );
      }
    }
  }

  // Contact Us via WhatsApp
  Future<void> _contactUs(BuildContext context) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/963935535204?text=Hello, I need help with Event App');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  // Report Bug via WhatsApp
  Future<void> _reportBug(BuildContext context) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/963935535204?text=Bug Report for Event App:%0A%0A');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Event App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Event App is your one-stop solution for discovering and managing events. Browse upcoming events, purchase tickets, request refunds, and manage your profile all in one place.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // Features
            _buildFeatureCard(
              icon: Icons.search,
              title: 'Discover Events',
              description: 'Find events based on your interests and location',
            ),
            _buildFeatureCard(
              icon: Icons.confirmation_number,
              title: 'Digital Tickets',
              description: 'Store and manage all your tickets in one place',
            ),
            _buildFeatureCard(
              icon: Icons.qr_code,
              title: 'QR Code Entry',
              description: 'Easy check-in with digital QR codes',
            ),
            _buildFeatureCard(
              icon: Icons.money_off,
              title: 'Easy Refunds',
              description: 'Request refunds with just a few taps',
            ),
            const SizedBox(height: 32),
            // Links
            _buildLinkTile(
              icon: Icons.star_rate,
              title: 'Rate Us',
              onTap: () => _rateApp(context),
            ),
            _buildLinkTile(
              icon: Icons.share,
              title: 'Share App',
              onTap: () => _shareApp(context),
            ),
            _buildLinkTile(
              icon: Icons.bug_report,
              title: 'Report a Bug',
              onTap: () => _reportBug(context),
            ),
            _buildLinkTile(
              icon: Icons.email_outlined,
              title: 'Contact Us',
              onTap: () => _contactUs(context),
            ),
            const SizedBox(height: 32),
            // Social Links
            const Text(
              'Follow Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(Icons.facebook, () {}),
                const SizedBox(width: 16),
                _buildSocialButton(Icons.camera_alt, () {}),
                const SizedBox(width: 16),
                _buildSocialButton(Icons.alternate_email, () {}),
              ],
            ),
            const SizedBox(height: 32),
            // Copyright
            const Text(
              '2025 Event App. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Made with love in Syria',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }
}
