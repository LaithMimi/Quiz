import 'package:flutter/material.dart';

InputDecoration fieldDecoration({
  required String label,
  required String hint,
  required IconData prefix,
  Widget? suffix,
  String? error,
}) {
  return InputDecoration(
    prefixIcon: Icon(prefix),
    suffixIcon: suffix,
    labelText: label,
    hintText: hint,
    errorText: error,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
