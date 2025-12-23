import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../models/event_api_model.dart';
import '../services/api_client.dart';
import '../config.dart';

/// Enum representing the current state of async operations
enum ProfileState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider for managing user profile state and API interactions.
///
/// This provider uses ChangeNotifier for state management and handles:
/// - Profile fetching and caching
/// - Profile updates (name, phone, location, picture)
/// - Password changes
/// - Saved events management
/// - Notification preferences
/// - Account deletion
///
/// Usage:
/// ```dart
/// // Wrap your app with ChangeNotifierProvider
/// ChangeNotifierProvider(
///   create: (_) => ProfileProvider(),
///   child: MyApp(),
/// )
///
/// // Access in widgets
/// final profile = context.watch<ProfileProvider>();
/// final provider = context.read<ProfileProvider>();
/// ```
class ProfileProvider extends ChangeNotifier {
  // State
  ProfileState _state = ProfileState.initial;
  UserProfileModel? _profile;
  List<EventApiModel> _savedEvents = [];
  List<UserTicketModel> _tickets = [];
  String? _errorMessage;
  bool _isSaving = false;

  // Getters
  ProfileState get state => _state;
  UserProfileModel? get profile => _profile;
  List<EventApiModel> get savedEvents => _savedEvents;
  List<UserTicketModel> get tickets => _tickets;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  bool get isLoading => _state == ProfileState.loading;
  bool get hasError => _state == ProfileState.error;
  bool get isAuthenticated => AuthHelper.isAuthenticated;

  /// Set profile directly from registration data.
  ///
  /// This allows the app to treat the user as logged in immediately after
  /// signup, even without email verification. The profile data is constructed
  /// from the registration response.
  ///
  /// [userData] - Map containing user data from registration response
  /// [token] - Optional auth token to save
  void setProfileFromRegistration(Map<String, dynamic> userData, {String? token}) {
    if (token != null && token.isNotEmpty) {
      AuthHelper.setToken(token);
    }

    // Build a profile from registration data
    // The backend may return user data in different formats
    final user = userData['user'] ?? userData;

    _profile = UserProfileModel(
      id: user['id'] ?? 0,
      name: user['name'] ?? '',
      email: user['email'] ?? '',
      phone: user['phone'],
      location: user['location'],
      picture: user['picture'],
      emailVerified: user['email_verified'] ?? false,
      notificationsEnabled: user['notifications_enabled'] ?? true,
      accountType: user['account_type'] ?? 'user',
      stats: ProfileStats(events: 0, tickets: 0, saved: 0),
      accountTypeInfo: AccountTypeInfo(
        currentType: 'user',
        latestRequestStatus: null,
        canApplyForOrganizer: true,
      ),
    );

    _state = ProfileState.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set profile from basic registration info when backend doesn't return full user data.
  ///
  /// [name] - User's name from registration form
  /// [email] - User's email from registration form
  /// [phone] - User's phone from registration form
  /// [location] - User's location from registration form
  /// [token] - Optional auth token to save
  void setProfileFromBasicInfo({
    required String name,
    required String email,
    String? phone,
    String? location,
    String? token,
  }) {
    if (token != null && token.isNotEmpty) {
      AuthHelper.setToken(token);
    }

    _profile = UserProfileModel(
      id: 0, // Will be updated when we fetch from API later
      name: name,
      email: email,
      phone: phone,
      location: location,
      picture: null,
      emailVerified: false, // Not verified yet, but we allow access
      notificationsEnabled: true,
      accountType: 'user',
      stats: ProfileStats(events: 0, tickets: 0, saved: 0),
      accountTypeInfo: AccountTypeInfo(
        currentType: 'user',
        latestRequestStatus: null,
        canApplyForOrganizer: true,
      ),
    );

    _state = ProfileState.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if we have a valid session (either token or local profile).
  bool get hasValidSession => AuthHelper.isAuthenticated || _profile != null;

  /// Fetch user profile from API.
  ///
  /// Sets state to loading, fetches profile, and updates state based on result.
  /// If no token but we have local profile, returns success with local data.
  /// Returns true if successful, false otherwise.
  Future<bool> fetchProfile() async {
    // If we have local profile but no token, just return success
    // This handles the case after signup when backend doesn't return token
    if (!AuthHelper.isAuthenticated) {
      if (_profile != null) {
        // We have local profile data, use it
        _state = ProfileState.loaded;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Not authenticated. Please log in.';
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }

    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.getProfile();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _profile = UserProfileModel.fromJson(data);
        _state = ProfileState.loaded;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        // Token invalid, but if we have local profile, keep using it
        if (_profile != null) {
          _state = ProfileState.loaded;
          notifyListeners();
          return true;
        }
        _errorMessage = 'Session expired. Please log in again.';
        _state = ProfileState.error;
        AuthHelper.clearToken();
        notifyListeners();
        return false;
      } else {
        // API error, but if we have local profile, keep using it
        if (_profile != null) {
          _state = ProfileState.loaded;
          notifyListeners();
          return true;
        }
        final data = json.decode(response.body);
        _errorMessage = data['message'] ?? 'Failed to load profile';
        _state = ProfileState.error;
        notifyListeners();
        return false;
      }
    } on SocketException {
      // No internet, but if we have local profile, keep using it
      if (_profile != null) {
        _state = ProfileState.loaded;
        notifyListeners();
        return true;
      }
      _errorMessage = 'No internet connection. Please check your network.';
      _state = ProfileState.error;
      notifyListeners();
      return false;
    } catch (e) {
      // Error, but if we have local profile, keep using it
      if (_profile != null) {
        _state = ProfileState.loaded;
        notifyListeners();
        return true;
      }
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile.
  ///
  /// [name] - New display name (optional)
  /// [phone] - New phone number (optional)
  /// [location] - New location/city (optional)
  /// [pictureBase64] - Base64 encoded image (optional)
  ///
  /// Returns a [ProfileUpdateResult] with success status and message.
  Future<ProfileUpdateResult> updateProfile({
    String? name,
    String? phone,
    String? location,
    String? pictureBase64,
  }) async {
    if (!AuthHelper.isAuthenticated) {
      // No token - update local profile only
      if (_profile != null) {
        _profile = _profile!.copyWith(
          name: name ?? _profile!.name,
          phone: phone ?? _profile!.phone,
          location: location ?? _profile!.location,
        );
        notifyListeners();
        return ProfileUpdateResult(
          success: true,
          message: 'Profile updated locally. Server sync requires login.',
        );
      }
      return ProfileUpdateResult(
        success: false,
        message: 'Please log in to update your profile.',
      );
    }

    _isSaving = true;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (name != null && name.isNotEmpty) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (location != null) data['location'] = location;
      if (pictureBase64 != null) data['picture'] = pictureBase64;

      final response = await ApiClient.updateProfile(data);

      _isSaving = false;

      if (response.statusCode == 200) {
        // Refresh profile to get updated data
        await fetchProfile();
        notifyListeners();
        return ProfileUpdateResult(
          success: true,
          message: 'Profile updated successfully.',
        );
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        final errors = responseData['errors'] as Map<String, dynamic>?;
        String errorMsg = 'Validation failed.';
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMsg = firstError.first.toString();
          }
        }
        notifyListeners();
        return ProfileUpdateResult(success: false, message: errorMsg);
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        _state = ProfileState.error;
        _errorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      } else {
        final responseData = json.decode(response.body);
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: responseData['message'] ?? 'Failed to update profile.',
        );
      }
    } on SocketException {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Change user password.
  ///
  /// [currentPassword] - The user's current password
  /// [newPassword] - The new password (min 8 characters)
  /// [confirmPassword] - Must match newPassword
  ///
  /// Returns a [ProfileUpdateResult] with success status and message.
  Future<ProfileUpdateResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!AuthHelper.isAuthenticated) {
      return ProfileUpdateResult(
        success: false,
        message: 'Please verify your email and log in to change password.',
      );
    }

    _isSaving = true;
    notifyListeners();

    try {
      final response = await ApiClient.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );

      _isSaving = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return ProfileUpdateResult(
          success: true,
          message: 'Password changed successfully.',
        );
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        return ProfileUpdateResult(
          success: false,
          message: responseData['message'] ?? 'Current password is incorrect.',
        );
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        _state = ProfileState.error;
        _errorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      } else {
        final responseData = json.decode(response.body);
        return ProfileUpdateResult(
          success: false,
          message: responseData['message'] ?? 'Failed to change password.',
        );
      }
    } on SocketException {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Fetch user's saved events.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> fetchSavedEvents() async {
    if (!AuthHelper.isAuthenticated) {
      // No token - return empty list, not an error
      _savedEvents = [];
      notifyListeners();
      return true; // Not an error, just no saved events available
    }

    try {
      final response = await ApiClient.getSavedEvents();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final eventsList = data['events'] as List<dynamic>? ?? [];
        _savedEvents = eventsList
            .map((e) => EventApiModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        _errorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return false;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'] ?? 'Failed to load saved events';
        notifyListeners();
        return false;
      }
    } on SocketException {
      _errorMessage = 'No internet connection. Please check your network.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Save an event to user's saved list.
  ///
  /// [eventId] - The ID of the event to save
  ///
  /// Returns a [ProfileUpdateResult] with success status and message.
  Future<ProfileUpdateResult> saveEvent(int eventId) async {
    if (!AuthHelper.isAuthenticated) {
      return ProfileUpdateResult(
        success: false,
        message: 'Please verify your email and log in to save events.',
      );
    }

    try {
      final response = await ApiClient.saveEvent(eventId);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh saved events and profile stats
        await fetchSavedEvents();
        await fetchProfile();
        return ProfileUpdateResult(
          success: true,
          message: 'Event saved successfully.',
        );
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        return ProfileUpdateResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      } else {
        final data = json.decode(response.body);
        return ProfileUpdateResult(
          success: false,
          message: data['message'] ?? 'Failed to save event.',
        );
      }
    } on SocketException {
      return ProfileUpdateResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ProfileUpdateResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Remove an event from user's saved list.
  ///
  /// [eventId] - The ID of the event to unsave
  ///
  /// Returns a [ProfileUpdateResult] with success status and message.
  Future<ProfileUpdateResult> unsaveEvent(int eventId) async {
    if (!AuthHelper.isAuthenticated) {
      return ProfileUpdateResult(
        success: false,
        message: 'Please verify your email and log in to manage saved events.',
      );
    }

    try {
      final response = await ApiClient.unsaveEvent(eventId);

      if (response.statusCode == 200) {
        // Remove from local list immediately for responsiveness
        _savedEvents.removeWhere((event) => event.id == eventId);
        notifyListeners();
        // Refresh profile stats
        await fetchProfile();
        return ProfileUpdateResult(
          success: true,
          message: 'Event removed from saved list.',
        );
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        return ProfileUpdateResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      } else {
        final data = json.decode(response.body);
        return ProfileUpdateResult(
          success: false,
          message: data['message'] ?? 'Failed to remove event.',
        );
      }
    } on SocketException {
      return ProfileUpdateResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ProfileUpdateResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Check if an event is saved.
  bool isEventSaved(int eventId) {
    return _savedEvents.any((event) => event.id == eventId);
  }

  /// Fetch user's tickets.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> fetchTickets() async {
    if (!AuthHelper.isAuthenticated) {
      // No token - return empty list, not an error
      _tickets = [];
      notifyListeners();
      return true; // Not an error, just no tickets available
    }

    try {
      final response = await ApiClient.getProfileTickets();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ticketsList = data['tickets'] as List<dynamic>? ?? [];
        _tickets = ticketsList
            .map((t) => UserTicketModel.fromJson(t as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        _errorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return false;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'] ?? 'Failed to load tickets';
        notifyListeners();
        return false;
      }
    } on SocketException {
      _errorMessage = 'No internet connection. Please check your network.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Update notification preferences.
  ///
  /// [enabled] - true to enable notifications, false to disable
  ///
  /// Returns a [ProfileUpdateResult] with success status and message.
  Future<ProfileUpdateResult> updateNotifications(bool enabled) async {
    if (!AuthHelper.isAuthenticated) {
      // No token - update local profile only
      if (_profile != null) {
        _profile = _profile!.copyWith(notificationsEnabled: enabled);
        notifyListeners();
        return ProfileUpdateResult(
          success: true,
          message: enabled ? 'Notifications enabled locally.' : 'Notifications disabled locally.',
        );
      }
      return ProfileUpdateResult(
        success: false,
        message: 'Please verify your email and log in to update settings.',
      );
    }

    _isSaving = true;
    notifyListeners();

    try {
      final response = await ApiClient.updateNotifications(enabled);

      _isSaving = false;

      if (response.statusCode == 200) {
        // Update local profile state
        if (_profile != null) {
          _profile = _profile!.copyWith(notificationsEnabled: enabled);
        }
        notifyListeners();
        return ProfileUpdateResult(
          success: true,
          message: enabled
              ? 'Notifications enabled.'
              : 'Notifications disabled.',
        );
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        _state = ProfileState.error;
        _errorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      } else {
        final data = json.decode(response.body);
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: data['message'] ?? 'Failed to update notification settings.',
        );
      }
    } on SocketException {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Delete user account.
  ///
  /// WARNING: This action is irreversible.
  ///
  /// Returns a [ProfileUpdateResult] with success status and message.
  Future<ProfileUpdateResult> deleteAccount() async {
    if (!AuthHelper.isAuthenticated) {
      return ProfileUpdateResult(
        success: false,
        message: 'Please verify your email and log in to delete your account.',
      );
    }

    _isSaving = true;
    notifyListeners();

    try {
      final response = await ApiClient.deleteAccount();

      _isSaving = false;

      if (response.statusCode == 200) {
        // Clear all local data
        clearLocalData();
        return ProfileUpdateResult(
          success: true,
          message: 'Account deleted successfully.',
        );
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        _state = ProfileState.error;
        _errorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      } else {
        final data = json.decode(response.body);
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: data['message'] ?? 'Failed to delete account.',
        );
      }
    } on SocketException {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Clear all local profile data.
  ///
  /// Called on logout or account deletion.
  void clearLocalData() {
    _profile = null;
    _savedEvents = [];
    _tickets = [];
    _state = ProfileState.initial;
    _errorMessage = null;
    _isSaving = false;
    AuthHelper.clearToken();
    notifyListeners();
  }

  /// Logout user - clears token and local data.
  void logout() {
    clearLocalData();
  }

  /// Set authentication token and fetch profile.
  ///
  /// Call this after successful login.
  Future<void> setTokenAndFetchProfile(String token) async {
    AuthHelper.setToken(token);
    await fetchProfile();
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Submit an organizer request.
  ///
  /// [organizationName] - Name of the organization (required)
  /// [description] - Description of the organization (required)
  /// [documentBytes] - Optional document file bytes
  /// [documentFileName] - Optional document file name
  ///
  /// Returns a [ProfileUpdateResult] with success status and message.
  Future<ProfileUpdateResult> submitOrganizerRequest({
    required String organizationName,
    required String description,
    List<int>? documentBytes,
    String? documentFileName,
  }) async {
    if (!AuthHelper.isAuthenticated) {
      return ProfileUpdateResult(
        success: false,
        message: 'Please log in to submit an organizer request.',
      );
    }

    _isSaving = true;
    notifyListeners();

    try {
      final response = await ApiClient.submitOrganizerRequest(
        organizationName: organizationName,
        description: description,
        documentBytes: documentBytes,
        documentFileName: documentFileName,
      );

      _isSaving = false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh profile to get updated account_type info
        await fetchProfile();
        notifyListeners();
        return ProfileUpdateResult(
          success: true,
          message: 'Your organizer request has been submitted successfully.',
        );
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: data['message'] ?? 'Only normal users can submit organizer requests.',
        );
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final errors = data['errors'] as Map<String, dynamic>?;
        String errorMsg = 'Validation failed.';
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMsg = firstError.first.toString();
          }
        }
        notifyListeners();
        return ProfileUpdateResult(success: false, message: errorMsg);
      } else if (response.statusCode == 401) {
        AuthHelper.clearToken();
        _state = ProfileState.error;
        _errorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      } else {
        final data = json.decode(response.body);
        notifyListeners();
        return ProfileUpdateResult(
          success: false,
          message: data['message'] ?? 'Failed to submit organizer request.',
        );
      }
    } on SocketException {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return ProfileUpdateResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }
}

/// Result class for profile update operations.
class ProfileUpdateResult {
  final bool success;
  final String message;

  ProfileUpdateResult({
    required this.success,
    required this.message,
  });
}
