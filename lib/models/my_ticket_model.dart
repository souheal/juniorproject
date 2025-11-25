class MyTicketModel {
  final String id;
  final String ticketId;
  final String eventTitle;
  final String eventImageUrl;
  final double ticketAmount;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestDate;
  final DateTime? processedDate;
  final String? adminNote;

  MyTicketModel({
    required this.id,
    required this.ticketId,
    required this.eventTitle,
    required this.eventImageUrl,
    required this.ticketAmount,
    required this.reason,
    required this.status,
    required this.requestDate,
    this.processedDate,
    this.adminNote,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  // Mock data for UI
  static List<MyTicketModel> getMockTickets() {
    return [
      MyTicketModel(
        id: 'TKT001',
        ticketId: 'TKT005',
        eventTitle: 'Jazz Night Under Stars',
        eventImageUrl: 'https://picsum.photos/seed/ticket1/400/200',
        ticketAmount: 65.00,
        reason: 'Unable to attend due to schedule conflict',
        status: 'pending',
        requestDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MyTicketModel(
        id: 'TKT002',
        ticketId: 'TKT006',
        eventTitle: 'Business Summit 2025',
        eventImageUrl: 'https://picsum.photos/seed/ticket2/400/200',
        ticketAmount: 200.00,
        reason: 'Event was cancelled by organizer',
        status: 'approved',
        requestDate: DateTime.now().subtract(const Duration(days: 10)),
        processedDate: DateTime.now().subtract(const Duration(days: 7)),
        adminNote: 'Full refund approved due to event cancellation.',
      ),
      MyTicketModel(
        id: 'TKT003',
        ticketId: 'TKT007',
        eventTitle: 'Photography Workshop',
        eventImageUrl: 'https://picsum.photos/seed/ticket3/400/200',
        ticketAmount: 80.00,
        reason: 'Changed my mind',
        status: 'rejected',
        requestDate: DateTime.now().subtract(const Duration(days: 15)),
        processedDate: DateTime.now().subtract(const Duration(days: 12)),
        adminNote: 'Ticket request submitted after the deadline. Please refer to our policy.',
      ),
    ];
  }

  static List<String> getTicketReasons() {
    return [
      'Unable to attend due to schedule conflict',
      'Event was cancelled',
      'Event was rescheduled',
      'Personal emergency',
      'Purchased wrong tickets',
      'Duplicate purchase',
      'Other',
    ];
  }
}
