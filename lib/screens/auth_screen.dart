import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import '../services/api_client.dart';
import '../models/category_api_model.dart';
import '../config.dart';
import '../providers/profile_provider.dart';

enum AuthMode { signIn, signUp }

enum _ImageAction { camera, gallery, remove }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.onBackRequested, this.onCompleted});

  final void Function(BuildContext context)? onBackRequested;
  final void Function(BuildContext context)? onCompleted;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

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

  AuthMode _mode = AuthMode.signIn;
  bool _isSubmitting = false;
  bool _isLoadingCategories = false;
  Uint8List? _profileImageBytes;
  String? _selectedCity;
  List<CategoryApiModel> _categories = [];
  List<CategoryApiModel> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final response = await ApiClient.getCategories();

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final categories = jsonList
            .map((json) => CategoryApiModel.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _categories = categories;
            _isLoadingCategories = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingCategories = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _switchMode(AuthMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
      // Clear all form fields when switching modes
      _clearAllFields();
    });
  }

  void _clearAllFields() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _birthDateController.clear();
    _selectedCity = null;
    _selectedCategories = [];
    _profileImageBytes = null;
    _formKey.currentState?.reset();
  }

  void _handleBack() {
    final handler = widget.onBackRequested;
    if (handler != null) {
      handler(context);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _showImageSourceActionSheet() async {
    final action = await showModalBottomSheet<_ImageAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profile photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_ImageAction.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Use camera'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_ImageAction.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from gallery'),
                ),
                if (_profileImageBytes != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_ImageAction.remove),
                    child: const Text('Remove current photo'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _ImageAction.remove) {
      setState(() => _profileImageBytes = null);
      return;
    }

    final source = action == _ImageAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 720,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() => _profileImageBytes = bytes);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t pick image. Please try again.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Only call API for Sign Up mode
      if (_mode == AuthMode.signUp) {
        // Convert profile image to base64 if available
        String? pictureBase64;
        if (_profileImageBytes != null) {
          pictureBase64 = base64Encode(_profileImageBytes!);
        }

        // Build the JSON payload matching Laravel's expected format
        final requestData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _selectedCity ?? '',
          'birth_date': _birthDateController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
          'picture': pictureBase64, // Send base64 encoded image
          'categories': _selectedCategories.map((c) => c.name).toList(),
        };

        // Call the API
        final response = await ApiClient.registerUser(requestData);

        if (!mounted) {
          return;
        }

        // Handle response
        if (response.statusCode == 201) {
          // Success - User registered
          final responseData = json.decode(response.body);
          final message = responseData['message'] ?? 'User registered successfully';

          // DEBUG: Print the full response to see what backend returns
          debugPrint('=== SIGNUP RESPONSE ===');
          debugPrint(response.body);
          debugPrint('=======================');

          // Extract token if provided (check all possible field names)
          String? token = responseData['token'] ??
                          responseData['access_token'] ??
                          responseData['authorization']?['token'] ??
                          responseData['data']?['token'] ??
                          responseData['data']?['access_token'] ??
                          responseData['user']?['token'];

          // Get profile provider
          final profileProvider = context.read<ProfileProvider>();

          // Try to set profile from response data first
          if (responseData['user'] != null || responseData['data']?['user'] != null) {
            // Backend returned user data - use it
            profileProvider.setProfileFromRegistration(
              responseData,
              token: token,
            );
          } else {
            // Backend didn't return user data - use form data
            // This allows immediate access even without token/user from backend
            profileProvider.setProfileFromBasicInfo(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              location: _selectedCity,
              token: token,
            );
          }

          // Clear all form fields after successful signup
          setState(() {
            _isSubmitting = false;
            _clearAllFields();
          });

          if (!mounted) return;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate directly to home - skip any verification screens
          final completed = widget.onCompleted;
          if (completed != null) {
            completed(context);
            return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          );
          return;
        } else if (response.statusCode == 422) {
          // Validation error from Laravel
          final errorData = json.decode(response.body);
          final errors = errorData['errors'] as Map<String, dynamic>?;

          String errorMessage = 'Validation failed';
          if (errors != null && errors.isNotEmpty) {
            // Get the first error message
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            }
          }

          setState(() => _isSubmitting = false);

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
          return;
        } else {
          // Other error
          setState(() => _isSubmitting = false);

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else if (_mode == AuthMode.signIn) {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final response = await ApiClient.loginUser(email, password);

        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final message = data['message'] ?? 'Login successful';

          // DEBUG: Print the full response to see what backend returns
          debugPrint('=== LOGIN RESPONSE ===');
          debugPrint(response.body);
          debugPrint('======================');

          // Extract and save the token (check all possible field names)
          String? token = data['token'] ??
                          data['access_token'] ??
                          data['authorization']?['token'] ??
                          data['data']?['token'] ??
                          data['data']?['access_token'] ??
                          data['user']?['token'];

          if (token != null && token.isNotEmpty) {
            // Save token to AuthHelper
            AuthHelper.setToken(token);

            // Fetch user profile
            if (mounted) {
              final profileProvider = context.read<ProfileProvider>();
              await profileProvider.fetchProfile();
            }
          }

          setState(() => _isSubmitting = false);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );

          final completed = widget.onCompleted;
          if (completed != null) {
            completed(context);
            return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          );
        } else if (response.statusCode == 401) {
          setState(() => _isSubmitting = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email or password is incorrect.'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (response.statusCode == 403) {
          // Email not verified on server
          setState(() => _isSubmitting = false);

          if (!mounted) return;

          // Show friendly dialog instead of just a snackbar
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.mail_outline,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  const Text('Email Not Verified'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your account is not verified on the server yet.',
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Please check your email inbox (and spam folder) for a verification link.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          setState(() => _isSubmitting = false);

          // Try to get error message from response
          String errorMessage = 'Something went wrong. Please try again.';
          try {
            final data = json.decode(response.body);
            if (data['message'] != null) {
              errorMessage = data['message'];
            }
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMessage (Status: ${response.statusCode})'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Network or other error
      setState(() => _isSubmitting = false);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  void _continueAsGuest() {
    final completed = widget.onCompleted;
    if (completed != null) {
      completed(context);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  String? _validateName(String? value) {
    if (_mode != AuthMode.signUp) {
      return null;
    }
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Please enter your full name';
    }
    if (trimmed.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (_mode != AuthMode.signUp) {
      return null;
    }
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Phone number is required';
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 7) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_mode != AuthMode.signUp) {
      return null;
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (_mode != AuthMode.signUp) {
      return null;
    }
    if (value == null || value.isEmpty) {
      return 'Please choose your city';
    }
    return null;
  }

  Future<void> _showCategoryDialog() async {
    final List<CategoryApiModel> tempSelected = List.from(_selectedCategories);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Categories'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = tempSelected.any((c) => c.id == category.id);

                    return CheckboxListTile(
                      title: Text(category.name),
                      value: isSelected,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            tempSelected.add(category);
                          } else {
                            tempSelected.removeWhere((c) => c.id == category.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedCategories = tempSelected;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _validateBirthDate(String? value) {
    if (_mode != AuthMode.signUp) {
      return null;
    }
    if (value == null || value.isEmpty) {
      return 'Please select your birth date';
    }
    return null;
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6A62FF)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6A62FF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _mode == AuthMode.signIn
                          ? 'Welcome back'
                          : 'Create an account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mode == AuthMode.signIn
                          ? 'Sign in to continue planning amazing events.'
                          : 'Join us to discover events, track RSVPs, and more.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF707070),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ModeToggle(mode: _mode, onChanged: _switchMode),
                            const SizedBox(height: 18),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_mode == AuthMode.signUp) ...[
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: _showImageSourceActionSheet,
                                          child: CircleAvatar(
                                            radius: 32,
                                            backgroundColor: const Color(
                                              0xFF6A62FF,
                                            ),
                                            backgroundImage:
                                                _profileImageBytes == null
                                                ? null
                                                : MemoryImage(
                                                    _profileImageBytes!,
                                                  ),
                                            child: _profileImageBytes == null
                                                ? const Icon(
                                                    Icons.add_a_photo_outlined,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Add a profile photo so friends can find you.',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF606060,
                                                  ),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _nameController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: _fieldDecoration(
                                        label: 'Full name',
                                        icon: Icons.person_outline,
                                      ),
                                      validator: _validateName,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      autofillHints: const [
                                        AutofillHints.telephoneNumber,
                                      ],
                                      decoration: _fieldDecoration(
                                        label: 'Phone number',
                                        icon: Icons.call_outlined,
                                      ),
                                      validator: _validatePhone,
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _selectedCity,
                                      items: _syrianCities
                                          .map(
                                            (city) => DropdownMenuItem(
                                              value: city,
                                              child: Text(city),
                                            ),
                                          )
                                          .toList(),
                                      decoration: _fieldDecoration(
                                        label: 'City',
                                        icon: Icons.location_city_outlined,
                                      ),
                                      onChanged: (value) =>
                                          setState(() => _selectedCity = value),
                                      validator: _validateCity,
                                    ),
                                    const SizedBox(height: 12),
                                    // Category Multi-Select Field
                                    GestureDetector(
                                      onTap: _isLoadingCategories ? null : _showCategoryDialog,
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          decoration: _fieldDecoration(
                                            label: 'Categories (tap to select)',
                                            icon: Icons.category_outlined,
                                          ),
                                          controller: TextEditingController(
                                            text: _selectedCategories.isEmpty
                                                ? ''
                                                : _selectedCategories
                                                    .map((c) => c.name)
                                                    .join(', '),
                                          ),
                                          validator: (value) {
                                            if (_selectedCategories.isEmpty) {
                                              return 'Please select at least one category';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _birthDateController,
                                      readOnly: true,
                                      decoration: _fieldDecoration(
                                        label: 'Birth date',
                                        icon: Icons.calendar_today_outlined,
                                      ),
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now().subtract(
                                            const Duration(days: 365 * 18),
                                          ),
                                          firstDate: DateTime(1900),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            _birthDateController.text =
                                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                          });
                                        }
                                      },
                                      validator: _validateBirthDate,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: _fieldDecoration(
                                      label: 'Email address',
                                      icon: Icons.mail_outline,
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    decoration: _fieldDecoration(
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                    ),
                                    validator: _validatePassword,
                                  ),
                                  if (_mode == AuthMode.signUp) ...[
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: true,
                                      decoration: _fieldDecoration(
                                        label: 'Confirm password',
                                        icon: Icons.lock_reset_outlined,
                                      ),
                                      validator: _validateConfirmPassword,
                                    ),
                                  ],
                                  if (_mode == AuthMode.signIn) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          foregroundColor: const Color(
                                            0xFF6A62FF,
                                          ),
                                        ),
                                        child: const Text('Forgot password?'),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  _PrimaryButton(
                                    onPressed: _isSubmitting ? null : _submit,
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            _mode == AuthMode.signIn
                                                ? 'Sign in'
                                                : 'Create account',
                                          ),
                                  ),
                                  if (_mode == AuthMode.signIn) ...[
                                    const SizedBox(height: 12),
                                    _SecondaryButton(
                                      onPressed: _continueAsGuest,
                                      child: const Text('Continue as guest'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => _switchMode(
                          _mode == AuthMode.signIn
                              ? AuthMode.signUp
                              : AuthMode.signIn,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6A62FF),
                        ),
                        child: Text(
                          _mode == AuthMode.signIn
                              ? 'New here? Create an account'
                              : 'Already have an account? Sign in',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => onChanged(AuthMode.signIn),
            style: OutlinedButton.styleFrom(
              foregroundColor: mode == AuthMode.signIn
                  ? Colors.white
                  : const Color(0xFF1F1F1F),
              backgroundColor: mode == AuthMode.signIn
                  ? const Color(0xFF6A62FF)
                  : Colors.white,
              side: const BorderSide(color: Color(0xFF6A62FF)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: mode == AuthMode.signIn
                    ? Colors.white
                    : const Color(0xFF1F1F1F),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => onChanged(AuthMode.signUp),
            style: OutlinedButton.styleFrom(
              foregroundColor: mode == AuthMode.signUp
                  ? Colors.white
                  : const Color(0xFF1F1F1F),
              backgroundColor: mode == AuthMode.signUp
                  ? const Color(0xFF6A62FF)
                  : Colors.white,
              side: const BorderSide(color: Color(0xFF6A62FF)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: mode == AuthMode.signUp
                    ? Colors.white
                    : const Color(0xFF1F1F1F),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF6A62FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: const Color(0xFF6A62FF),
          side: const BorderSide(color: Color(0xFF6A62FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: child,
      ),
    );
  }
}
