/// Application configuration - single source of truth for API settings.
///
/// This file contains all configurable settings for the app, including
/// the base URL for API requests and authentication helpers.
library;

class AppConfig {
  /// Base URL for all API requests
  /// Change this to your production URL when deploying
  static const String baseUrl = 'http://192.168.1.13:8000';

  /// API version prefix
  static const String apiPrefix = '/api';

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Storage URL for images (Laravel storage)
  static String get storageUrl => '$baseUrl/storage';

  /// Request timeout duration in seconds
  static const int requestTimeout = 30;

  /// Private constructor to prevent instantiation
  AppConfig._();
}

/// Development helper for authentication
///
/// This class provides a way to set/get the auth token during development
/// when the login screen may not be in scope.
///
/// Usage:
/// ```dart
/// // Set token after login (or manually for testing)
/// AuthHelper.setToken('your-bearer-token-here');
///
/// // Get token for API requests
/// final token = AuthHelper.token;
///
/// // Check if authenticated
/// if (AuthHelper.isAuthenticated) { ... }
/// ```
class AuthHelper {
  static String? _token;
  static bool _isGuest = false;

  /// Current authentication token
  static String? get token => _token;

  /// Check if user is in guest mode
  static bool get isGuest => _isGuest;

  /// Check if user is authenticated (not a guest and has token)
  static bool get isAuthenticated => !_isGuest && _token != null && _token!.isNotEmpty;

  /// Set the authentication token
  /// Call this after successful login
  static void setToken(String? token) {
    _token = token;
    _isGuest = false; // Clear guest mode when setting token
  }

  /// Clear the authentication token
  /// Call this on logout
  static void clearToken() {
    _token = null;
    _isGuest = false;
  }

  /// Enable guest mode
  /// Call this when user chooses "Continue as Guest"
  static void setGuestMode() {
    _token = null;
    _isGuest = true;
  }

  /// Exit guest mode (used before login/signup)
  static void exitGuestMode() {
    _isGuest = false;
  }

  /// Check if user can browse (either authenticated or guest)
  static bool get canBrowse => isAuthenticated || _isGuest;

  /// Get authorization header map for API requests
  /// Returns empty map if not authenticated
  static Map<String, String> get authHeader {
    if (!isAuthenticated) return {};
    return {'Authorization': 'Bearer $_token'};
  }

  /// Get all common headers including auth (if available)
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...authHeader,
    };
  }

  /// Private constructor to prevent instantiation
  AuthHelper._();
}
