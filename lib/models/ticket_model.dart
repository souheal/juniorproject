class TicketModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String eventImageUrl;
  final DateTime eventDate;
  final String eventTime;
  final String venue;
  final String ticketType;
  final double price;
  final String qrCode;
  final String status; // 'active', 'used', 'expired', 'cancelled'
  final DateTime purchaseDate;
  final String seatNumber;

  TicketModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventImageUrl,
    required this.eventDate,
    required this.eventTime,
    required this.venue,
    required this.ticketType,
    required this.price,
    required this.qrCode,
    required this.status,
    required this.purchaseDate,
    required this.seatNumber,
  });

  bool get isActive => status == 'active';
  bool get isUsed => status == 'used';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  // Mock data for UI
  static List<TicketModel> getMockTickets() {
    return [
      TicketModel(
        id: 'TKT001',
        eventId: '1',
        eventTitle: 'Summer Music Festival 2025',
        eventImageUrl: 'https://picsum.photos/seed/event1/400/200',
        eventDate: DateTime.now().add(const Duration(days: 15)),
        eventTime: '7:00 PM - 11:00 PM',
        venue: 'Damascus Opera House',
        ticketType: 'VIP',
        price: 150.00,
        qrCode: 'QR-TKT001-VIP-2025',
        status: 'active',
        purchaseDate: DateTime.now().subtract(const Duration(days: 5)),
        seatNumber: 'A-12',
      ),
      TicketModel(
        id: 'TKT002',
        eventId: '2',
        eventTitle: 'Tech Conference 2025',
        eventImageUrl: 'https://picsum.photos/seed/event2/400/200',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        eventTime: '9:00 AM - 6:00 PM',
        venue: 'Aleppo Convention Center',
        ticketType: 'Standard',
        price: 150.00,
        qrCode: 'QR-TKT002-STD-2025',
        status: 'active',
        purchaseDate: DateTime.now().subtract(const Duration(days: 10)),
        seatNumber: 'B-45',
      ),
      TicketModel(
        id: 'TKT003',
        eventId: '3',
        eventTitle: 'Food & Wine Festival',
        eventImageUrl: 'https://picsum.photos/seed/event3/400/200',
        eventDate: DateTime.now().subtract(const Duration(days: 7)),
        eventTime: '12:00 PM - 8:00 PM',
        venue: 'Latakia Beach Resort',
        ticketType: 'General',
        price: 45.00,
        qrCode: 'QR-TKT003-GEN-2025',
        status: 'used',
        purchaseDate: DateTime.now().subtract(const Duration(days: 20)),
        seatNumber: 'GA',
      ),
      TicketModel(
        id: 'TKT004',
        eventId: '6',
        eventTitle: 'Comedy Night Live',
        eventImageUrl: 'https://picsum.photos/seed/event6/400/200',
        eventDate: DateTime.now().subtract(const Duration(days: 30)),
        eventTime: '8:00 PM - 11:00 PM',
        venue: 'Comedy Club Damascus',
        ticketType: 'Standard',
        price: 30.00,
        qrCode: 'QR-TKT004-STD-2025',
        status: 'expired',
        purchaseDate: DateTime.now().subtract(const Duration(days: 45)),
        seatNumber: 'C-8',
      ),
    ];
  }
}
