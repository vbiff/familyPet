import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum EnhancedInputType {
  text,
  email,
  password,
  search,
  multiline,
  number,
  phone,
}

class EnhancedInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? placeholder;
  final String? description;
  final TextEditingController? controller;
  final String? initialValue;
  final EnhancedInputType type;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Widget? leading;
  final Widget? trailing;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final EdgeInsets? contentPadding;
  final BorderRadius? borderRadius;

  const EnhancedInput({
    super.key,
    this.label,
    this.hint,
    this.placeholder,
    this.description,
    this.controller,
    this.initialValue,
    this.type = EnhancedInputType.text,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.textInputAction = TextInputAction.done,
    this.onEditingComplete,
    this.onChanged,
    this.validator,
    this.leading,
    this.trailing,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.borderRadius,
  });

  // Named constructors for different types
  const EnhancedInput.email({
    super.key,
    this.label,
    this.hint,
    this.placeholder,
    this.description,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction = TextInputAction.done,
    this.onEditingComplete,
    this.onChanged,
    this.validator,
    this.leading,
    this.trailing,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.borderRadius,
  })  : type = EnhancedInputType.email,
        maxLines = 1,
        minLines = null,
        maxLength = null;

  const EnhancedInput.password({
    super.key,
    this.label,
    this.hint,
    this.placeholder,
    this.description,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction = TextInputAction.done,
    this.onEditingComplete,
    this.onChanged,
    this.validator,
    this.leading,
    this.trailing,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.borderRadius,
  })  : type = EnhancedInputType.password,
        maxLines = 1,
        minLines = null,
        maxLength = null;

  const EnhancedInput.search({
    super.key,
    this.label,
    this.hint,
    this.placeholder,
    this.description,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction = TextInputAction.search,
    this.onEditingComplete,
    this.onChanged,
    this.validator,
    this.leading,
    this.trailing,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.borderRadius,
  })  : type = EnhancedInputType.search,
        maxLines = 1,
        minLines = null,
        maxLength = null;

  const EnhancedInput.multiline({
    super.key,
    this.label,
    this.hint,
    this.placeholder,
    this.description,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 5,
    this.minLines = 3,
    this.maxLength,
    this.textInputAction = TextInputAction.newline,
    this.onEditingComplete,
    this.onChanged,
    this.validator,
    this.leading,
    this.trailing,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.borderRadius,
  }) : type = EnhancedInputType.multiline;

  @override
  State<EnhancedInput> createState() => _EnhancedInputState();
}

class _EnhancedInputState extends State<EnhancedInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.type == EnhancedInputType.password;

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
        ],
        _buildInputField(context),
        if (widget.description != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: _obscureText,
      maxLines:
          widget.type == EnhancedInputType.multiline ? widget.maxLines : 1,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction,
      keyboardType: _getKeyboardType(),
      inputFormatters: widget.inputFormatters,
      onEditingComplete: widget.onEditingComplete,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.placeholder ?? widget.hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        prefixIcon: widget.leading != null
            ? _buildIconContainer(widget.leading!)
            : _getDefaultLeadingIcon(),
        suffixIcon: _buildSuffixIcon(),
        filled: true,
        fillColor: _getFillColor(colorScheme),
        border: _buildBorder(colorScheme, false, false),
        enabledBorder: _buildBorder(colorScheme, false, false),
        focusedBorder: _buildBorder(colorScheme, true, false),
        errorBorder: _buildBorder(colorScheme, false, true),
        focusedErrorBorder: _buildBorder(colorScheme, true, true),
        contentPadding: widget.contentPadding ??
            (widget.type == EnhancedInputType.multiline
                ? const EdgeInsets.all(16)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        counterText: '', // Hide the default counter
      ),
    );
  }

  Widget? _buildIconContainer(Widget icon) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: icon,
    );
  }

  Widget? _getDefaultLeadingIcon() {
    switch (widget.type) {
      case EnhancedInputType.email:
        return _buildIconContainer(const Icon(Icons.email_outlined, size: 18));
      case EnhancedInputType.password:
        return _buildIconContainer(const Icon(Icons.lock_outline, size: 18));
      case EnhancedInputType.search:
        return _buildIconContainer(const Icon(Icons.search, size: 18));
      case EnhancedInputType.phone:
        return _buildIconContainer(const Icon(Icons.phone_outlined, size: 18));
      default:
        return null;
    }
  }

  Widget? _buildSuffixIcon() {
    final widgets = <Widget>[];

    // Add password visibility toggle
    if (widget.type == EnhancedInputType.password) {
      widgets.add(
        IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      );
    }

    // Add clear button for search
    if (widget.type == EnhancedInputType.search &&
        _controller.text.isNotEmpty) {
      widgets.add(
        IconButton(
          icon: const Icon(Icons.clear, size: 18),
          onPressed: () {
            _controller.clear();
            widget.onChanged?.call('');
          },
        ),
      );
    }

    // Add custom trailing widget
    if (widget.trailing != null) {
      widgets.add(widget.trailing!);
    }

    if (widgets.isEmpty) return null;
    if (widgets.length == 1) return widgets.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Color _getFillColor(ColorScheme colorScheme) {
    if (!widget.enabled) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }
    if (_isFocused) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
    }
    return colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
  }

  OutlineInputBorder _buildBorder(
      ColorScheme colorScheme, bool focused, bool error) {
    Color borderColor;
    double width = 1.0;

    if (error) {
      borderColor = colorScheme.error;
      width = 2.0;
    } else if (focused) {
      borderColor = colorScheme.primary;
      width = 2.0;
    } else {
      borderColor = colorScheme.outline.withValues(alpha: 0.5);
    }

    return OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      borderSide: BorderSide(
        color: borderColor,
        width: width,
      ),
    );
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case EnhancedInputType.email:
        return TextInputType.emailAddress;
      case EnhancedInputType.number:
        return TextInputType.number;
      case EnhancedInputType.phone:
        return TextInputType.phone;
      case EnhancedInputType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }
}

// Form field variant
class EnhancedInputFormField extends FormField<String> {
  EnhancedInputFormField({
    super.key,
    String? label,
    String? hint,
    String? placeholder,
    String? description,
    TextEditingController? controller,
    super.initialValue,
    EnhancedInputType type = EnhancedInputType.text,
    bool enabled = true,
    bool readOnly = false,
    int? maxLines,
    int? minLines,
    int? maxLength,
    TextInputAction textInputAction = TextInputAction.done,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onChanged,
    super.validator,
    Widget? leading,
    Widget? trailing,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    EdgeInsets? contentPadding,
    BorderRadius? borderRadius,
    super.autovalidateMode,
  }) : super(
          builder: (FormFieldState<String> field) {
            final state = field as _EnhancedInputFormFieldState;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                EnhancedInput(
                  label: label,
                  hint: hint,
                  placeholder: placeholder,
                  description: description,
                  controller: state._controller,
                  type: type,
                  enabled: enabled,
                  readOnly: readOnly,
                  maxLines: maxLines,
                  minLines: minLines,
                  maxLength: maxLength,
                  textInputAction: textInputAction,
                  onEditingComplete: onEditingComplete,
                  onChanged: (value) {
                    state.didChange(value);
                    onChanged?.call(value);
                  },
                  leading: leading,
                  trailing: trailing,
                  inputFormatters: inputFormatters,
                  focusNode: focusNode,
                  contentPadding: contentPadding,
                  borderRadius: borderRadius,
                ),
                if (field.hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    field.errorText!,
                    style:
                        Theme.of(field.context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(field.context).colorScheme.error,
                            ),
                  ),
                ],
              ],
            );
          },
        );

  @override
  FormFieldState<String> createState() => _EnhancedInputFormFieldState();
}

class _EnhancedInputFormFieldState extends FormFieldState<String> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    didChange(_controller.text);
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (_controller.text != value) {
      _controller.text = value ?? '';
    }
  }

  @override
  void reset() {
    super.reset();
    _controller.text = widget.initialValue ?? '';
  }
}

// Specialized input variants
class SearchInput extends StatelessWidget {
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final TextEditingController? controller;

  const SearchInput({
    super.key,
    this.placeholder,
    this.onChanged,
    this.onEditingComplete,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedInput.search(
      placeholder: placeholder ?? 'Search...',
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      controller: controller,
    );
  }
}

class LoginInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const LoginInput({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedInputFormField(
      label: label,
      placeholder: hint,
      controller: controller,
      type: isPassword ? EnhancedInputType.password : EnhancedInputType.text,
      validator: validator,
      textInputAction: textInputAction,
    );
  }
}
