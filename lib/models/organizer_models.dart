// Organizer-related models for frontend-only implementation.
// These models use local storage (SharedPreferences/localStorage) only.
// TODO: Replace with backend API integration when available.

/// Organizer approval status enum
enum OrganizerApprovalStatus {
  none,
  pending,
  approved,
  rejected;

  static OrganizerApprovalStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return OrganizerApprovalStatus.pending;
      case 'approved':
        return OrganizerApprovalStatus.approved;
      case 'rejected':
        return OrganizerApprovalStatus.rejected;
      default:
        return OrganizerApprovalStatus.none;
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }
}

/// Organizer request model
class OrganizerRequest {
  final String id;
  final String organizationName;
  final String description;
  final List<String> documentPaths; // Local file paths (mock)
  final DateTime createdAt;
  final OrganizerApprovalStatus status;

  OrganizerRequest({
    required this.id,
    required this.organizationName,
    required this.description,
    this.documentPaths = const [],
    required this.createdAt,
    this.status = OrganizerApprovalStatus.pending,
  });

  factory OrganizerRequest.fromJson(Map<String, dynamic> json) {
    return OrganizerRequest(
      id: json['id'] as String,
      organizationName: json['organizationName'] as String,
      description: json['description'] as String,
      documentPaths: List<String>.from(json['documentPaths'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OrganizerApprovalStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationName': organizationName,
      'description': description,
      'documentPaths': documentPaths,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toShortString(),
    };
  }

  OrganizerRequest copyWith({
    String? id,
    String? organizationName,
    String? description,
    List<String>? documentPaths,
    DateTime? createdAt,
    OrganizerApprovalStatus? status,
  }) {
    return OrganizerRequest(
      id: id ?? this.id,
      organizationName: organizationName ?? this.organizationName,
      description: description ?? this.description,
      documentPaths: documentPaths ?? this.documentPaths,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

/// Organizer profile (separate from user profile)
class OrganizerProfile {
  final String id;
  final String organizerName;
  final String description;
  final String contactEmail;
  final String? contactPhone;
  final String? website;
  final Map<String, String> socialLinks; // e.g., {'facebook': 'url', 'instagram': 'url'}
  final String? logoPath; // Local path or base64
  final DateTime createdAt;
  final DateTime updatedAt;

  OrganizerProfile({
    required this.id,
    required this.organizerName,
    required this.description,
    required this.contactEmail,
    this.contactPhone,
    this.website,
    this.socialLinks = const {},
    this.logoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizerProfile.fromJson(Map<String, dynamic> json) {
    return OrganizerProfile(
      id: json['id'] as String,
      organizerName: json['organizerName'] as String,
      description: json['description'] as String,
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String?,
      website: json['website'] as String?,
      socialLinks: Map<String, String>.from(json['socialLinks'] ?? {}),
      logoPath: json['logoPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizerName': organizerName,
      'description': description,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website,
      'socialLinks': socialLinks,
      'logoPath': logoPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  OrganizerProfile copyWith({
    String? id,
    String? organizerName,
    String? description,
    String? contactEmail,
    String? contactPhone,
    String? website,
    Map<String, String>? socialLinks,
    String? logoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizerProfile(
      id: id ?? this.id,
      organizerName: organizerName ?? this.organizerName,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      website: website ?? this.website,
      socialLinks: socialLinks ?? this.socialLinks,
      logoPath: logoPath ?? this.logoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Event status enum
enum OrganizerEventStatus {
  draft,
  published,
  finished;

  static OrganizerEventStatus fromString(String? value) {
    switch (value) {
      case 'published':
        return OrganizerEventStatus.published;
      case 'finished':
        return OrganizerEventStatus.finished;
      default:
        return OrganizerEventStatus.draft;
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case OrganizerEventStatus.draft:
        return 'Draft';
      case OrganizerEventStatus.published:
        return 'Published';
      case OrganizerEventStatus.finished:
        return 'Finished';
    }
  }
}

/// Event ticket model
class EventTicket {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final int soldCount;
  final bool isFree;

  EventTicket({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.soldCount = 0,
    required this.isFree,
  });

  int get availableCount => quantity - soldCount;

  factory EventTicket.fromJson(Map<String, dynamic> json) {
    return EventTicket(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      soldCount: json['soldCount'] as int? ?? 0,
      isFree: json['isFree'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'soldCount': soldCount,
      'isFree': isFree,
    };
  }

  EventTicket copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    int? soldCount,
    bool? isFree,
  }) {
    return EventTicket(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      soldCount: soldCount ?? this.soldCount,
      isFree: isFree ?? this.isFree,
    );
  }
}

/// Organizer's event model
class OrganizerEvent {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final String category;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String location;
  final String? city;
  final String? coverImagePath; // Local path or base64
  final List<String> galleryImagePaths;
  final List<EventTicket> tickets;
  final List<VolunteerOpportunity> volunteerOpportunities;
  final OrganizerEventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Mock stats
  final int viewCount;
  final int ticketsSold;

  OrganizerEvent({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.category,
    required this.startDateTime,
    required this.endDateTime,
    required this.location,
    this.city,
    this.coverImagePath,
    this.galleryImagePaths = const [],
    this.tickets = const [],
    this.volunteerOpportunities = const [],
    this.status = OrganizerEventStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.ticketsSold = 0,
  });

  /// Derive status based on date (Finished if event date has passed)
  OrganizerEventStatus get derivedStatus {
    if (status == OrganizerEventStatus.published &&
        DateTime.now().isAfter(endDateTime)) {
      return OrganizerEventStatus.finished;
    }
    return status;
  }

  bool get isUpcoming => startDateTime.isAfter(DateTime.now());
  bool get isOngoing => DateTime.now().isAfter(startDateTime) && DateTime.now().isBefore(endDateTime);
  bool get isPast => DateTime.now().isAfter(endDateTime);

  int get totalTicketCapacity {
    return tickets.fold(0, (sum, ticket) => sum + ticket.quantity);
  }

  int get totalTicketsSold {
    return tickets.fold(0, (sum, ticket) => sum + ticket.soldCount);
  }

  factory OrganizerEvent.fromJson(Map<String, dynamic> json) {
    return OrganizerEvent(
      id: json['id'] as String,
      organizerId: json['organizerId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      location: json['location'] as String,
      city: json['city'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      galleryImagePaths: List<String>.from(json['galleryImagePaths'] ?? []),
      tickets: (json['tickets'] as List<dynamic>?)
              ?.map((t) => EventTicket.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      volunteerOpportunities: (json['volunteerOpportunities'] as List<dynamic>?)
              ?.map((v) => VolunteerOpportunity.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      status: OrganizerEventStatus.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      viewCount: json['viewCount'] as int? ?? 0,
      ticketsSold: json['ticketsSold'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizerId': organizerId,
      'title': title,
      'description': description,
      'category': category,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'location': location,
      'city': city,
      'coverImagePath': coverImagePath,
      'galleryImagePaths': galleryImagePaths,
      'tickets': tickets.map((t) => t.toJson()).toList(),
      'volunteerOpportunities': volunteerOpportunities.map((v) => v.toJson()).toList(),
      'status': status.toShortString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'viewCount': viewCount,
      'ticketsSold': ticketsSold,
    };
  }

  OrganizerEvent copyWith({
    String? id,
    String? organizerId,
    String? title,
    String? description,
    String? category,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? location,
    String? city,
    String? coverImagePath,
    List<String>? galleryImagePaths,
    List<EventTicket>? tickets,
    List<VolunteerOpportunity>? volunteerOpportunities,
    OrganizerEventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    int? ticketsSold,
  }) {
    return OrganizerEvent(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      location: location ?? this.location,
      city: city ?? this.city,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      galleryImagePaths: galleryImagePaths ?? this.galleryImagePaths,
      tickets: tickets ?? this.tickets,
      volunteerOpportunities: volunteerOpportunities ?? this.volunteerOpportunities,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      ticketsSold: ticketsSold ?? this.ticketsSold,
    );
  }
}

/// Volunteer opportunity status enum
enum OpportunityStatus {
  draft,
  published,
  closed;

  static OpportunityStatus fromString(String? value) {
    switch (value) {
      case 'published':
        return OpportunityStatus.published;
      case 'closed':
        return OpportunityStatus.closed;
      default:
        return OpportunityStatus.draft;
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case OpportunityStatus.draft:
        return 'Draft';
      case OpportunityStatus.published:
        return 'Open';
      case OpportunityStatus.closed:
        return 'Closed';
    }
  }
}

/// Volunteer opportunity model (organizer creates these for events)
class OrganizerVolunteerOpportunity {
  final String id;
  final String eventId;
  final String roleName;
  final String? description;
  final int spotsTotal;
  final int spotsFilled;
  final String? duration;
  final String? requirements;
  final String? benefits;
  final OpportunityStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrganizerVolunteerOpportunity({
    required this.id,
    required this.eventId,
    required this.roleName,
    this.description,
    required this.spotsTotal,
    this.spotsFilled = 0,
    this.duration,
    this.requirements,
    this.benefits,
    this.status = OpportunityStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  int get spotsAvailable => spotsTotal - spotsFilled;
  bool get isFull => spotsAvailable <= 0;

  /// Derive status: auto-close when spots reach 0
  OpportunityStatus get derivedStatus {
    if (status == OpportunityStatus.published && isFull) {
      return OpportunityStatus.closed;
    }
    return status;
  }

  factory OrganizerVolunteerOpportunity.fromJson(Map<String, dynamic> json) {
    return OrganizerVolunteerOpportunity(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      roleName: json['roleName'] as String,
      description: json['description'] as String?,
      spotsTotal: json['spotsTotal'] as int,
      spotsFilled: json['spotsFilled'] as int? ?? 0,
      duration: json['duration'] as String?,
      requirements: json['requirements'] as String?,
      benefits: json['benefits'] as String?,
      status: OpportunityStatus.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'roleName': roleName,
      'description': description,
      'spotsTotal': spotsTotal,
      'spotsFilled': spotsFilled,
      'duration': duration,
      'requirements': requirements,
      'benefits': benefits,
      'status': status.toShortString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  OrganizerVolunteerOpportunity copyWith({
    String? id,
    String? eventId,
    String? roleName,
    String? description,
    int? spotsTotal,
    int? spotsFilled,
    String? duration,
    String? requirements,
    String? benefits,
    OpportunityStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizerVolunteerOpportunity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      spotsTotal: spotsTotal ?? this.spotsTotal,
      spotsFilled: spotsFilled ?? this.spotsFilled,
      duration: duration ?? this.duration,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Volunteer application status enum
enum ApplicationStatus {
  pending,
  accepted,
  rejected;

  static ApplicationStatus fromString(String? value) {
    switch (value) {
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Volunteer application model
class VolunteerApplication {
  final String id;
  final String eventId;
  final String opportunityId;
  final String volunteerId;
  final String volunteerName;
  final String? volunteerEmail;
  final String? volunteerPhone;
  final String? message;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  VolunteerApplication({
    required this.id,
    required this.eventId,
    required this.opportunityId,
    required this.volunteerId,
    required this.volunteerName,
    this.volunteerEmail,
    this.volunteerPhone,
    this.message,
    this.status = ApplicationStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VolunteerApplication.fromJson(Map<String, dynamic> json) {
    return VolunteerApplication(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      opportunityId: json['opportunityId'] as String,
      volunteerId: json['volunteerId'] as String,
      volunteerName: json['volunteerName'] as String,
      volunteerEmail: json['volunteerEmail'] as String?,
      volunteerPhone: json['volunteerPhone'] as String?,
      message: json['message'] as String?,
      status: ApplicationStatus.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'opportunityId': opportunityId,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'volunteerEmail': volunteerEmail,
      'volunteerPhone': volunteerPhone,
      'message': message,
      'status': status.toShortString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  VolunteerApplication copyWith({
    String? id,
    String? eventId,
    String? opportunityId,
    String? volunteerId,
    String? volunteerName,
    String? volunteerEmail,
    String? volunteerPhone,
    String? message,
    ApplicationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VolunteerApplication(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      opportunityId: opportunityId ?? this.opportunityId,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      volunteerEmail: volunteerEmail ?? this.volunteerEmail,
      volunteerPhone: volunteerPhone ?? this.volunteerPhone,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Simple volunteer opportunity for event creation flow
class VolunteerOpportunity {
  final String id;
  final String roleName;
  final int capacity;
  final String? duration;
  final String? requirements;
  final String? benefits;
  final OpportunityStatus status;

  VolunteerOpportunity({
    required this.id,
    required this.roleName,
    required this.capacity,
    this.duration,
    this.requirements,
    this.benefits,
    this.status = OpportunityStatus.draft,
  });

  int get spotsLeft => capacity; // Initial spots = capacity

  factory VolunteerOpportunity.fromJson(Map<String, dynamic> json) {
    return VolunteerOpportunity(
      id: json['id'] as String,
      roleName: json['roleName'] as String,
      capacity: json['capacity'] as int,
      duration: json['duration'] as String?,
      requirements: json['requirements'] as String?,
      benefits: json['benefits'] as String?,
      status: OpportunityStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleName': roleName,
      'capacity': capacity,
      'duration': duration,
      'requirements': requirements,
      'benefits': benefits,
      'status': status.toShortString(),
    };
  }

  VolunteerOpportunity copyWith({
    String? id,
    String? roleName,
    int? capacity,
    String? duration,
    String? requirements,
    String? benefits,
    OpportunityStatus? status,
  }) {
    return VolunteerOpportunity(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      capacity: capacity ?? this.capacity,
      duration: duration ?? this.duration,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      status: status ?? this.status,
    );
  }
}

/// Event categories for dropdown
class EventCategories {
  static const List<String> all = [
    'Music',
    'Technology',
    'Sports',
    'Art',
    'Food & Drink',
    'Business',
    'Education',
    'Health & Wellness',
    'Community',
    'Entertainment',
    'Charity',
    'Other',
  ];
}
