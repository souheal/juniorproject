import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../theme/app_theme.dart';

class EventsFilterScreen extends StatefulWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const EventsFilterScreen({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<EventsFilterScreen> createState() => _EventsFilterScreenState();
}

class _EventsFilterScreenState extends State<EventsFilterScreen> {
  late String _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 500);
  String _selectedDateFilter = 'Any time';

  final List<String> _dateFilters = [
    'Any time',
    'Today',
    'Tomorrow',
    'This week',
    'This month',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
                _priceRange = const RangeValues(0, 500);
                _selectedDateFilter = 'Any time';
              });
            },
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
              children: EventModel.getCategories().map((category) {
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textLight.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      category,
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
            // Date Filter
            const Text(
              'Date',
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
              children: _dateFilters.map((filter) {
                final isSelected = filter == _selectedDateFilter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textLight.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      filter,
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
            // Price Range
            const Text(
              'Price Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 500,
              divisions: 50,
              activeColor: AppTheme.primaryColor,
              inactiveColor: AppTheme.primaryColor.withOpacity(0.2),
              labels: RangeLabels(
                '\$${_priceRange.start.toInt()}',
                '\$${_priceRange.end.toInt()}',
              ),
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                });
              },
            ),
            const SizedBox(height: 32),
            // Location
            const Text(
              'Location',
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
                border: Border.all(color: AppTheme.textLight.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: const Icon(Icons.my_location, color: AppTheme.primaryColor),
                title: const Text('Use current location'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: AppTheme.primaryColor,
                ),
              ),
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              widget.onCategorySelected(_selectedCategory);
              Navigator.pop(context);
            },
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
