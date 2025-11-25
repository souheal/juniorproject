import 'dart:convert';
import 'package:http/http.dart' as http;

/// API client for communicating with Laravel backend.
class ApiClient {
  /// Base URL for the Laravel API.
  ///
  /// IMPORTANT: Adjust this based on where you're running Flutter:
  /// - Android emulator: Use 'http://10.0.2.2:8000'
  /// - iOS simulator: Use 'http://127.0.0.1:8000'
  /// - Physical device: Use your computer's LAN IP (e.g., 'http://192.168.1.x:8000')
  static const String baseUrl = 'http://192.168.1.5:8000';



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

    final url = Uri.parse('$baseUrl/api/events/browse').replace(queryParameters: queryParams);

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
}
