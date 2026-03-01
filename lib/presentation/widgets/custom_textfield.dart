import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/constants/colors.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.hintFontSize,
    this.labelText,
    this.showAsUpperLabel,
    this.margin,
    this.textInputAction,
    this.focusNode,
    this.onChanged,
    this.obscureText = false,
    this.onTap,
    this.onSubmitted,
    this.keyBoardType,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.changeColor,
    this.fillColor,
    this.readOnly = false,
    this.enabled = true,
    this.autofillHints,
    this.onIconTap,
    this.suffixIcon,
    this.suffix,
    this.validator,
    this.maxLength,
    this.inputFormatters,
    this.textColor,
    this.maxLines = 1,
    this.minLines = 1,
    this.counterText,
    this.textAlign,
    this.prefixIcon,
    this.prefix,
    this.contentPadding,
  })  : assert(
          maxLines == null || maxLines > 0,
          'maxLines must be greater than 0',
        ),
        assert(
          minLines == null || minLines > 0,
          'minLines must be greater than 0',
        ),
        assert(
          maxLines == null || minLines == null || maxLines >= minLines,
          'maxLines must be greater than or equal to minLines',
        );

  final TextEditingController? controller;
  final EdgeInsetsGeometry? margin;
  final TextInputAction? textInputAction;
  final double? hintFontSize;
  final String? labelText;
  final bool? showAsUpperLabel;
  final String? counterText;
  final Color? fillColor;
  final FocusNode? focusNode;
  final bool? obscureText;
  final void Function(String value)? onChanged;
  final void Function(String value)? onSubmitted;
  final void Function()? onTap;
  final TextInputType? keyBoardType;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final bool? changeColor;
  final bool? readOnly;
  final bool? enabled;
  final Iterable<String>? autofillHints;
  final void Function()? onIconTap;
  final Widget? suffixIcon;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? prefix;
  final String? Function(String? value)? validator;
  final int? maxLength;
  final Color? textColor;
  final int? maxLines;
  final int? minLines;
  final TextAlign? textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  FocusNode? _internalFocusNode;
  TextEditingController? _internalController;
  bool _hasFocus = false;

  // Getters for effective instances
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;
  TextEditingController get _effectiveController => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();

    // Create internal instances only if not provided by parent
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    if (widget.controller == null) {
      _internalController = TextEditingController();
    }

    // Add focus listener to track focus state for border styling
    _effectiveFocusNode.addListener(_onFocusChange);
    _hasFocus = _effectiveFocusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle focus node changes
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode != null) {
        oldWidget.focusNode?.removeListener(_onFocusChange);
      } else {
        _internalFocusNode?.removeListener(_onFocusChange);
      }

      if (widget.focusNode == null && _internalFocusNode == null) {
        _internalFocusNode = FocusNode();
      } else if (widget.focusNode != null && _internalFocusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }

      _effectiveFocusNode.addListener(_onFocusChange);
      _hasFocus = _effectiveFocusNode.hasFocus;
    }

    // Handle controller changes
    if (oldWidget.controller != widget.controller) {
      if (widget.controller == null && _internalController == null) {
        _internalController = TextEditingController();
      } else if (widget.controller != null && _internalController != null) {
        _internalController?.dispose();
        _internalController = null;
      }
    }
  }

  void _onFocusChange() {
    if (mounted && _hasFocus != _effectiveFocusNode.hasFocus) {
      setState(() {
        _hasFocus = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    try {
      // Remove listener from effective focus node
      _effectiveFocusNode.removeListener(_onFocusChange);

      // Dispose internal instances only
      _internalFocusNode?.dispose();
      _internalController?.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('CustomTextField dispose error: $e');
      }
    }
    super.dispose();
  }

  Color _getBorderColor(BuildContext context) {
    if (widget.errorText != null) {
      return Theme.of(context).colorScheme.error;
    }
    if (_hasFocus) {
      return Theme.of(context).primaryColor;
    }
    return Theme.of(context).dividerColor.withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveHintFontSize = widget.hintFontSize ?? 14.0;

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1.5,
          color: _getBorderColor(context),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Center(child: widget.prefixIcon!),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showAsUpperLabel == true && widget.labelText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
                      child: Text(
                        widget.labelText!,
                        style: TextStyle(
                          fontSize: effectiveHintFontSize - 2,
                          color: AppColors.hintFontColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  TextFormField(
                    onTapOutside: (event) => _hideKeyboard(),
                    autofillHints: widget.autofillHints,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly ?? false,
                    controller: _effectiveController,
                    focusNode: _effectiveFocusNode,
                    textInputAction: widget.textInputAction,
                    obscureText: widget.obscureText ?? false,
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                    onFieldSubmitted: widget.onSubmitted,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    onTap: widget.onTap,
                    keyboardType: widget.keyBoardType,
                    textCapitalization: widget.textCapitalization,
                    cursorColor: theme.primaryColor,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.textColor ?? AppColors.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: widget.textAlign ?? TextAlign.start,
                    decoration: InputDecoration(
                      labelStyle: TextStyle(
                        color: AppColors.hintFontColor,
                        fontSize: effectiveHintFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                      filled: false,
                      hintText: widget.showAsUpperLabel == true ? null : widget.labelText,
                      counterText: widget.counterText,
                      fillColor: widget.fillColor ?? theme.cardColor,
                      hintStyle: TextStyle(
                        color: AppColors.hintFontColor,
                        fontSize: effectiveHintFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                      isDense: true,
                      isCollapsed: true,
                      contentPadding: widget.contentPadding ??
                          EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: widget.showAsUpperLabel == true ? 8 : 13,
                          ),
                      suffix: widget.suffix,
                      prefix: widget.prefix,
                      errorText: widget.errorText,
                      errorStyle: const TextStyle(
                        fontSize: 10,
                        height: 1,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: widget.validator,
                    maxLength: widget.maxLength,
                  ),
                ],
              ),
            ),
            if (widget.suffixIcon != null)
              GestureDetector(
                onTap: widget.onIconTap,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Center(child: widget.suffixIcon!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
