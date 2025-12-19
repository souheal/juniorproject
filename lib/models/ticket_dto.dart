/// Data Transfer Object for Ticket from the API.
///
/// Maps to the JSON returned by GET /api/my-tickets endpoint.
class TicketDto {
  final int id;
  final String qrCode;
  final String paymentStatus; // 'pending', 'paid'
  final bool isScanned;
  final DateTime? scannedAt;
  final EventInTicketDto event;

  TicketDto({
    required this.id,
    required this.qrCode,
    required this.paymentStatus,
    required this.isScanned,
    this.scannedAt,
    required this.event,
  });

  factory TicketDto.fromJson(Map<String, dynamic> json) {
    return TicketDto(
      id: json['id'] as int,
      qrCode: json['qr_code'] as String,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      isScanned: json['is_scanned'] as bool? ?? false,
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'] as String)
          : null,
      event: EventInTicketDto.fromJson(json['event'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qr_code': qrCode,
      'payment_status': paymentStatus,
      'is_scanned': isScanned,
      'scanned_at': scannedAt?.toIso8601String(),
      'event': event.toJson(),
    };
  }

  /// Check if ticket is paid
  bool get isPaid => paymentStatus == 'paid';

  /// Check if ticket is pending payment
  bool get isPending => paymentStatus == 'pending';

  /// Check if ticket is valid (paid and not scanned)
  bool get isValid => isPaid && !isScanned;

  /// Check if ticket has been used
  bool get isUsed => isScanned;

  /// Get the QR code image URL using external QR API
  String get qrCodeImageUrl =>
      'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$qrCode';
}


/// Event information embedded in ticket response.
class EventInTicketDto {
  final int id;
  final String name;
  final String? city;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final double? price;
  final String? picture;

  EventInTicketDto({
    required this.id,
    required this.name,
    this.city,
    this.location,
    required this.startTime,
    required this.endTime,
    this.price,
    this.picture,
  });

  factory EventInTicketDto.fromJson(Map<String, dynamic> json) {
    return EventInTicketDto(
      id: json['id'] as int,
      name: json['name'] as String,
      city: json['city'] as String?,
      location: json['location'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      picture: json['picture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'price': price,
      'picture': picture,
    };
  }

  /// Get full location string
  String get fullLocation {
    if (city != null && location != null) {
      return '$location, $city';
    }
    return location ?? city ?? 'Location TBA';
  }

  /// Check if event has started
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// Check if event has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Check if event is upcoming
  bool get isUpcoming => !hasStarted;
}


/// Checkout session response from POST /api/events/{event}/checkout
class CheckoutSession {
  final String checkoutUrl;
  final String sessionId;

  CheckoutSession({
    required this.checkoutUrl,
    required this.sessionId,
  });

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      checkoutUrl: json['checkout_url'] as String,
      sessionId: json['session_id'] as String,
    );
  }
}


/// Result from scanning a ticket via POST /api/organizer/tickets/scan
class ScanResult {
  final bool success;
  final String message;
  final DateTime? scannedAt;
  final String? errorCode; // 'already_used', 'not_paid', 'not_found', 'not_your_event'

  ScanResult({
    required this.success,
    required this.message,
    this.scannedAt,
    this.errorCode,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json, int statusCode) {
    final bool isSuccess = statusCode >= 200 && statusCode < 300;

    String message = json['message'] as String? ??
        (isSuccess ? 'Ticket scanned successfully' : 'Scan failed');

    String? errorCode;
    if (!isSuccess) {
      if (message.toLowerCase().contains('already')) {
        errorCode = 'already_used';
      } else if (message.toLowerCase().contains('not paid') ||
                 message.toLowerCase().contains('payment')) {
        errorCode = 'not_paid';
      } else if (message.toLowerCase().contains('not found') ||
                 message.toLowerCase().contains('invalid')) {
        errorCode = 'not_found';
      } else if (message.toLowerCase().contains('belong') ||
                 message.toLowerCase().contains('forbidden')) {
        errorCode = 'not_your_event';
      }
    }

    return ScanResult(
      success: isSuccess,
      message: message,
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'] as String)
          : (isSuccess ? DateTime.now() : null),
      errorCode: errorCode,
    );
  }
}


/// Simple event model for event selection dropdown
class EventForPurchase {
  final int id;
  final String name;
  final String? city;
  final double price;
  final DateTime startTime;
  final int? availableCapacity;

  EventForPurchase({
    required this.id,
    required this.name,
    this.city,
    required this.price,
    required this.startTime,
    this.availableCapacity,
  });

  factory EventForPurchase.fromJson(Map<String, dynamic> json) {
    return EventForPurchase(
      id: json['id'] as int,
      name: json['name'] as String,
      city: json['city'] as String?,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      startTime: DateTime.parse(json['start_time'] as String),
      availableCapacity: json['available_capacity'] as int?,
    );
  }

  bool get isFree => price == 0;
  bool get hasStarted => DateTime.now().isAfter(startTime);
}
