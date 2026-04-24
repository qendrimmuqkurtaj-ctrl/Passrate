import 'package:flutter/services.dart';

extension StringExtensions on String {
  /// [toCapitalize] convert each word to Capitalize for a string
  String get toCapitalize => isEmpty ? this :
      split(' ').map((String word) => word.isNotEmpty
      ?
      word[0].toUpperCase() + word.substring(1).toLowerCase()
      :
      ''
      ).join(' ');

  String get wordByNewLine => splitMapJoin(
    RegExp(r' '),
    onMatch: (Match m) => '\n',
    onNonMatch: (String n) => n,
  );

  String get toCamelCase => split(" ").map((String word) => word.toCapitalize).join("");

  bool get isNumeric => double.tryParse(this) != null;

  bool get isValidUrl => Uri.tryParse(this)?.hasAbsolutePath ?? false;

  String removeSpaces() => replaceAll(' ', '');

  bool isValidEmail() => RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(this);

  Future<void> get copyToClipboard async => await Clipboard.setData(ClipboardData(text: this));
}
