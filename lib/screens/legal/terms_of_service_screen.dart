import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Terms of Service Screen
///
/// Displays the app's terms of service to users.
/// Accessible from settings and auth screens.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Terms of Service'),
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
              title: '1. Acceptance of Terms',
              content: '''
By accessing or using our Events App, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.

These terms apply to all users, including:
• Event attendees and ticket purchasers
• Event organizers and promoters
• Vendors and partners
• General visitors

We reserve the right to update these terms at any time. Continued use of the app constitutes acceptance of any modifications.
''',
            ),
            _buildSection(
              title: '2. Account Registration',
              content: '''
To access certain features, you must create an account. You agree to:
• Provide accurate and complete information
• Maintain the security of your account credentials
• Accept responsibility for all activities under your account
• Notify us immediately of any unauthorized access
• Not share your account with others

We reserve the right to suspend or terminate accounts that violate these terms or engage in fraudulent activity.
''',
            ),
            _buildSection(
              title: '3. Event Tickets and Purchases',
              content: '''
When purchasing tickets through our app:
• All sales are final unless otherwise stated
• Refund policies are set by individual event organizers
• Ticket prices may include service fees
• You must present valid tickets for event entry
• Resale of tickets may be prohibited or restricted

We act as an intermediary between you and event organizers. We are not responsible for:
• Event cancellations or changes by organizers
• Quality or safety of events
• Actions of other attendees
''',
            ),
            _buildSection(
              title: '4. User Conduct',
              content: '''
You agree not to:
• Use the app for any unlawful purpose
• Harass, abuse, or harm other users
• Post false, misleading, or offensive content
• Attempt to gain unauthorized access to our systems
• Use automated systems to access our services
• Interfere with the proper functioning of the app
• Violate intellectual property rights
• Engage in fraudulent transactions

Violation of these rules may result in immediate account termination.
''',
            ),
            _buildSection(
              title: '5. Intellectual Property',
              content: '''
All content on this app is protected by intellectual property laws:
• App design, logos, and trademarks belong to us
• Event content belongs to respective organizers
• User-generated content remains yours, but you grant us a license to use it

You may not:
• Copy, modify, or distribute our content without permission
• Use our trademarks without written authorization
• Reverse engineer our software or systems
''',
            ),
            _buildSection(
              title: '6. Limitation of Liability',
              content: '''
To the maximum extent permitted by law:
• We provide the app "as is" without warranties
• We are not liable for indirect, incidental, or consequential damages
• Our total liability is limited to the amount you paid for services
• We are not responsible for third-party content or services

You acknowledge that:
• Internet-based services may have interruptions
• We cannot guarantee error-free operation
• You use the app at your own risk
''',
            ),
            _buildSection(
              title: '7. Indemnification',
              content: '''
You agree to indemnify and hold harmless our company, its officers, directors, employees, and agents from any claims, damages, losses, or expenses arising from:
• Your use of the app
• Your violation of these terms
• Your violation of any third-party rights
• Content you submit or share through the app
''',
            ),
            _buildSection(
              title: '8. Dispute Resolution',
              content: '''
Any disputes arising from these terms or your use of the app will be:
• First addressed through informal negotiation
• Resolved through binding arbitration if negotiation fails
• Governed by the laws of our jurisdiction

You agree to:
• Waive your right to participate in class action lawsuits
• Submit disputes within one year of the issue arising
• Arbitrate disputes on an individual basis
''',
            ),
            _buildSection(
              title: '9. Termination',
              content: '''
We may terminate or suspend your access to the app:
• For violation of these terms
• For engaging in fraudulent or illegal activities
• At our discretion with or without notice

Upon termination:
• Your right to use the app ceases immediately
• We may delete your account and data
• Provisions that should survive termination will remain in effect
''',
            ),
            _buildSection(
              title: '10. Contact Information',
              content: '''
For questions about these Terms of Service, please contact us:

Email: legal@eventsapp.com
Address: 123 Event Street, City, Country
Phone: +1 (555) 123-4567

Business Hours: Monday - Friday, 9 AM - 5 PM
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
              Icons.description_outlined,
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
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please read these terms carefully before using our app.',
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
