import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  const TicketCard({
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left side - Image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: Image.network(
                  ticket.eventImageUrl,
                  width: 100,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Center(
                        child: Icon(Icons.confirmation_number, size: 30, color: AppTheme.primaryColor),
                      ),
                    );
                  },
                ),
              ),
              // Dotted line separator
              Column(
                children: List.generate(
                  10,
                  (index) => Expanded(
                    child: Container(
                      width: 1,
                      color: index.isEven ? AppTheme.textLight : Colors.transparent,
                    ),
                  ),
                ),
              ),
              // Right side - Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ticket.eventTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(ticket.eventDate),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Time
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ticket.eventTime,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Ticket type and seat
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ticket.ticketType,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          Text(
                            'Seat: ${ticket.seatNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (ticket.status) {
      case 'active':
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        text = 'Active';
        break;
      case 'used':
        backgroundColor = AppTheme.textSecondary.withOpacity(0.1);
        textColor = AppTheme.textSecondary;
        text = 'Used';
        break;
      case 'expired':
        backgroundColor = AppTheme.errorColor.withOpacity(0.1);
        textColor = AppTheme.errorColor;
        text = 'Expired';
        break;
      case 'cancelled':
        backgroundColor = AppTheme.errorColor.withOpacity(0.1);
        textColor = AppTheme.errorColor;
        text = 'Cancelled';
        break;
      default:
        backgroundColor = AppTheme.textSecondary.withOpacity(0.1);
        textColor = AppTheme.textSecondary;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
