import 'package:flutter/material.dart';
import '../models/my_ticket_model.dart';
import '../theme/app_theme.dart';

class MyTicketCard extends StatelessWidget {
  final MyTicketModel ticket;
  final VoidCallback onTap;

  const MyTicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.eventTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ticket ID: ${ticket.ticketId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              color: AppTheme.textLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            // Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ticket Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${ticket.ticketAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(ticket.requestDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Reason
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket.reason,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Admin note if processed
            if (ticket.adminNote != null && ticket.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ticket.isApproved
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      ticket.isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                      size: 16,
                      color: ticket.isApproved ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ticket.adminNote!,
                        style: TextStyle(
                          fontSize: 13,
                          color: ticket.isApproved ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (ticket.status) {
      case 'pending':
        backgroundColor = AppTheme.pendingColor.withValues(alpha: 0.1);
        textColor = AppTheme.pendingColor;
        text = 'Pending';
        icon = Icons.schedule;
        break;
      case 'approved':
        backgroundColor = AppTheme.successColor.withValues(alpha: 0.1);
        textColor = AppTheme.successColor;
        text = 'Approved';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = AppTheme.errorColor.withValues(alpha: 0.1);
        textColor = AppTheme.errorColor;
        text = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = AppTheme.textSecondary.withValues(alpha: 0.1);
        textColor = AppTheme.textSecondary;
        text = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
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
