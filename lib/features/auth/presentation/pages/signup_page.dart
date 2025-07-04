import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';
import 'package:jhonny/features/auth/presentation/widgets/auth_button.dart';
import 'package:jhonny/features/auth/presentation/widgets/auth_layout.dart';
import 'package:jhonny/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jhonny/features/home/presentation/pages/home_page.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.parent;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your display name';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authNotifierProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
            role: _selectedRole,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    // Listen for auth state changes and navigate to home when authenticated
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }
    });

    return AuthLayout(
      title: 'Create Account',
      subtitle: 'Join your family and start your journey',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          TextButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Sign In'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Display Name',
              hint: 'Enter your display name',
              controller: _displayNameController,
              validator: _validateDisplayName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Email',
              hint: 'Enter your email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              textInputAction: TextInputAction.done,
              onEditingComplete: _handleSignup,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            const SizedBox(height: 24),
            SegmentedButton<UserRole>(
              segments: const [
                ButtonSegment<UserRole>(
                  value: UserRole.parent,
                  label: Text('Parent'),
                  icon: Icon(Icons.person),
                ),
                ButtonSegment<UserRole>(
                  value: UserRole.child,
                  label: Text('Child'),
                  icon: Icon(Icons.child_care),
                ),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (Set<UserRole> newSelection) {
                setState(() {
                  _selectedRole = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            if (authState.status == AuthStatus.error &&
                authState.failure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  authState.failure!.message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            AuthButton(
              label: 'Sign Up',
              onPressed: _handleSignup,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
