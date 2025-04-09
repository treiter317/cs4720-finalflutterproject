import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;

  const TextFieldWidget({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: isPassword ? Icon(Icons.visibility_off) : null,
      ),
    );
  }
}
