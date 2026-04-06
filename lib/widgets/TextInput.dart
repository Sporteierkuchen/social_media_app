import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TextInput extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController controller;

  final Widget? prefixIcon;

  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final int? maxLength;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

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

    // Dunkles UI als Standard
    this.cursorColor = AppColors.primary,

    this.textColor = Colors.white,
    this.labelColor = const Color(0xFFBDBDBD),
    this.hintColor = const Color(0xFF8F8F8F),
    this.iconColor = const Color(0xFFD0D0D0),

    this.fillColor = const Color(0xFF222222),

    this.enabledBorderColor = const Color(0xFF3A3A3A),
    this.focusedBorderColor = AppColors.primary,
    this.errorBorderColor = Colors.redAccent,

    this.borderRadius = 14,
    this.borderWidth = 1.4,
    this.contentPadding =
    const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
  });

  @override
  Widget build(BuildContext context) {
    final borderEnabled = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: enabledBorderColor,
        width: borderWidth,
      ),
    );

    final borderFocused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: focusedBorderColor,
        width: borderWidth,
      ),
    );

    final borderError = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: errorBorderColor,
        width: borderWidth,
      ),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      cursorColor: cursorColor,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        height: 1.2,
      ),
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        counterText: maxLength != null ? "" : null,
        labelText: label,
        labelStyle: TextStyle(
          color: labelColor,
          fontSize: 15,
        ),
        floatingLabelStyle: TextStyle(
          color: focusedBorderColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 15,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: contentPadding,

        prefixIcon: prefixIcon == null
            ? null
            : Padding(
          padding: const EdgeInsets.only(left: 10, right: 4),
          child: IconTheme(
            data: IconThemeData(
              color: iconColor,
              size: 20,
            ),
            child: prefixIcon!,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),

        enabledBorder: borderEnabled,
        focusedBorder: borderFocused,
        errorBorder: borderError,
        focusedErrorBorder: borderError,
      ),
    );
  }
}