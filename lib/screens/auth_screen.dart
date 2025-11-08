import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';

enum AuthMode { signIn, signUp }
enum _ImageAction { camera, gallery, remove }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.onBackRequested,
    this.onCompleted,
  });

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
  final ImagePicker _imagePicker = ImagePicker();

  AuthMode _mode = AuthMode.signIn;
  bool _isSubmitting = false;
  Uint8List? _profileImageBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() => _mode = mode);
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

    final source =
        action == _ImageAction.camera ? ImageSource.camera : ImageSource.gallery;
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

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    final completed = widget.onCompleted;
    if (completed != null) {
      completed(context);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  void _continueAsGuest() {
    final completed = widget.onCompleted;
    if (completed != null) {
      completed(context);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: _handleBack,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ModeToggle(
                          mode: _mode,
                          onChanged: _switchMode,
                        ),
                        const SizedBox(height: 24),
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
                                        radius: 36,
                                        backgroundColor:
                                            const Color(0xFF6A62FF),
                                        backgroundImage: _profileImageBytes ==
                                                null
                                            ? null
                                            : MemoryImage(_profileImageBytes!),
                                        child: _profileImageBytes == null
                                            ? const Icon(
                                                Icons.add_a_photo_outlined,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Add a profile photo so friends can find you.',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color: const Color(0xFF606060),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
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
                                const SizedBox(height: 16),
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
                                const SizedBox(height: 16),
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                decoration: _fieldDecoration(
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                ),
                                validator: _validatePassword,
                              ),
                              if (_mode == AuthMode.signUp) ...[
                                const SizedBox(height: 16),
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
                                      foregroundColor:
                                          const Color(0xFF6A62FF),
                                    ),
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
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
                              const SizedBox(height: 16),
                              _SecondaryButton(
                                onPressed: _continueAsGuest,
                                child: const Text('Continue as guest'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                mode == AuthMode.signIn ? null : () => onChanged(AuthMode.signIn),
            style: OutlinedButton.styleFrom(
              foregroundColor: mode == AuthMode.signIn
                  ? Colors.white
                  : const Color(0xFF6A62FF),
              backgroundColor:
                  mode == AuthMode.signIn ? const Color(0xFF6A62FF) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Sign In'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed:
                mode == AuthMode.signUp ? null : () => onChanged(AuthMode.signUp),
            style: OutlinedButton.styleFrom(
              foregroundColor: mode == AuthMode.signUp
                  ? Colors.white
                  : const Color(0xFF6A62FF),
              backgroundColor:
                  mode == AuthMode.signUp ? const Color(0xFF6A62FF) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Sign Up'),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
  const _SecondaryButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
