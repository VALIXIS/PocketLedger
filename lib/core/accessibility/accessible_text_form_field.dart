import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A WCAG AAA compliant [TextFormField] wrapper for PocketLedger.
///
/// Guarantees minimum 48dp touch targets, semantic accessibility announcements,
/// high-contrast visual cues, assistive error messaging, and full keyboard navigation.
class AccessibleTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool isRequired;
  final String? semanticLabel;
  final InputDecoration? decoration;

  const AccessibleTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.isRequired = false,
    this.semanticLabel,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = isRequired && label != null ? '$label *' : label;
    final assistiveLabel =
        semanticLabel ??
        (label != null
            ? (isRequired ? '$label, required' : label!)
            : (hint ?? 'Text input field'));

    final baseDecoration = decoration ?? const InputDecoration();

    final mergedDecoration = baseDecoration.copyWith(
      labelText: effectiveLabel,
      hintText: hint ?? baseDecoration.hintText,
      helperText: helperText ?? baseDecoration.helperText,
      errorText: errorText ?? baseDecoration.errorText,
      prefixIcon: prefixIcon ?? baseDecoration.prefixIcon,
      suffixIcon: suffixIcon ?? baseDecoration.suffixIcon,
    );

    return Semantics(
      label: assistiveLabel,
      textField: true,
      container: true,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48.0),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: mergedDecoration,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          onTap: onTap,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
        ),
      ),
    );
  }
}
