import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/category_api_model.dart';
import '../../theme/app_theme.dart';

class EventsApiFilterScreen extends StatefulWidget {
  final List<CategoryApiModel> categories;
  final int? selectedCategoryId;
  final String? selectedCity;
  final String? selectedPlace;
  final DateTime? selectedDate;
  final bool liveOnly;
  final Function({
    int? categoryId,
    String? city,
    String? place,
    DateTime? date,
    required bool liveOnly,
  }) onApplyFilters;

  const EventsApiFilterScreen({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedCity,
    required this.selectedPlace,
    required this.selectedDate,
    required this.liveOnly,
    required this.onApplyFilters,
  });

  @override
  State<EventsApiFilterScreen> createState() => _EventsApiFilterScreenState();
}

class _EventsApiFilterScreenState extends State<EventsApiFilterScreen> {
  late int? _selectedCategoryId;
  late String? _selectedCity;
  late String? _selectedPlace;
  late DateTime? _selectedDate;
  late bool _liveOnly;

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedCity = widget.selectedCity;
    _selectedPlace = widget.selectedPlace;
    _selectedDate = widget.selectedDate;
    _liveOnly = widget.liveOnly;

    _cityController.text = _selectedCity ?? '';
    _placeController.text = _selectedPlace ?? '';
  }

  @override
  void dispose() {
    _cityController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _selectedDate = picked);
    }
  }

  void _clearFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategoryId = null;
      _selectedCity = null;
      _selectedPlace = null;
      _selectedDate = null;
      _liveOnly = false;
      _cityController.clear();
      _placeController.clear();
    });
  }

  void _applyFilters() {
    HapticFeedback.lightImpact();
    widget.onApplyFilters(
      categoryId: _selectedCategoryId,
      city: _cityController.text.isEmpty ? null : _cityController.text,
      place: _placeController.text.isEmpty ? null : _placeController.text,
      date: _selectedDate,
      liveOnly: _liveOnly,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = [
      CategoryApiModel(id: 0, name: 'All'),
      ...widget.categories,
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Filter Events'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: allCategories.map((category) {
                final isSelected = (_selectedCategoryId == null && category.id == 0) ||
                    _selectedCategoryId == category.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategoryId = category.id == 0 ? null : category.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Date
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDate != null
                        ? AppTheme.primaryColor
                        : AppTheme.textLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _selectedDate != null ? AppTheme.primaryColor : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Select date'
                            : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedDate = null);
                        },
                        child: const Icon(
                          Icons.clear,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Live Only
            const Text(
              'Event Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                ),
              ),
              child: SwitchListTile(
                value: _liveOnly,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _liveOnly = value);
                },
                title: const Text('Show only live events'),
                subtitle: const Text('Events happening right now'),
                activeColor: AppTheme.primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 32),

            // City
            const Text(
              'City',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Enter city name',
                prefixIcon: const Icon(Icons.location_city, color: AppTheme.primaryColor),
                suffixIcon: _cityController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _cityController.clear();
                            _selectedCity = null;
                          });
                        },
                      )
                    : null,
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
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value.isEmpty ? null : value;
                });
              },
            ),
            const SizedBox(height: 32),

            // Place
            const Text(
              'Place',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search by location or venue',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _placeController,
              decoration: InputDecoration(
                hintText: 'Enter location or venue',
                prefixIcon: const Icon(Icons.place, color: AppTheme.primaryColor),
                suffixIcon: _placeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _placeController.clear();
                            _selectedPlace = null;
                          });
                        },
                      )
                    : null,
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
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedPlace = value.isEmpty ? null : value;
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Apply Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
