import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/services/qr_code_service.dart';
import 'package:jhonny/core/services/qr_share_service.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';

class ChildInviteQrPage extends ConsumerStatefulWidget {
  const ChildInviteQrPage({super.key});

  @override
  ConsumerState<ChildInviteQrPage> createState() => _ChildInviteQrPageState();
}

class _ChildInviteQrPageState extends ConsumerState<ChildInviteQrPage> {
  final TextEditingController _childNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _qrKey = GlobalKey();

  String? _generatedToken;
  bool _isGenerating = false;
  bool _showAdvancedOptions = false;
  bool _isSharing = false;
  bool _isSaving = false;
  int? _expiryHours; // Changed to nullable, null means never expire

  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }

  Future<void> _generateQrCode() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final familyState = ref.read(familyNotifierProvider);

    if (user == null || familyState.family == null) {
      _showErrorSnackBar('Unable to generate QR code. Please try again.');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final result =
          await ref.read(authRepositoryProvider).createChildInvitationToken(
                familyId: familyState.family!.id,
                childDisplayName: _childNameController.text.trim().isNotEmpty
                    ? _childNameController.text.trim()
                    : null,
                expiresInHours: _expiryHours,
              );

      result.fold(
        (failure) {
          _showErrorSnackBar(failure.message);
        },
        (token) {
          setState(() {
            _generatedToken = token;
          });
          _showSuccessSnackBar('QR code generated successfully!');
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _shareQrCode() async {
    if (_generatedToken == null) {
      _showErrorSnackBar('No QR code available to share');
      return;
    }

    final familyState = ref.read(familyNotifierProvider);
    if (familyState.family == null) {
      _showErrorSnackBar('Family information not available');
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      // Small delay to ensure QR code is fully rendered
      await Future.delayed(const Duration(milliseconds: 100));

      await QrShareService.shareInvitationWithOptions(
        context: context,
        qrKey: _qrKey,
        familyName: familyState.family!.name,
        token: _generatedToken!,
        childDisplayName: _childNameController.text.trim().isNotEmpty
            ? _childNameController.text.trim()
            : null,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share QR code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _saveQrCode() async {
    if (_generatedToken == null) {
      _showErrorSnackBar('No QR code available to save');
      return;
    }

    final familyState = ref.read(familyNotifierProvider);
    if (familyState.family == null) {
      _showErrorSnackBar('Family information not available');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Small delay to ensure QR code is fully rendered
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await QrShareService.saveQrCodeToGallery(
        qrKey: _qrKey,
        familyName: familyState.family!.name,
        childDisplayName: _childNameController.text.trim().isNotEmpty
            ? _childNameController.text.trim()
            : null,
      );

      if (success) {
        _showSuccessSnackBar('QR code saved to gallery!');
      } else {
        _showErrorSnackBar(
            'Failed to save QR code. Please check app permissions.');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save QR code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _generateNewCode() {
    setState(() {
      _generatedToken = null;
    });
    _regenerateQrCode();
  }

  Future<void> _regenerateQrCode() async {
    final user = ref.read(currentUserProvider);
    final familyState = ref.read(familyNotifierProvider);

    if (user == null || familyState.family == null) {
      _showErrorSnackBar('Unable to generate QR code. Please try again.');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final result =
          await ref.read(authRepositoryProvider).createChildInvitationToken(
                familyId: familyState.family!.id,
                childDisplayName: _childNameController.text.trim().isNotEmpty
                    ? _childNameController.text.trim()
                    : null,
                expiresInHours: _expiryHours,
              );

      result.fold(
        (failure) {
          _showErrorSnackBar(failure.message);
        },
        (token) {
          setState(() {
            _generatedToken = token;
          });
          _showSuccessSnackBar('New QR code generated successfully!');
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _copyInvitationToken() async {
    if (_generatedToken == null) return;

    await Clipboard.setData(ClipboardData(text: _generatedToken!));
    _showSuccessSnackBar('Invitation token copied to clipboard!');
  }

  Future<void> _copyInvitationLink() async {
    if (_generatedToken == null) return;

    final familyState = ref.read(familyNotifierProvider);
    if (familyState.family == null) return;

    try {
      await QrShareService.copyInvitationLink(
        token: _generatedToken!,
        familyName: familyState.family!.name,
        childDisplayName: _childNameController.text.trim().isNotEmpty
            ? _childNameController.text.trim()
            : null,
      );
      _showSuccessSnackBar('Invitation link copied to clipboard!');
    } catch (e) {
      _showErrorSnackBar('Failed to copy link: $e');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Child'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: familyState.family == null
          ? _buildNoFamilyState()
          : _generatedToken == null
              ? _buildFormState()
              : _buildQrCodeState(),
    );
  }

  Widget _buildNoFamilyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Family Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be part of a family to invite children.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState() {
    final familyState = ref.watch(familyNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 32),

            // Family info
            _buildFamilyInfo(familyState.family!.name),

            const SizedBox(height: 24),

            // Child name input
            _buildChildNameInput(),

            const SizedBox(height: 24),

            // Advanced options
            _buildAdvancedOptions(),

            const SizedBox(height: 32),

            // Generate button
            _buildGenerateButton(),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeState() {
    final familyState = ref.watch(familyNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'QR Code Generated!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Show this QR code to your child to let them join your family',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // QR Code
          Center(
            child: RepaintBoundary(
              key: _qrKey,
              child: QrCodeService.buildShareableQrCode(
                token: _generatedToken!,
                familyName: familyState.family!.name,
                childDisplayName: _childNameController.text.trim().isNotEmpty
                    ? _childNameController.text.trim()
                    : null,
                size: 280,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Expiry info
          _buildExpiryInfo(),

          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(),

          const SizedBox(height: 24),

          // Tips
          _buildQrTips(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.qr_code,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Invite Your Child',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Generate a QR code to add a child to your family without needing email',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildFamilyInfo(String familyName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.family_restroom,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inviting to',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  familyName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildNameInput() {
    return TextFormField(
      controller: _childNameController,
      decoration: InputDecoration(
        labelText: 'Child\'s Name (Optional)',
        hintText: 'Enter your child\'s name',
        helperText: 'This will pre-fill the name during signup',
        prefixIcon: const Icon(Icons.child_care),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value != null && value.isNotEmpty && value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showAdvancedOptions = !_showAdvancedOptions;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Advanced Options',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showAdvancedOptions) ...[
          const SizedBox(height: 16),
          Text(
            'QR Code Expiry',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            value: _expiryHours,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.timer),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Never expire')),
              DropdownMenuItem(value: 1, child: Text('1 hour')),
              DropdownMenuItem(value: 6, child: Text('6 hours')),
              DropdownMenuItem(value: 12, child: Text('12 hours')),
              DropdownMenuItem(value: 24, child: Text('24 hours')),
              DropdownMenuItem(value: 48, child: Text('2 days')),
              DropdownMenuItem(value: 168, child: Text('1 week')),
            ],
            onChanged: (value) {
              setState(() {
                _expiryHours = value;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildGenerateButton() {
    return FilledButton.icon(
      onPressed: _isGenerating ? null : _generateQrCode,
      icon: _isGenerating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.qr_code),
      label: Text(_isGenerating ? 'Generating...' : 'Generate QR Code'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
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
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'How it works',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            '1. Generate a QR code with optional child name',
            '2. Show the QR code to your child',
            '3. Child scans the code with the app',
            '4. Child creates their account with a PIN',
          ].map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExpiryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _expiryHours == null
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _expiryHours == null ? Icons.all_inclusive : Icons.schedule,
            color: _expiryHours == null
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR Code Expiry',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _expiryHours == null
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _expiryHours == null
                      ? 'This QR code never expires'
                      : 'Expires in ${_expiryHours == 1 ? '1 hour' : '$_expiryHours hours'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _expiryHours == null
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                if (_expiryHours != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Until ${DateTime.now().add(Duration(hours: _expiryHours!)).toString().split('.')[0]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary actions row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSharing ? null : _shareQrCode,
                icon: _isSharing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(_isSharing ? 'Sharing...' : 'Share'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _saveQrCode,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isSaving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Copy actions row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyInvitationToken,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Token'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyInvitationLink,
                icon: const Icon(Icons.link),
                label: const Text('Copy Link'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Generate new code action
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isGenerating ? null : _generateNewCode,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(_isGenerating ? 'Generating...' : 'Generate New Code'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            'Make sure your child has the Jhonny app installed',
            'Ensure good lighting when scanning the QR code',
            'QR code expires automatically for security',
            'You can generate multiple codes if needed',
          ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
