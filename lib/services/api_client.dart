import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// API client for communicating with Laravel backend.
class ApiClient {
  /// Base URL for the Laravel API - now from centralized config
  static String get baseUrl => AppConfig.baseUrl;



  /// Register a new user account.
  ///
  /// Sends a POST request to /api/auth/register with the user's registration data.
  /// Returns the HTTP response which should be checked for status code and parsed.
  static Future<http.Response> registerUser(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      return response;
    } catch (e) {
      // Re-throw to let the caller handle connection errors
      rethrow;
    }
  }

  /// Login an existing user.
  ///
  /// Sends a POST request to /api/auth/login with email and password.
  /// Returns the HTTP response which should be checked for status code and parsed.
  static Future<http.Response> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all categories from the API.
  ///
  /// Sends a GET request to /api/categories.
  /// Returns the HTTP response which contains a JSON array of categories.
  static Future<http.Response> getCategories() async {
    final url = Uri.parse('$baseUrl/api/categories');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Browse events with optional filters.
  ///
  /// Sends a GET request to /api/events/browse with query parameters.
  ///
  /// Supported filters:
  /// - category_id: Filter by category ID (int)
  /// - city: Filter by city name (string)
  /// - place: Search in city/location/venue (string)
  /// - date: Filter by specific date (YYYY-MM-DD format)
  /// - live_only: Show only currently live events (bool, send as 1 or 0)
  /// - search: Search in event name/city/location/venue (string)
  /// - page: Pagination page number (int)
  ///
  /// Returns the HTTP response containing paginated event results.
  static Future<http.Response> browseEvents({
    int? categoryId,
    String? city,
    String? place,
    String? date,
    bool? liveOnly,
    String? search,
    int page = 1,
  }) async {
    final Map<String, String> queryParams = {};

    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (place != null && place.isNotEmpty) queryParams['place'] = place;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (liveOnly != null && liveOnly) queryParams['live_only'] = '1';
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    queryParams['page'] = page.toString();

    final url = Uri.parse('$baseUrl/api/events').replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // PROFILE ENDPOINTS
  // All profile endpoints require Authorization: Bearer <token>
  // ============================================================

  /// Get user profile data including stats and account type info.
  ///
  /// GET /api/profile
  /// Requires authentication.
  ///
  /// Returns JSON with 'user', 'stats', and 'account_type' objects.
  static Future<http.Response> getProfile() async {
    final url = Uri.parse('$baseUrl/api/profile');

    try {
      final response = await http.get(
        url,
        headers: AuthHelper.headers,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile (name, phone, location, picture).
  ///
  /// PUT /api/profile
  /// Requires authentication.
  ///
  /// [data] should contain fields to update:
  /// - name: string (optional)
  /// - phone: string (optional)
  /// - location: string (optional)
  /// - picture: base64 encoded image string (optional)
  ///
  /// Returns JSON with 'message' and updated 'user' object.
  static Future<http.Response> updateProfile(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/profile');

    try {
      final response = await http.put(
        url,
        headers: AuthHelper.headers,
        body: json.encode(data),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Change user password.
  ///
  /// POST /api/profile/change-password
  /// Requires authentication.
  ///
  /// [currentPassword] - The user's current password
  /// [newPassword] - The new password (min 8 characters)
  /// [newPasswordConfirmation] - Must match newPassword
  ///
  /// Returns 200 on success, 422 if current password is incorrect.
  static Future<http.Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final url = Uri.parse('$baseUrl/api/profile/change-password');

    try {
      final response = await http.post(
        url,
        headers: AuthHelper.headers,
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        }),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's tickets with event details.
  ///
  /// GET /api/profile/tickets
  /// Requires authentication.
  ///
  /// Returns JSON with 'tickets' array containing ticket objects with nested event data.
  static Future<http.Response> getProfileTickets() async {
    final url = Uri.parse('$baseUrl/api/profile/tickets');

    try {
      final response = await http.get(
        url,
        headers: AuthHelper.headers,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's saved events.
  ///
  /// GET /api/profile/saved-events
  /// Requires authentication.
  ///
  /// Returns JSON with 'events' array containing saved event objects.
  static Future<http.Response> getSavedEvents() async {
    final url = Uri.parse('$baseUrl/api/profile/saved-events');

    try {
      final response = await http.get(
        url,
        headers: AuthHelper.headers,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Save an event to user's saved list.
  ///
  /// POST /api/events/{eventId}/save
  /// Requires authentication.
  ///
  /// Returns 201 on success with 'message'.
  static Future<http.Response> saveEvent(int eventId) async {
    final url = Uri.parse('$baseUrl/api/events/$eventId/save');

    try {
      final response = await http.post(
        url,
        headers: AuthHelper.headers,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove an event from user's saved list.
  ///
  /// DELETE /api/events/{eventId}/save
  /// Requires authentication.
  ///
  /// Returns 200 on success with 'message'.
  static Future<http.Response> unsaveEvent(int eventId) async {
    final url = Uri.parse('$baseUrl/api/events/$eventId/save');

    try {
      final response = await http.delete(
        url,
        headers: AuthHelper.headers,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update notification preferences.
  ///
  /// POST /api/profile/notifications
  /// Requires authentication.
  ///
  /// [enabled] - true to enable notifications, false to disable
  ///
  /// Returns JSON with 'message' and 'notifications_enabled' boolean.
  static Future<http.Response> updateNotifications(bool enabled) async {
    final url = Uri.parse('$baseUrl/api/profile/notifications');

    try {
      final response = await http.post(
        url,
        headers: AuthHelper.headers,
        body: json.encode({'enabled': enabled}),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user account.
  ///
  /// DELETE /api/profile
  /// Requires authentication.
  ///
  /// WARNING: This action is irreversible and will delete all user data.
  /// Returns 200 on success with 'message'.
  static Future<http.Response> deleteAccount() async {
    final url = Uri.parse('$baseUrl/api/profile');

    try {
      final response = await http.delete(
        url,
        headers: AuthHelper.headers,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
