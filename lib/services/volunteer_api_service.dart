import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class VolunteerApiService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  /// GET /api/volunteer/opportunities
  /// Returns list of volunteer opportunities (public)
  static Future<List<VolunteerOpportunityDto>> getOpportunities() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteer/opportunities'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VolunteerOpportunityDto.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load volunteer opportunities');
      }
    } catch (e) {
      throw Exception('Error fetching opportunities: $e');
    }
  }

  /// GET /api/volunteer/opportunities/{eventId}
  /// Returns event details with all volunteer roles
  static Future<EventVolunteerDetailsDto> getEventDetails(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteer/opportunities/$eventId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EventVolunteerDetailsDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Event not found');
      } else {
        throw Exception('Failed to load event details');
      }
    } catch (e) {
      throw Exception('Error fetching event details: $e');
    }
  }

  /// GET /api/volunteer/opportunities/{eventId}/roles/{type}
  /// Returns detailed info about a specific role
  static Future<RoleDetailsDto> getRoleDetails(int eventId, String roleType) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteer/opportunities/$eventId/roles/$roleType'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RoleDetailsDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Event not found');
      } else if (response.statusCode == 422) {
        throw Exception('Invalid volunteer role type');
      } else {
        throw Exception('Failed to load role details');
      }
    } catch (e) {
      throw Exception('Error fetching role details: $e');
    }
  }

  /// POST /api/events/{eventId}/volunteer-requests
  /// User applies as volunteer (requires authentication)
  static Future<VolunteerRequestResponse> applyAsVolunteer({
    required int eventId,
    required String volunteerType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/events/$eventId/volunteer-requests'),
        headers: AuthHelper.headers,
        body: json.encode({'volunteer_type': volunteerType}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return VolunteerRequestResponse(
          success: true,
          message: data['message'] ?? 'Request submitted successfully',
        );
      } else if (response.statusCode == 422) {
        return VolunteerRequestResponse(
          success: false,
          message: data['message'] ?? 'Unable to submit request',
        );
      } else if (response.statusCode == 403) {
        return VolunteerRequestResponse(
          success: false,
          message: data['message'] ?? 'Only users can submit volunteer requests',
        );
      } else {
        return VolunteerRequestResponse(
          success: false,
          message: data['message'] ?? 'Something went wrong',
        );
      }
    } catch (e) {
      return VolunteerRequestResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// GET /api/volunteer-requests/me
  /// Returns user's volunteer requests (requires authentication)
  static Future<List<MyVolunteerRequestDto>> getMyRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteer-requests/me'),
        headers: AuthHelper.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MyVolunteerRequestDto.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load your requests');
      }
    } catch (e) {
      throw Exception('Error fetching your requests: $e');
    }
  }
}

// ============ DTOs ============

/// DTO for volunteer opportunity card (list view)
class VolunteerOpportunityDto {
  final EventBasicDto event;
  final RoleBasicDto role;
  final int spotsLeft;

  VolunteerOpportunityDto({
    required this.event,
    required this.role,
    required this.spotsLeft,
  });

  factory VolunteerOpportunityDto.fromJson(Map<String, dynamic> json) {
    return VolunteerOpportunityDto(
      event: EventBasicDto.fromJson(json['event']),
      role: RoleBasicDto.fromJson(json['role']),
      spotsLeft: json['spots_left'] ?? 0,
    );
  }

  bool get isUrgent => spotsLeft <= 3;
}

class EventBasicDto {
  final int id;
  final String name;
  final String? date;
  final String? time;
  final int? durationHours;
  final String? venue;
  final String? location;
  final String? city;
  final String? picture;

  EventBasicDto({
    required this.id,
    required this.name,
    this.date,
    this.time,
    this.durationHours,
    this.venue,
    this.location,
    this.city,
    this.picture,
  });

  factory EventBasicDto.fromJson(Map<String, dynamic> json) {
    return EventBasicDto(
      id: json['id'],
      name: json['name'] ?? '',
      date: json['date'],
      time: json['time'],
      durationHours: json['duration_hours'],
      venue: json['venue'],
      location: json['location'],
      city: json['city'],
      picture: json['picture'],
    );
  }

  String get imageUrl {
    if (picture != null && picture!.isNotEmpty) {
      if (picture!.startsWith('http')) return picture!;
      return '${AppConfig.storageUrl}/$picture';
    }
    return '';
  }
}

class RoleBasicDto {
  final String type;
  final String title;

  RoleBasicDto({
    required this.type,
    required this.title,
  });

  factory RoleBasicDto.fromJson(Map<String, dynamic> json) {
    return RoleBasicDto(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
    );
  }
}

/// DTO for event volunteer details (with all roles)
class EventVolunteerDetailsDto {
  final EventDetailDto event;
  final List<RoleWithSpotsDto> roles;

  EventVolunteerDetailsDto({
    required this.event,
    required this.roles,
  });

  factory EventVolunteerDetailsDto.fromJson(Map<String, dynamic> json) {
    return EventVolunteerDetailsDto(
      event: EventDetailDto.fromJson(json['event']),
      roles: (json['roles'] as List<dynamic>)
          .map((r) => RoleWithSpotsDto.fromJson(r))
          .toList(),
    );
  }
}

class EventDetailDto {
  final int id;
  final String name;
  final String? description;
  final String? date;
  final String? startTime;
  final String? endTime;
  final int? durationHours;
  final String? venue;
  final String? location;
  final String? picture;

  EventDetailDto({
    required this.id,
    required this.name,
    this.description,
    this.date,
    this.startTime,
    this.endTime,
    this.durationHours,
    this.venue,
    this.location,
    this.picture,
  });

  factory EventDetailDto.fromJson(Map<String, dynamic> json) {
    return EventDetailDto(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      durationHours: json['duration_hours'],
      venue: json['venue'],
      location: json['location'],
      picture: json['picture'],
    );
  }

  String get imageUrl {
    if (picture != null && picture!.isNotEmpty) {
      if (picture!.startsWith('http')) return picture!;
      return '${AppConfig.storageUrl}/$picture';
    }
    return '';
  }
}

class RoleWithSpotsDto {
  final String type;
  final String title;
  final int spotsLeft;

  RoleWithSpotsDto({
    required this.type,
    required this.title,
    required this.spotsLeft,
  });

  factory RoleWithSpotsDto.fromJson(Map<String, dynamic> json) {
    return RoleWithSpotsDto(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      spotsLeft: json['spots_left'] ?? 0,
    );
  }
}

/// DTO for role details (with requirements and benefits)
class RoleDetailsDto {
  final EventBasicDto event;
  final RoleFullDto role;

  RoleDetailsDto({
    required this.event,
    required this.role,
  });

  factory RoleDetailsDto.fromJson(Map<String, dynamic> json) {
    return RoleDetailsDto(
      event: EventBasicDto.fromJson(json['event']),
      role: RoleFullDto.fromJson(json['role']),
    );
  }
}

class RoleFullDto {
  final String type;
  final String title;
  final String description;
  final List<String> requirements;
  final List<String> benefits;
  final int limit;
  final int spotsLeft;

  RoleFullDto({
    required this.type,
    required this.title,
    required this.description,
    required this.requirements,
    required this.benefits,
    required this.limit,
    required this.spotsLeft,
  });

  factory RoleFullDto.fromJson(Map<String, dynamic> json) {
    return RoleFullDto(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirements: List<String>.from(json['requirements'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      limit: json['limit'] ?? 0,
      spotsLeft: json['spots_left'] ?? 0,
    );
  }

  bool get isUrgent => spotsLeft <= 3;
}

/// Response for volunteer application
class VolunteerRequestResponse {
  final bool success;
  final String message;

  VolunteerRequestResponse({
    required this.success,
    required this.message,
  });
}

/// DTO for user's volunteer requests
class MyVolunteerRequestDto {
  final int id;
  final int eventId;
  final int userId;
  final String volunteerType;
  final String status;
  final String? reward;
  final String createdAt;
  final MyRequestEventDto? event;

  MyVolunteerRequestDto({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.volunteerType,
    required this.status,
    this.reward,
    required this.createdAt,
    this.event,
  });

  factory MyVolunteerRequestDto.fromJson(Map<String, dynamic> json) {
    return MyVolunteerRequestDto(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      volunteerType: json['volunteer_type'] ?? '',
      status: json['status'] ?? 'pending',
      reward: json['reward'],
      createdAt: json['created_at'] ?? '',
      event: json['event'] != null ? MyRequestEventDto.fromJson(json['event']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

class MyRequestEventDto {
  final int id;
  final String name;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? venue;

  MyRequestEventDto({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    this.location,
    this.venue,
  });

  factory MyRequestEventDto.fromJson(Map<String, dynamic> json) {
    return MyRequestEventDto(
      id: json['id'],
      name: json['name'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      location: json['location'],
      venue: json['venue'],
    );
  }
}
