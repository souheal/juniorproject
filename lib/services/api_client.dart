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
  static const String baseUrl = 'http://192.168.1.9:8000';



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
}
