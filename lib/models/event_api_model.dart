/// Model for events from the Laravel API browse() endpoint.
class EventApiModel {
  final int id;
  final String name;
  final String? description;
  final String? picture;
  final DateTime startTime;
  final DateTime endTime;
  final String city;
  final String location;
  final double price;
  final int? capacity;
  final String? onlineLink;
  final String? status;
  final OrganizerModel organizer;
  final List<CategoryModel> categories;
  final bool? isLive;
  final String? fullLocation;

  // Additional fields that might be added by backend in future
  final double? ticketPrice;
  final int? maxVolunteers;
  final int? currentVolunteers;
  final String? venue;

  EventApiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.picture,
    required this.startTime,
    required this.endTime,
    required this.city,
    required this.location,
    required this.price,
    required this.capacity,
    required this.onlineLink,
    required this.status,
    required this.organizer,
    required this.categories,
    this.isLive,
    this.fullLocation,
    this.ticketPrice,
    this.maxVolunteers,
    this.currentVolunteers,
    this.venue,
  });

  factory EventApiModel.fromJson(Map<String, dynamic> json) {
    // Parse organizer - handle both object and null
    OrganizerModel organizer;
    if (json['organizer'] != null && json['organizer'] is Map<String, dynamic>) {
      organizer = OrganizerModel.fromJson(json['organizer'] as Map<String, dynamic>);
    } else {
      // Default organizer if not provided
      organizer = OrganizerModel(id: 0, name: 'Unknown', email: '');
    }

    // Parse categories - handle both list and null
    List<CategoryModel> categories = [];
    if (json['categories'] != null && json['categories'] is List) {
      categories = (json['categories'] as List<dynamic>)
          .map((cat) => CategoryModel.fromJson(cat as Map<String, dynamic>))
          .toList();
    }

    // Parse dates - handle null with default values
    DateTime startTime;
    DateTime endTime;
    try {
      startTime = json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now();
      endTime = json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : DateTime.now().add(const Duration(hours: 2));
    } catch (e) {
      startTime = DateTime.now();
      endTime = DateTime.now().add(const Duration(hours: 2));
    }

    return EventApiModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Untitled Event',
      description: json['description'] as String?,
      picture: json['picture'] as String?,
      startTime: startTime,
      endTime: endTime,
      city: json['city'] as String? ?? '',
      location: json['location'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      capacity: json['capacity'] as int?,
      onlineLink: json['online_link'] as String?,
      status: json['status'] as String?,
      organizer: organizer,
      categories: categories,
      isLive: json['is_live'] as bool?,
      fullLocation: json['full_location'] as String?,
      // Optional future fields
      ticketPrice: (json['ticket_price'] as num?)?.toDouble(),
      maxVolunteers: json['max_volunteers'] as int?,
      currentVolunteers: json['current_volunteers'] as int?,
      venue: json['venue'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'picture': picture,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'city': city,
      'location': location,
      'price': price,
      'capacity': capacity,
      'online_link': onlineLink,
      'status': status,
      'organizer': organizer.toJson(),
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'is_live': isLive,
      'full_location': fullLocation,
      'ticket_price': ticketPrice,
      'max_volunteers': maxVolunteers,
      'current_volunteers': currentVolunteers,
      'venue': venue,
    };
  }

  /// Get the first category name or 'Uncategorized'
  String get primaryCategory {
    return categories.isNotEmpty ? categories.first.name : 'Uncategorized';
  }

  /// Check if event is currently live (use backend value if available)
  bool get isEventLive {
    if (isLive != null) return isLive!;
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Get venue display (priority: venue field > full_location > location)
  String get venueDisplay {
    return venue ?? fullLocation ?? location;
  }

  /// Get formatted date string
  String get formattedDate {
    return '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted time range string
  String get formattedTime {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  /// Get full image URL or null
  String? get fullImageUrl {
    if (picture == null || picture!.isEmpty) return null;
    // Assuming Laravel storage URL structure
    return 'http://192.168.1.12:8000/storage/$picture';
  }

  /// Get ticket price (priority: ticketPrice field > price field)
  double get displayPrice => ticketPrice ?? price;
}

/// Model for event organizer
class OrganizerModel {
  final int id;
  final String name;
  final String email;

  OrganizerModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory OrganizerModel.fromJson(Map<String, dynamic> json) {
    return OrganizerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

/// Model for event categories
class CategoryModel {
  final int id;
  final String name;

  CategoryModel({
    required this.id,
    required this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => name;
}
