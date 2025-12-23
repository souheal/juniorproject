# Profile Management Feature

This document describes the Flutter frontend implementation for the Profile Management feature, which integrates with the existing Laravel backend API.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Configuration](#configuration)
4. [API Endpoints](#api-endpoints)
5. [State Management](#state-management)
6. [Screens](#screens)
7. [Running the App](#running-the-app)
8. [Testing](#testing)
9. [Error Handling](#error-handling)

---

## Overview

The Profile Management feature provides:
- View and edit user profile (name, phone, location, picture)
- Change password
- View and manage saved events
- Toggle push notification preferences
- Delete account functionality
- Session management with authentication tokens

### Technology Stack

- **State Management**: Provider (ChangeNotifier pattern)
- **HTTP Client**: http package
- **Image Handling**: image_picker, cached_network_image
- **UI**: Material Design 3 with custom theme

---

## Architecture

```
lib/
├── config.dart                          # App configuration (BASE_URL, AuthHelper)
├── main.dart                            # App entry point with Provider setup
├── models/
│   └── user_profile_model.dart          # Profile data models
├── providers/
│   └── profile_provider.dart            # Profile state management
├── services/
│   └── api_client.dart                  # API client with profile endpoints
├── screens/
│   └── profile/
│       ├── profile_screen.dart          # Main profile screen
│       ├── edit_profile_screen.dart     # Edit profile form
│       ├── change_password_screen.dart  # Password change screen
│       ├── saved_events_screen.dart     # Saved events list
│       └── settings_screen.dart         # App settings
└── widgets/
    └── error_retry_widget.dart          # Reusable error/retry widgets
```

---

## Configuration

### Setting the Base URL

Edit `lib/config.dart` to configure the API base URL:

```dart
class AppConfig {
  /// Change this to your backend URL
  static const String baseUrl = 'http://192.168.1.13:8000';
  // For Android emulator: 'http://10.0.2.2:8000'
  // For iOS simulator: 'http://127.0.0.1:8000'
  // For production: 'https://your-api-domain.com'
}
```

### Setting the Auth Token (Development)

For development/testing, you can manually set the auth token:

```dart
import 'package:juniorproject/config.dart';

// After login, set the token
AuthHelper.setToken('your-bearer-token-here');

// Check if authenticated
if (AuthHelper.isAuthenticated) {
  // User is logged in
}

// On logout
AuthHelper.clearToken();
```

In production, the token should be stored securely using `flutter_secure_storage` and persisted across app launches.

---

## API Endpoints

All protected endpoints require the `Authorization: Bearer <token>` header.

### GET /api/profile

Fetches user profile with stats and account type info.

**Response Example:**
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+963912345678",
    "location": "Damascus",
    "picture": "http://192.168.1.13:8000/storage/users/abc123.jpg",
    "email_verified": true,
    "notifications_enabled": true,
    "account_type": "user"
  },
  "stats": {
    "events": 12,
    "tickets": 8,
    "saved": 5
  },
  "account_type": {
    "current_type": "user",
    "latest_request_status": null,
    "can_apply_for_organizer": true
  }
}
```

### PUT /api/profile

Updates user profile.

**Request Body:**
```json
{
  "name": "Jane Doe",
  "phone": "+963912345678",
  "location": "Aleppo",
  "picture": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
}
```

**Response:**
```json
{
  "message": "Profile updated successfully.",
  "user": { ... }
}
```

### POST /api/profile/change-password

Changes user password.

**Request Body:**
```json
{
  "current_password": "oldpassword123",
  "new_password": "newpassword456",
  "new_password_confirmation": "newpassword456"
}
```

**Response (200):**
```json
{
  "message": "Password updated successfully."
}
```

**Response (422 - Wrong Password):**
```json
{
  "message": "Current password is incorrect."
}
```

### GET /api/profile/saved-events

Fetches user's saved events.

**Response:**
```json
{
  "events": [
    {
      "id": 1,
      "name": "Tech Conference 2024",
      "description": "...",
      "picture": "events/event1.jpg",
      "start_time": "2024-03-15T10:00:00Z",
      "end_time": "2024-03-15T18:00:00Z",
      "city": "Damascus",
      "location": "Grand Hall",
      "categories": [...],
      "organizer": {...}
    }
  ]
}
```

### POST /api/events/{id}/save

Saves an event to user's list.

**Response (201):**
```json
{
  "message": "Event saved."
}
```

### DELETE /api/events/{id}/save

Removes an event from saved list.

**Response (200):**
```json
{
  "message": "Event removed from saved list."
}
```

### POST /api/profile/notifications

Updates notification preference.

**Request Body:**
```json
{
  "enabled": true
}
```

**Response:**
```json
{
  "message": "Notification preference updated.",
  "notifications_enabled": true
}
```

### DELETE /api/profile

Deletes user account (irreversible).

**Response:**
```json
{
  "message": "Account deleted successfully."
}
```

---

## State Management

The app uses **Provider** with `ChangeNotifier` for state management.

### ProfileProvider

Located at `lib/providers/profile_provider.dart`

```dart
// Reading profile data
final profile = context.watch<ProfileProvider>().profile;

// Calling methods
final provider = context.read<ProfileProvider>();
await provider.fetchProfile();

// Updating profile
final result = await provider.updateProfile(
  name: 'New Name',
  phone: '+963912345678',
  location: 'Damascus',
  pictureBase64: 'data:image/jpeg;base64,...',
);

if (result.success) {
  // Show success message
} else {
  // Show error: result.message
}
```

### Available States

```dart
enum ProfileState {
  initial,   // No data loaded
  loading,   // Fetching data
  loaded,    // Data available
  error,     // Error occurred
}
```

### Key Methods

| Method | Description |
|--------|-------------|
| `fetchProfile()` | Loads user profile from API |
| `updateProfile(...)` | Updates profile fields |
| `changePassword(...)` | Changes user password |
| `fetchSavedEvents()` | Loads saved events |
| `saveEvent(id)` | Saves an event |
| `unsaveEvent(id)` | Removes saved event |
| `updateNotifications(bool)` | Toggles notifications |
| `deleteAccount()` | Deletes user account |
| `logout()` | Clears local data and token |

---

## Screens

### ProfileScreen

Main profile view displaying:
- Profile picture with edit button
- User name and email
- Verification badge
- Account type badge (organizer/admin)
- Stats (events, tickets, saved)
- Navigation menu items
- Notification toggle
- Logout button

### EditProfileScreen

Edit form with:
- Profile picture picker (camera/gallery)
- Name field
- Email field (read-only)
- Phone field
- Location dropdown (Syrian cities)
- Delete account option

### ChangePasswordScreen

Password change form with:
- Current password field
- New password field with strength indicator
- Confirm password field
- Password requirements checklist
- Show/hide password toggles

### SavedEventsScreen

List of saved events with:
- Pull to refresh
- Swipe to remove
- Empty state handling
- Navigate to event details

### SettingsScreen

App settings including:
- Dark mode toggle (local)
- Language selection
- Push notifications toggle (API)
- Email notifications toggle (local)
- Change password navigation
- Privacy policy
- Terms of service
- Clear cache

---

## Running the App

### Prerequisites

1. Flutter SDK (3.9.2 or higher)
2. Running Laravel backend at configured URL
3. Valid test user account

### Steps

1. **Install dependencies:**
   ```bash
   cd juniorproject
   flutter pub get
   ```

2. **Configure API URL:**
   Edit `lib/config.dart` with your backend URL.

3. **Set auth token (for testing):**
   After login, the token should be set via `AuthHelper.setToken(token)`.

   For quick testing without full auth flow:
   ```dart
   // In your test/debug setup
   AuthHelper.setToken('your-valid-jwt-token');
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

### Testing on Different Platforms

| Platform | Base URL |
|----------|----------|
| Android Emulator | `http://10.0.2.2:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Physical Device | `http://<your-lan-ip>:8000` |

---

## Testing

### Manual Test Cases

#### Profile Fetch
1. Ensure valid auth token is set
2. Navigate to Profile tab
3. Verify profile data loads
4. Verify stats display correctly

#### Profile Update
1. Tap "Edit Profile"
2. Modify name and phone
3. Tap "Save"
4. Verify success message
5. Verify profile reflects changes

#### Change Password
1. Navigate to Settings > Change Password
2. Enter current password
3. Enter new password (8+ chars)
4. Confirm new password
5. Tap "Change Password"
6. Verify success message

#### Saved Events
1. Navigate to "Saved Events"
2. Verify events load
3. Swipe to remove an event
4. Verify removal confirmation
5. Verify event removed from list

#### Network Error Handling
1. Disable network connection
2. Attempt to load profile
3. Verify error message displays
4. Tap "Try Again"
5. Re-enable network
6. Verify data loads

### API Testing with cURL

```bash
# Get Profile
curl -X GET http://192.168.1.13:8000/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"

# Update Profile
curl -X PUT http://192.168.1.13:8000/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"name": "New Name", "phone": "+963123456789"}'

# Change Password
curl -X POST http://192.168.1.13:8000/api/profile/change-password \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"current_password": "old123", "new_password": "new12345", "new_password_confirmation": "new12345"}'

# Toggle Notifications
curl -X POST http://192.168.1.13:8000/api/profile/notifications \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'

# Get Saved Events
curl -X GET http://192.168.1.13:8000/api/profile/saved-events \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"

# Save Event
curl -X POST http://192.168.1.13:8000/api/events/1/save \
  -H "Authorization: Bearer YOUR_TOKEN"

# Unsave Event
curl -X DELETE http://192.168.1.13:8000/api/events/1/save \
  -H "Authorization: Bearer YOUR_TOKEN"

# Delete Account
curl -X DELETE http://192.168.1.13:8000/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Error Handling

The app implements comprehensive error handling:

### Network Errors
- Displays "No internet connection" message
- Provides retry button
- Preserves cached data when available

### Authentication Errors (401)
- Clears invalid token
- Displays "Session expired" message
- Prompts user to log in again

### Validation Errors (422)
- Extracts specific field errors
- Displays human-readable messages
- Highlights invalid form fields

### UI Components

```dart
// Full-page error with retry
ErrorRetryWidget(
  message: 'Failed to load data',
  onRetry: () => loadData(),
);

// Inline error
InlineErrorWidget(
  message: 'Failed to save',
  onRetry: () => retry(),
);

// Network-specific error
NetworkErrorWidget(
  onRetry: () => retry(),
);

// Session expired
SessionExpiredWidget(
  onLogin: () => navigateToLogin(),
);
```

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2           # State management
  http: ^1.2.0               # HTTP requests
  image_picker: ^1.1.2       # Camera/gallery picker
  cached_network_image: ^3.3.1  # Image caching
  google_fonts: ^6.2.1       # Typography
  shimmer: ^3.0.0            # Loading skeletons
```

---

## Future Improvements

1. **Persistent Token Storage**: Implement `flutter_secure_storage` for secure token persistence
2. **Offline Support**: Cache profile data locally for offline viewing
3. **Image Compression**: Optimize image uploads before base64 encoding
4. **Biometric Auth**: Add fingerprint/face ID for sensitive operations
5. **Dark Mode**: Complete theme switching implementation

---

## File Structure Summary

| File | Purpose |
|------|---------|
| `lib/config.dart` | App configuration, BASE_URL, AuthHelper |
| `lib/models/user_profile_model.dart` | Profile data models |
| `lib/providers/profile_provider.dart` | Profile state management |
| `lib/services/api_client.dart` | API client with all endpoints |
| `lib/screens/profile/profile_screen.dart` | Main profile UI |
| `lib/screens/profile/edit_profile_screen.dart` | Edit profile form |
| `lib/screens/profile/change_password_screen.dart` | Password change |
| `lib/screens/profile/saved_events_screen.dart` | Saved events list |
| `lib/screens/profile/settings_screen.dart` | App settings |
| `lib/widgets/error_retry_widget.dart` | Error handling widgets |
