import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';
import 'package:jhonny/features/auth/presentation/widgets/auth_button.dart';
import 'package:jhonny/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jhonny/features/home/presentation/pages/home_page.dart';

class ChildSigninPage extends ConsumerStatefulWidget {
  const ChildSigninPage({super.key});

  @override
  ConsumerState<ChildSigninPage> createState() => _ChildSigninPageState();
}

class _ChildSigninPageState extends ConsumerState<ChildSigninPage> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePin = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(authRepositoryProvider).signInWithPin(
            displayName: _displayNameController.text.trim(),
            pin: _pinController.text,
          );

      result.fold(
        (failure) {
          _showErrorSnackBar(failure.message);
        },
        (user) {
          // Success handled by auth state listener
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _togglePinVisibility() {
    setState(() {
      _obscurePin = !_obscurePin;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for successful authentication
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Header
                _buildHeader(),

                const SizedBox(height: 48),

                // Name field
                AuthTextField(
                  label: 'Your Name',
                  hint: 'Enter your name',
                  controller: _displayNameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // PIN field
                AuthTextField(
                  label: 'PIN',
                  hint: 'Enter your PIN',
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _handleSignIn,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your PIN';
                    }
                    if (value.length < 4) {
                      return 'PIN must be at least 4 digits';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: _togglePinVisibility,
                    icon: Icon(
                      _obscurePin ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign in button
                AuthButton(
                  label: 'Sign In',
                  onPressed: _handleSignIn,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Help section
                _buildHelpSection(),

                const SizedBox(height: 40),

                // Back to parent login
                _buildBackToParentLogin(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App icon/logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.pets,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),

        const SizedBox(height: 24),

        // Welcome message
        Text(
          'Welcome back!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Sign in with your name and PIN',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Need help?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHelpItem(
            Icons.person,
            'Enter the same name you used when you first joined',
          ),
          const SizedBox(height: 8),
          _buildHelpItem(
            Icons.lock,
            'Use the PIN you created when you signed up',
          ),
          const SizedBox(height: 8),
          _buildHelpItem(
            Icons.family_restroom,
            'Ask your parents if you forgot your name or PIN',
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToParentLogin() {
    return Column(
      children: [
        Divider(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Parent Login'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Simple PIN input widget with visual feedback
class PinInputWidget extends StatefulWidget {
  final Function(String) onChanged;
  final Function(String) onCompleted;
  final int length;
  final bool obscureText;

  const PinInputWidget({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.length = 6,
    this.obscureText = true,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    widget.onChanged(_getCurrentPin());

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_getCurrentPin().length == widget.length) {
      widget.onCompleted(_getCurrentPin());
    }
  }

  String _getCurrentPin() {
    return _controllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            obscureText: widget.obscureText,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) => _onChanged(value, index),
            onTap: () {
              _controllers[index].selection = TextSelection.fromPosition(
                TextPosition(offset: _controllers[index].text.length),
              );
            },
          ),
        );
      }),
    );
  }
}
