import 'package:flutter/material.dart';
import '../../models/my_ticket_model.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';

class TicketRequestScreen extends StatefulWidget {
  const TicketRequestScreen({super.key});

  @override
  State<TicketRequestScreen> createState() => _TicketRequestScreenState();
}

class _TicketRequestScreenState extends State<TicketRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  TicketModel? _selectedTicket;
  String? _selectedReason;
  final _additionalInfoController = TextEditingController();
  bool _agreedToTerms = false;

  List<TicketModel> _availableTickets = [];

  @override
  void initState() {
    super.initState();
    // Get only active tickets
    _availableTickets = TicketModel.getMockTickets().where((t) => t.isActive).toList();
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Ticket'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ticket requests are processed within 5-7 business days. Please review our policy before submitting.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Select Ticket
              const Text(
                'Select Ticket',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (_availableTickets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      'No eligible tickets available',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...List.generate(_availableTickets.length, (index) {
                  final ticket = _availableTickets[index];
                  final isSelected = _selectedTicket?.id == ticket.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTicket = ticket;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textLight.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: ticket.id,
                            groupValue: _selectedTicket?.id,
                            onChanged: (value) {
                              setState(() {
                                _selectedTicket = ticket;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.eventTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ticket.ticketType} • ${ticket.seatNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${ticket.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              // Select Reason
              const Text(
                'Reason',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  hintText: 'Select a reason',
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
                ),
                items: MyTicketModel.getTicketReasons().map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Additional Information
              const Text(
                'Additional Information (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _additionalInfoController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Provide any additional details...',
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
                ),
              ),
              const SizedBox(height: 24),
              // Terms checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'I understand that processing may take 5-7 business days and I agree to the policy terms.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedTicket != null && _selectedReason != null && _agreedToTerms
                      ? _submitRequest
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: AppTheme.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Request Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your ticket request has been submitted successfully. We will review it and get back to you soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
