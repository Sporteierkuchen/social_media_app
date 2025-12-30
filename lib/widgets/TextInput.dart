import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TextInput extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController controller;

  /// Icon flexibel (Icon, Image, etc.)
  final Widget? prefixIcon;

  // Optionales Verhalten
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final int? maxLength;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  // -------------------------
  // 🎨 Styling (mit Defaults)
  // -------------------------
  final Color cursorColor;

  final Color textColor;
  final Color labelColor;
  final Color hintColor;
  final Color iconColor;

  final Color fillColor;

  final Color enabledBorderColor;
  final Color focusedBorderColor;
  final Color errorBorderColor;

  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry contentPadding;

  const TextInput({
    super.key,
    required this.label,
    required this.obscureText,
    required this.controller,
    this.prefixIcon,

    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,

    // ✅ Defaults: neutral/hell (passt überall, auch bisher)
    this.cursorColor = AppColors.primary,

    this.textColor = Colors.black,
    this.labelColor = const Color(0xFF777777),
    this.hintColor = const Color(0xFF999999),
    this.iconColor = const Color(0xFF777777),

    this.fillColor = const Color(0xFFE6E6E6),

    this.enabledBorderColor = const Color(0xFFCCCCCC),
    this.focusedBorderColor = AppColors.primary,
    this.errorBorderColor = Colors.redAccent,

    this.borderRadius = 12,
    this.borderWidth = 1.5,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final borderEnabled = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: enabledBorderColor, width: borderWidth),
    );

    final borderFocused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: focusedBorderColor, width: borderWidth),
    );

    final borderError = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: errorBorderColor, width: borderWidth),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      cursorColor: cursorColor,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
      ),
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        counterText: maxLength != null ? "" : null,
        prefixIcon: prefixIcon == null
            ? null
            : IconTheme(
          data: IconThemeData(color: iconColor),
          child: prefixIcon!,
        ),
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        contentPadding: contentPadding,
        enabledBorder: borderEnabled,
        focusedBorder: borderFocused,
        errorBorder: borderError,
        focusedErrorBorder: borderError,
      ),
    );
  }
}
