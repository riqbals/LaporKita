import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Input field reusable dengan gaya border dan validasi konsisten.
/// Mendukung toggle visibility otomatis jika [isPassword] bernilai true.
class CustomInput extends StatefulWidget {
  const CustomInput({
    super.key,
    required this.hintText,
    this.controller,
    this.labelText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String hintText;
  final String? labelText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final int maxLines;
  final int? maxLength;
  final bool enabled;

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 20)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}

