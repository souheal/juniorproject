import '../config.dart';

/// User profile data model matching the API response from GET /api/profile
///
/// Example API Response:
/// ```json
/// {
///   "user": {
///     "id": 1,
///     "name": "John Doe",س
///     "email": "john@example.com",
///     "phone": "+1234567890",
///     "location": "Damascus",
///     "picture": "http://192.168.1.13:8000/storage/users/abc123.jpg",
///     "email_verified": true,
///     "notifications_enabled": true,
///     "account_type": "user"
///   },
///   "stats": {
///     "events": 12,
///     "tickets": 8,
///     "saved": 5
///   },
///   "account_type": {
///     "current_type": "user",
///     "latest_request_status": null,
///     "can_apply_for_organizer": true
///   }
/// }
/// ```
class UserProfileModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? location;
  final String? picture;
  final bool emailVerified;
  final bool notificationsEnabled;
  final String accountType;
  final ProfileStats stats;
  final AccountTypeInfo accountTypeInfo;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.location,
    this.picture,
    required this.emailVerified,
    required this.notificationsEnabled,
    required this.accountType,
    required this.stats,
    required this.accountTypeInfo,
  });

  /// Full URL for profile picture
  /// Returns null if no picture is set
  String? get pictureUrl {
    if (picture == null || picture!.isEmpty) return null;
    // If picture already contains full URL, return as-is
    if (picture!.startsWith('http')) return picture;
    // Otherwise, construct full URL
    return '${AppConfig.storageUrl}/$picture';
  }

  /// Check if user has a profile picture
  bool get hasPicture => picture != null && picture!.isNotEmpty;

  /// Check if user is verified (email verified)
  bool get isVerified => emailVerified;

  /// Check if user is an organizer
  bool get isOrganizer => accountType == 'organizer';

  /// Check if user is an admin
  bool get isAdmin => accountType == 'admin';

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;
    final statsData = json['stats'] as Map<String, dynamic>;
    final accountTypeData = json['account_type'] as Map<String, dynamic>;

    return UserProfileModel(
      id: userData['id'] as int,
      name: userData['name'] as String,
      email: userData['email'] as String,
      phone: userData['phone'] as String?,
      location: userData['location'] as String?,
      picture: userData['picture'] as String?,
      emailVerified: userData['email_verified'] as bool? ?? false,
      notificationsEnabled: userData['notifications_enabled'] as bool? ?? true,
      accountType: userData['account_type'] as String? ?? 'user',
      stats: ProfileStats.fromJson(statsData),
      accountTypeInfo: AccountTypeInfo.fromJson(accountTypeData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'picture': picture,
        'email_verified': emailVerified,
        'notifications_enabled': notificationsEnabled,
        'account_type': accountType,
      },
      'stats': stats.toJson(),
      'account_type': accountTypeInfo.toJson(),
    };
  }

  /// Create a copy with updated fields
  UserProfileModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? location,
    String? picture,
    bool? emailVerified,
    bool? notificationsEnabled,
    String? accountType,
    ProfileStats? stats,
    AccountTypeInfo? accountTypeInfo,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      picture: picture ?? this.picture,
      emailVerified: emailVerified ?? this.emailVerified,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      accountType: accountType ?? this.accountType,
      stats: stats ?? this.stats,
      accountTypeInfo: accountTypeInfo ?? this.accountTypeInfo,
    );
  }
}

/// Profile statistics (events attended, tickets, saved events)
class ProfileStats {
  final int events;
  final int tickets;
  final int saved;

  ProfileStats({
    required this.events,
    required this.tickets,
    required this.saved,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      events: json['events'] as int? ?? 0,
      tickets: json['tickets'] as int? ?? 0,
      saved: json['saved'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'events': events,
      'tickets': tickets,
      'saved': saved,
    };
  }
}

/// Account type information (organizer status, application eligibility)
class AccountTypeInfo {
  final String currentType;
  final String? latestRequestStatus;
  final bool canApplyForOrganizer;

  AccountTypeInfo({
    required this.currentType,
    this.latestRequestStatus,
    required this.canApplyForOrganizer,
  });

  /// Check if there's a pending organizer request
  bool get hasPendingRequest => latestRequestStatus == 'pending';

  /// Check if the organizer request was rejected
  bool get wasRejected => latestRequestStatus == 'rejected';

  /// Check if the organizer request was approved
  bool get wasApproved => latestRequestStatus == 'approved';

  factory AccountTypeInfo.fromJson(Map<String, dynamic> json) {
    return AccountTypeInfo(
      currentType: json['current_type'] as String? ?? 'user',
      latestRequestStatus: json['latest_request_status'] as String?,
      canApplyForOrganizer: json['can_apply_for_organizer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_type': currentType,
      'latest_request_status': latestRequestStatus,
      'can_apply_for_organizer': canApplyForOrganizer,
    };
  }
}

/// Model for profile update request (PUT /api/profile)
class ProfileUpdateRequest {
  final String? name;
  final String? phone;
  final String? location;
  final String? pictureBase64;

  ProfileUpdateRequest({
    this.name,
    this.phone,
    this.location,
    this.pictureBase64,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    if (location != null) map['location'] = location;
    if (pictureBase64 != null) map['picture'] = pictureBase64;
    return map;
  }
}

/// Model for password change request (POST /api/profile/change-password)
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    };
  }
}

/// Model for user's ticket with event details (GET /api/profile/tickets)
class UserTicketModel {
  final int id;
  final int eventId;
  final int userId;
  final String? createdAt;
  final TicketEventModel? event;

  UserTicketModel({
    required this.id,
    required this.eventId,
    required this.userId,
    this.createdAt,
    this.event,
  });

  factory UserTicketModel.fromJson(Map<String, dynamic> json) {
    return UserTicketModel(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      userId: json['user_id'] as int,
      createdAt: json['created_at'] as String?,
      event: json['event'] != null
          ? TicketEventModel.fromJson(json['event'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'created_at': createdAt,
      'event': event?.toJson(),
    };
  }
}

/// Simplified event model for tickets
class TicketEventModel {
  final int id;
  final String name;
  final String? description;
  final String? picture;
  final String? startTime;
  final String? endTime;
  final String? city;
  final String? location;

  TicketEventModel({
    required this.id,
    required this.name,
    this.description,
    this.picture,
    this.startTime,
    this.endTime,
    this.city,
    this.location,
  });

  String? get pictureUrl {
    if (picture == null || picture!.isEmpty) return null;
    if (picture!.startsWith('http')) return picture;
    return '${AppConfig.storageUrl}/$picture';
  }

  factory TicketEventModel.fromJson(Map<String, dynamic> json) {
    return TicketEventModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      picture: json['picture'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      city: json['city'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'picture': picture,
      'start_time': startTime,
      'end_time': endTime,
      'city': city,
      'location': location,
    };
  }
}
