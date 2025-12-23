import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/organizer_storage_service.dart';
import '../../models/organizer_models.dart';

class CreateEventScreen extends StatefulWidget {
  final OrganizerEvent? eventToEdit;

  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  // Syrian cities list (same as signup)
  static const List<String> _syrianCities = [
    'Damascus',
    'Aleppo',
    'Homs',
    'Hama',
    'Latakia',
    'Tartus',
    'Deir ez-Zor',
    'Raqqa',
    'Hasakah',
    'Daraa',
    'As-Suwayda',
    'Idlib',
    'Qamishli',
    'Palmyra',
  ];

  // Step 1: Event Info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = EventCategories.all.first;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  final _locationController = TextEditingController();
  String? _selectedCity;

  // Step 2: Media
  String? _coverImageBase64;
  List<String> _galleryImagesBase64 = [];

  // Step 3: Tickets
  List<EventTicket> _tickets = [];

  // Step 4: Volunteer Opportunities
  List<VolunteerOpportunity> _volunteerOpportunities = [];

  bool _isSubmitting = false;
  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadEventData();
    }
  }

  void _loadEventData() {
    final event = widget.eventToEdit!;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _selectedCategory = event.category;
    _startDate = event.startDateTime;
    _startTime = TimeOfDay.fromDateTime(event.startDateTime);
    _endDate = event.endDateTime;
    _endTime = TimeOfDay.fromDateTime(event.endDateTime);
    _locationController.text = event.location;
    _selectedCity = event.city;
    _coverImageBase64 = event.coverImagePath;
    _galleryImagesBase64 = List.from(event.galleryImagePaths);
    _tickets = List.from(event.tickets);
    _volunteerOpportunities = List.from(event.volunteerOpportunities);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_formKeys[_currentStep].currentState?.validate() ?? true) {
        setState(() => _currentStep++);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickImage({bool isGallery = false}) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64 = base64Encode(bytes);

      setState(() {
        if (isGallery) {
          if (_galleryImagesBase64.length < 5) {
            _galleryImagesBase64.add(base64);
          }
        } else {
          _coverImageBase64 = base64;
        }
      });
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImagesBase64.removeAt(index);
    });
  }

  void _addTicket() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTicketModal(
        onAdd: (ticket) {
          setState(() {
            _tickets.add(ticket);
          });
        },
      ),
    );
  }

  void _removeTicket(int index) {
    setState(() {
      _tickets.removeAt(index);
    });
  }

  Future<void> _publishEvent() async {
    if (!_formKeys[0].currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // When publishing, set all volunteer opportunities status to published
      final publishedOpportunities = _volunteerOpportunities.map((opp) {
        return opp.copyWith(status: OpportunityStatus.published);
      }).toList();

      final event = OrganizerEvent(
        id: _isEditing
            ? widget.eventToEdit!.id
            : OrganizerStorageService.generateId('evt'),
        organizerId: 'current_organizer', // TODO: Get from auth
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: _locationController.text.trim(),
        city: _selectedCity,
        coverImagePath: _coverImageBase64,
        galleryImagePaths: _galleryImagesBase64,
        tickets: _tickets,
        volunteerOpportunities: publishedOpportunities,
        status: OrganizerEventStatus.published,
        createdAt: _isEditing ? widget.eventToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await OrganizerStorageService.saveEvent(event);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(_isEditing ? 'Event updated!' : 'Event published!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isSubmitting = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final event = OrganizerEvent(
        id: _isEditing
            ? widget.eventToEdit!.id
            : OrganizerStorageService.generateId('evt'),
        organizerId: 'current_organizer',
        title: _titleController.text.trim().isEmpty
            ? 'Untitled Event'
            : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: _locationController.text.trim(),
        city: _selectedCity,
        coverImagePath: _coverImageBase64,
        galleryImagePaths: _galleryImagesBase64,
        tickets: _tickets,
        volunteerOpportunities: _volunteerOpportunities, // Keep as draft
        status: OrganizerEventStatus.draft,
        createdAt: _isEditing ? widget.eventToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await OrganizerStorageService.saveEvent(event);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.save, color: Colors.white),
                SizedBox(width: 12),
                Text('Draft saved!'),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveDraft,
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppTheme.primaryColor
                              : AppTheme.textLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < _totalSteps - 1) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepTitle(_currentStep),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Event Info';
      case 1:
        return 'Media';
      case 2:
        return 'Tickets';
      case 3:
        return 'Volunteers';
      case 4:
        return 'Review & Publish';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEventInfoStep();
      case 1:
        return _buildMediaStep();
      case 2:
        return _buildTicketsStep();
      case 3:
        return _buildVolunteersStep();
      case 4:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildEventInfoStep() {
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Event Title', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _buildInputDecoration('Enter event title'),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            _buildLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: _buildInputDecoration('Describe your event'),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            _buildLabel('Category', required: true),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: _buildInputDecoration('Select category'),
              items: EventCategories.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 20),
            _buildLabel('Date & Time', required: true),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'Start',
                    date: _startDate,
                    time: _startTime,
                    onDateChanged: (d) => setState(() => _startDate = d),
                    onTimeChanged: (t) => setState(() => _startTime = t),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'End',
                    date: _endDate,
                    time: _endTime,
                    onDateChanged: (d) => setState(() => _endDate = d),
                    onTimeChanged: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel('Location', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: _buildInputDecoration('Event venue or address'),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Location is required' : null,
            ),
            const SizedBox(height: 20),
            _buildLabel('City'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              decoration: _buildInputDecoration('Select city'),
              items: _syrianCities
                  .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCity = value),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required Function(DateTime) onDateChanged,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) onTimeChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Cover Image'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImage(isGallery: false),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                  width: 2,
                  style: _coverImageBase64 == null
                      ? BorderStyle.none
                      : BorderStyle.solid,
                ),
                image: _coverImageBase64 != null
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(_coverImageBase64!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _coverImageBase64 == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppTheme.primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to add cover image',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _coverImageBase64 = null),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('Gallery Images'),
          Text(
            'Up to 5 images',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._galleryImagesBase64.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(entry.value)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeGalleryImage(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (_galleryImagesBase64.length < 5)
                  GestureDetector(
                    onTap: () => _pickImage(isGallery: true),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTicketsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('Ticket Types'),
              TextButton.icon(
                onPressed: _addTicket,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Ticket'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tickets.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 48,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No tickets added yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add tickets for your event',
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_tickets.length, (index) {
              final ticket = _tickets[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ticket.isFree
                            ? AppTheme.successColor.withValues(alpha: 0.1)
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.confirmation_number_rounded,
                        color: ticket.isFree
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.isFree
                                ? 'Free - ${ticket.quantity} available'
                                : '\$${ticket.price.toStringAsFixed(2)} - ${ticket.quantity} available',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeTicket(index),
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.errorColor,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _addVolunteerOpportunity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddVolunteerModal(
        onAdd: (opportunity) {
          setState(() {
            _volunteerOpportunities.add(opportunity);
          });
        },
      ),
    );
  }

  void _editVolunteerOpportunity(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddVolunteerModal(
        existingOpportunity: _volunteerOpportunities[index],
        onAdd: (opportunity) {
          setState(() {
            _volunteerOpportunities[index] = opportunity;
          });
        },
      ),
    );
  }

  void _removeVolunteerOpportunity(int index) {
    setState(() {
      _volunteerOpportunities.removeAt(index);
    });
  }

  Widget _buildVolunteersStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Volunteer Roles'),
                  const SizedBox(height: 4),
                  Text(
                    'Optional - Add roles for volunteers',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addVolunteerOpportunity,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Role'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_volunteerOpportunities.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    size: 48,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No volunteer roles added',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add roles to recruit volunteers for your event',
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...List.generate(_volunteerOpportunities.length, (index) {
              final opportunity = _volunteerOpportunities[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_rounded,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opportunity.roleName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${opportunity.capacity} spots available',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editVolunteerOpportunity(index),
                          icon: const Icon(Icons.edit_outlined),
                          color: AppTheme.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: () => _removeVolunteerOpportunity(index),
                          icon: const Icon(Icons.delete_outline),
                          color: AppTheme.errorColor,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (opportunity.duration != null && opportunity.duration!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 16,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            opportunity.duration!,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (opportunity.requirements != null && opportunity.requirements!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Requirements: ${opportunity.requirements}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (opportunity.benefits != null && opportunity.benefits!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Benefits: ${opportunity.benefits}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    image: _coverImageBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(_coverImageBase64!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImageBase64 == null
                      ? const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedCategory,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _titleController.text.isEmpty
                            ? 'Event Title'
                            : _titleController.text,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.calendar_today,
                        '${_startDate.day}/${_startDate.month}/${_startDate.year} at ${_startTime.format(context)}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        _locationController.text.isEmpty
                            ? 'Location'
                            : _locationController.text,
                      ),
                      if (_tickets.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.confirmation_number_outlined,
                          '${_tickets.length} ticket type(s)',
                        ),
                      ],
                      if (_volunteerOpportunities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.volunteer_activism_outlined,
                          '${_volunteerOpportunities.length} volunteer role(s)',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Volunteer Opportunities Summary
          if (_volunteerOpportunities.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Volunteer Opportunities',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._volunteerOpportunities.map((opp) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${opp.roleName} (${opp.capacity} spots)',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _volunteerOpportunities.isNotEmpty
                        ? 'Your event and volunteer opportunities are ready to be published!'
                        : 'Your event is ready to be published!',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : _currentStep == _totalSteps - 1
                      ? _publishEvent
                      : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == _totalSteps - 1
                    ? AppTheme.successColor
                    : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1 ? 'Publish Event' : 'Next',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textLight),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

/// Modal for adding a new ticket
class _AddTicketModal extends StatefulWidget {
  final Function(EventTicket) onAdd;

  const _AddTicketModal({required this.onAdd});

  @override
  State<_AddTicketModal> createState() => _AddTicketModalState();
}

class _AddTicketModalState extends State<_AddTicketModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _quantityController = TextEditingController(text: '100');
  bool _isFree = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final ticket = EventTicket(
      id: OrganizerStorageService.generateId('tkt'),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      price: _isFree ? 0 : double.parse(_priceController.text),
      quantity: int.parse(_quantityController.text),
      isFree: _isFree,
    );

    widget.onAdd(ticket);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Ticket Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ticket Name',
                  hintText: 'e.g., General Admission, VIP',
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What\'s included',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Free Ticket'),
                subtitle: const Text('No charge for this ticket'),
                value: _isFree,
                onChanged: (v) => setState(() => _isFree = v),
                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primaryColor;
                  }
                  return null;
                }),
              ),
              if (!_isFree) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Price is required';
                    final price = double.tryParse(v!);
                    if (price == null || price < 0) return 'Invalid price';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity Available',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Quantity is required';
                  final qty = int.tryParse(v!);
                  if (qty == null || qty < 1) return 'Must be at least 1';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal for adding/editing a volunteer opportunity
class _AddVolunteerModal extends StatefulWidget {
  final Function(VolunteerOpportunity) onAdd;
  final VolunteerOpportunity? existingOpportunity;

  const _AddVolunteerModal({
    required this.onAdd,
    this.existingOpportunity,
  });

  @override
  State<_AddVolunteerModal> createState() => _AddVolunteerModalState();
}

class _AddVolunteerModalState extends State<_AddVolunteerModal> {
  final _formKey = GlobalKey<FormState>();
  final _roleNameController = TextEditingController();
  final _capacityController = TextEditingController(text: '5');
  final _durationController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();

  bool get _isEditing => widget.existingOpportunity != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final opp = widget.existingOpportunity!;
      _roleNameController.text = opp.roleName;
      _capacityController.text = opp.capacity.toString();
      _durationController.text = opp.duration ?? '';
      _requirementsController.text = opp.requirements ?? '';
      _benefitsController.text = opp.benefits ?? '';
    }
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    _capacityController.dispose();
    _durationController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final opportunity = VolunteerOpportunity(
      id: _isEditing
          ? widget.existingOpportunity!.id
          : OrganizerStorageService.generateId('vol'),
      roleName: _roleNameController.text.trim(),
      capacity: int.parse(_capacityController.text),
      duration: _durationController.text.trim().isEmpty
          ? null
          : _durationController.text.trim(),
      requirements: _requirementsController.text.trim().isEmpty
          ? null
          : _requirementsController.text.trim(),
      benefits: _benefitsController.text.trim().isEmpty
          ? null
          : _benefitsController.text.trim(),
      status: _isEditing
          ? widget.existingOpportunity!.status
          : OpportunityStatus.draft,
    );

    widget.onAdd(opportunity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEditing ? 'Edit Volunteer Role' : 'Add Volunteer Role',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _roleNameController,
                decoration: const InputDecoration(
                  labelText: 'Role Name *',
                  hintText: 'e.g., Registration Desk, Technical Support',
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Role name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Number of Spots *',
                  hintText: 'How many volunteers needed',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Capacity is required';
                  final capacity = int.tryParse(v!);
                  if (capacity == null || capacity < 1) {
                    return 'Must be at least 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Time / Duration (optional)',
                  hintText: 'e.g., 9:00 AM – 2:00 PM',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Requirements (optional)',
                  hintText: 'Any skills or experience needed',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _benefitsController,
                decoration: const InputDecoration(
                  labelText: 'Benefits (optional)',
                  hintText: 'What volunteers receive',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_isEditing ? 'Save Changes' : 'Add Role'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
