import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/ticket_dto.dart';

/// API Service for all ticket and payment related operations.
///
/// Uses the existing AuthHelper for authentication tokens.
/// All methods throw [TicketApiException] on failure.
class TicketsApiService {
  /// Get all tickets for the currently authenticated user.
  ///
  /// Calls: GET /api/my-tickets
  /// Returns: List of [TicketDto] with event information
  static Future<List<TicketDto>> getMyTickets() async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/my-tickets');

    try {
      final response = await http.get(
        url,
        headers: AuthHelper.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> ticketsList;
        if (data is List) {
          ticketsList = data;
        } else if (data is Map && data['tickets'] != null) {
          ticketsList = data['tickets'] as List;
        } else if (data is Map && data['data'] != null) {
          ticketsList = data['data'] as List;
        } else {
          ticketsList = [];
        }

        return ticketsList
            .map((json) => TicketDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw TicketApiException(
          'Authentication required. Please log in again.',
          statusCode: 401,
        );
      } else {
        final errorData = _tryParseJson(response.body);
        throw TicketApiException(
          errorData?['message'] ?? 'Failed to load tickets',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TicketApiException) rethrow;
      throw TicketApiException(
        'Network error: Unable to connect to server',
        statusCode: 0,
      );
    }
  }


  /// Initiate checkout for an event ticket.
  ///
  /// Calls: POST /api/events/{eventId}/checkout
  /// Returns: [CheckoutSession] with Stripe checkout URL
  ///
  /// Possible errors:
  /// - 400: Event already started, sold out, or user already has ticket
  /// - 401: Not authenticated
  /// - 404: Event not found
  static Future<CheckoutSession> createCheckoutForEvent(int eventId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/events/$eventId/checkout');

    try {
      final response = await http.post(
        url,
        headers: AuthHelper.headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return CheckoutSession.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw TicketApiException(
          'Please log in to purchase tickets',
          statusCode: 401,
        );
      } else {
        final errorData = _tryParseJson(response.body);
        String message = errorData?['message'] ?? 'Checkout failed';

        // Handle specific error cases
        if (response.statusCode == 400) {
          if (message.toLowerCase().contains('started') ||
              message.toLowerCase().contains('finished')) {
            message = 'This event has already started or ended';
          } else if (message.toLowerCase().contains('sold out') ||
                     message.toLowerCase().contains('capacity')) {
            message = 'Sorry, this event is sold out';
          } else if (message.toLowerCase().contains('already')) {
            message = 'You already have a ticket for this event';
          }
        }

        throw TicketApiException(
          message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TicketApiException) rethrow;
      throw TicketApiException(
        'Network error: Unable to process checkout',
        statusCode: 0,
      );
    }
  }


  /// Scan a ticket QR code (organizer only).
  ///
  /// Calls: POST /api/organizer/tickets/scan
  /// Body: { "qr_code": "..." }
  /// Returns: [ScanResult] with success/failure info
  ///
  /// Possible responses:
  /// - 200: Ticket scanned successfully
  /// - 400: Ticket already used or not paid
  /// - 403: Ticket doesn't belong to organizer's event
  /// - 404: Invalid QR code
  static Future<ScanResult> scanTicket(String qrCode) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/organizer/tickets/scan');

    try {
      final response = await http.post(
        url,
        headers: AuthHelper.headers,
        body: json.encode({'qr_code': qrCode}),
      );

      final data = _tryParseJson(response.body) ?? {};
      return ScanResult.fromJson(data, response.statusCode);
    } catch (e) {
      if (e is TicketApiException) rethrow;
      throw TicketApiException(
        'Network error: Unable to scan ticket',
        statusCode: 0,
      );
    }
  }


  /// Get list of available events for purchase.
  ///
  /// Calls: GET /api/events
  /// Returns: List of [EventForPurchase]
  static Future<List<EventForPurchase>> getAvailableEvents() async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/events');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> eventsList;
        if (data is List) {
          eventsList = data;
        } else if (data is Map && data['data'] != null) {
          eventsList = data['data'] as List;
        } else if (data is Map && data['events'] != null) {
          eventsList = data['events'] as List;
        } else {
          eventsList = [];
        }

        return eventsList
            .map((json) => EventForPurchase.fromJson(json as Map<String, dynamic>))
            .where((event) => !event.hasStarted) // Filter out past events
            .toList();
      } else {
        throw TicketApiException(
          'Failed to load events',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TicketApiException) rethrow;
      throw TicketApiException(
        'Network error: Unable to load events',
        statusCode: 0,
      );
    }
  }


  /// Helper to safely parse JSON
  static Map<String, dynamic>? _tryParseJson(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}


/// Custom exception for ticket API errors
class TicketApiException implements Exception {
  final String message;
  final int statusCode;

  TicketApiException(this.message, {required this.statusCode});

  @override
  String toString() => message;

  bool get isAuthError => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isBadRequest => statusCode == 400;
  bool get isForbidden => statusCode == 403;
  bool get isNetworkError => statusCode == 0;
}
