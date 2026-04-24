 import 'package:flutter/material.dart';
import 'package:pass_rate/core/extensions/date_time_extensions.dart';

class DatePickerUtils {
  DatePickerUtils._();

  static Future<String?> pickFormatedDate({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final DateTime now = DateTime.now();

    final DateTime? dateTime =  await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(now.year - 100),
      lastDate: lastDate ?? DateTime(now.year + 10),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, 
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    return dateTime?.formattedDate;
  }

}