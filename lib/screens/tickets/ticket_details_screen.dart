import 'package:flutter/material.dart';
import '../../models/my_ticket_model.dart';
import '../../theme/app_theme.dart';

class TicketDetailsScreen extends StatelessWidget {
  final MyTicketModel ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ticket Details'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 60,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusDescription(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Event Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Event', ticket.eventTitle),
                  _buildDetailRow('Ticket ID', ticket.ticketId),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Ticket Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ticket Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Request ID', ticket.id),
                  _buildDetailRow('Request Date', _formatDate(ticket.requestDate)),
                  if (ticket.processedDate != null)
                    _buildDetailRow('Processed Date', _formatDate(ticket.processedDate!)),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ticket Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${ticket.ticketAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Reason
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ticket.reason,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Admin Note
            if (ticket.adminNote != null && ticket.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ticket.isApproved
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: ticket.isApproved ? AppTheme.successColor : AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Admin Response',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ticket.isApproved ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ticket.adminNote!,
                      style: TextStyle(
                        fontSize: 15,
                        color: ticket.isApproved ? AppTheme.successColor : AppTheme.errorColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Actions
            if (ticket.isPending)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showCancelDialog(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (ticket.isPending) return AppTheme.pendingColor;
    if (ticket.isApproved) return AppTheme.successColor;
    return AppTheme.errorColor;
  }

  IconData _getStatusIcon() {
    if (ticket.isPending) return Icons.schedule;
    if (ticket.isApproved) return Icons.check_circle;
    return Icons.cancel;
  }

  String _getStatusText() {
    if (ticket.isPending) return 'Pending';
    if (ticket.isApproved) return 'Approved';
    return 'Rejected';
  }

  String _getStatusDescription() {
    if (ticket.isPending) return 'Your request is being reviewed';
    if (ticket.isApproved) return 'Your ticket has been approved';
    return 'Your request has been declined';
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this ticket request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket request cancelled'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
