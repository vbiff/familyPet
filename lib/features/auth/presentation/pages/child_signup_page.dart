import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/services/qr_scanner_service.dart';
import 'package:jhonny/core/services/qr_code_service.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';
import 'package:jhonny/features/auth/presentation/widgets/auth_button.dart';
import 'package:jhonny/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jhonny/features/home/presentation/pages/home_page.dart';

class ChildSignupPage extends ConsumerStatefulWidget {
  const ChildSignupPage({super.key});

  @override
  ConsumerState<ChildSignupPage> createState() => _ChildSignupPageState();
}

class _ChildSignupPageState extends ConsumerState<ChildSignupPage> {
  final PageController _pageController = PageController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ChildInviteQrData? _qrData;
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _onQrScanned(QrScanResult result) {
    if (result.isSuccess && result.childInviteData != null) {
      setState(() {
        _qrData = result.childInviteData;
        // Pre-fill display name if suggested
        if (_qrData?.childDisplayName != null) {
          _displayNameController.text = _qrData!.childDisplayName!;
        }
      });
      _nextPage();
    } else if (result.hasError) {
      _showErrorSnackBar(result.errorMessage ?? 'Failed to scan QR code');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createAccount() async {
    print('Create account button pressed');
    print('PIN controller text: "${_pinController.text}"');
    print('PIN controller text length: ${_pinController.text.length}');
    print('Confirm PIN controller text: "${_confirmPinController.text}"');
    print(
        'Confirm PIN controller text length: ${_confirmPinController.text.length}');
    print('Display name controller text: "${_displayNameController.text}"');

    // Check form validation
    final isFormValid = _formKey.currentState?.validate() == true;
    print('Form valid: $isFormValid');
    print('QR data exists: ${_qrData != null}');
    print('QR token: ${_qrData?.token}');

    if (!isFormValid) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    if (_qrData == null) {
      _showErrorSnackBar(
          'QR code data is missing. Please scan the QR code again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting account creation...');
      print('Token: ${_qrData!.token}');
      print('Display name: ${_displayNameController.text.trim()}');
      print('PIN length: ${_pinController.text.length}');

      final result = await ref.read(authRepositoryProvider).signUpChildWithPin(
            token: _qrData!.token,
            displayName: _displayNameController.text.trim(),
            pin: _pinController.text,
          );

      result.fold(
        (failure) {
          print('Account creation failed: ${failure.message}');
          _showErrorSnackBar(failure.message);
        },
        (user) {
          print('Account creation successful for user: ${user.displayName}');
          // Navigate to home page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        },
      );
    } catch (e) {
      print('Unexpected error during account creation: $e');
      _showErrorSnackBar('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    // Listen for auth state changes
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
        child: Column(
          children: [
            // Header with progress indicator
            _buildHeader(),

            // Page content
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildQrScannerPage(),
                    _buildPersonalInfoPage(),
                    _buildPinSetupPage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Back button
          Row(
            children: [
              if (_currentPage > 0)
                IconButton(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.arrow_back),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress indicator
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 8),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            _getPageTitle(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          if (_getPageSubtitle() != null) ...[
            const SizedBox(height: 8),
            Text(
              _getPageSubtitle()!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Scan QR Code';
      case 1:
        return 'Tell us about yourself';
      case 2:
        return 'Create your PIN';
      default:
        return 'Welcome';
    }
  }

  String? _getPageSubtitle() {
    switch (_currentPage) {
      case 0:
        return 'Ask your parent to show you the QR code to join your family';
      case 1:
        return 'Let\'s set up your profile';
      case 2:
        return 'Choose a PIN that you\'ll remember to sign in';
      default:
        return null;
    }
  }

  Widget _buildQrScannerPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // QR Scanner
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QrScannerService.buildQrScanner(
                  onScan: _onQrScanned,
                  overlay: const ChildInviteQrOverlay(
                    instruction: 'Point your camera at the QR code',
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Help text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure the QR code is well-lit and fully visible in the frame',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Family info (if available)
          if (_qrData != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Joining Family',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _qrData?.familyName ?? 'Unknown Family',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Display name field
          AuthTextField(
            label: 'Your Name',
            hint: 'What should we call you?',
            controller: _displayNameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Next button
          AuthButton(
            label: 'Continue',
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                _nextPage();
              }
            },
            isLoading: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPinSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PIN input
          AuthTextField(
            label: 'Create PIN',
            hint: 'Enter 4-6 digits',
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a PIN';
              }
              if (value.length < 4) {
                return 'PIN must be at least 4 digits';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Confirm PIN input
          AuthTextField(
            label: 'Confirm PIN',
            hint: 'Enter your PIN again',
            controller: _confirmPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your PIN';
              }
              if (value != _pinController.text) {
                return 'PINs do not match';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // PIN tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIN Tips:',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  'Choose something you\'ll remember',
                  'Don\'t use obvious patterns like 1234',
                  'Keep it secret from others'
                ].map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Create account button
          AuthButton(
            label: 'Create Account',
            onPressed: _createAccount,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
