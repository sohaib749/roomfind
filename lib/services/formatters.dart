import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll('-', '');
    if (text.length > 13) return oldValue;

    String formattedText = text;
    if (text.length > 5) {
      formattedText = '${text.substring(0, 5)}-${text.substring(5)}';
    }
    if (text.length > 12) {
      formattedText = '${formattedText.substring(0, 13)}-${formattedText.substring(13)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}