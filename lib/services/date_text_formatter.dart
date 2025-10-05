import 'package:flutter/services.dart';

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText == oldValue.text.replaceAll(RegExp(r'[^0-9]'), '')) {
      return newValue;
    }

    final truncatedText = (newText.length > 8)
        ? newText.substring(0, 8)
        : newText;

    var formattedText = '';
    if (truncatedText.length > 4) {
      formattedText =
          '${truncatedText.substring(0, 2)}/${truncatedText.substring(2, 4)}/${truncatedText.substring(4)}';
    } else if (truncatedText.length > 2) {
      formattedText =
          '${truncatedText.substring(0, 2)}/${truncatedText.substring(2)}';
    } else {
      formattedText = truncatedText;
    }

    int selectionIndex =
        newValue.selection.end + (formattedText.length - newValue.text.length);

    if (selectionIndex < 0) selectionIndex = 0;
    if (selectionIndex > formattedText.length) {
      selectionIndex = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
