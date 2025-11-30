import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Privacy Policy Screen
///
/// Displays the app's privacy policy to users.
/// Accessible from settings and auth screens.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Information We Collect',
              content: '''
We collect information you provide directly to us, such as:
• Account information (name, email, phone number)
• Profile information (profile picture, location, preferences)
• Event preferences and interactions
• Payment information for ticket purchases
• Communications with our support team

We also automatically collect certain information when you use our app:
• Device information (device type, operating system)
• Log information (access times, pages viewed)
• Location information (with your permission)
''',
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              content: '''
We use the information we collect to:
• Provide, maintain, and improve our services
• Process transactions and send related information
• Send you event recommendations based on your preferences
• Send promotional communications (with your consent)
• Respond to your comments, questions, and requests
• Monitor and analyze trends, usage, and activities
• Detect, investigate, and prevent fraudulent transactions
''',
            ),
            _buildSection(
              title: '3. Information Sharing',
              content: '''
We may share your information in the following situations:
• With event organizers when you purchase tickets
• With service providers who assist in our operations
• In response to legal process or government requests
• To protect our rights, privacy, safety, or property
• In connection with a merger or acquisition

We do not sell your personal information to third parties.
''',
            ),
            _buildSection(
              title: '4. Data Security',
              content: '''
We implement appropriate security measures to protect your personal information, including:
• Encryption of data in transit and at rest
• Regular security assessments and audits
• Access controls and authentication mechanisms
• Secure data storage practices

While we strive to protect your information, no method of transmission over the Internet is 100% secure.
''',
            ),
            _buildSection(
              title: '5. Your Rights',
              content: '''
You have the right to:
• Access your personal information
• Correct inaccurate or incomplete data
• Request deletion of your data
• Opt-out of marketing communications
• Export your data in a portable format
• Withdraw consent at any time

To exercise these rights, please contact us through the app settings or email.
''',
            ),
            _buildSection(
              title: '6. Cookies and Tracking',
              content: '''
We use cookies and similar technologies to:
• Remember your preferences and settings
• Analyze app usage and performance
• Personalize content and recommendations
• Provide social media features

You can manage cookie preferences through your device settings.
''',
            ),
            _buildSection(
              title: '7. Children\'s Privacy',
              content: '''
Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.
''',
            ),
            _buildSection(
              title: '8. Changes to This Policy',
              content: '''
We may update this Privacy Policy from time to time. We will notify you of any changes by:
• Posting the new Privacy Policy in the app
• Sending you an email notification
• Displaying a prominent notice in the app

Your continued use of the app after changes indicates your acceptance of the updated policy.
''',
            ),
            _buildSection(
              title: '9. Contact Us',
              content: '''
If you have any questions about this Privacy Policy, please contact us at:

Email: privacy@eventsapp.com
Address: 123 Event Street, City, Country

We will respond to your inquiry within 30 days.
''',
            ),
            const SizedBox(height: 16),
            _buildLastUpdated(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.privacy_tip_outlined,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'We are committed to protecting your personal information.',
                  style: TextStyle(
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

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return const Center(
      child: Text(
        'Last updated: November 2024',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textLight,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
