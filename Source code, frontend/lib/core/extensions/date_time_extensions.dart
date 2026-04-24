import 'package:intl/intl.dart';

import '../config/app_strings.dart';

extension DateTimeExtensions on DateTime {
  String toFormattedString() => "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year";

  int get age => DateTime.now().year - year;

  String get formattedDate => DateFormat('yyyy-MM-dd').format(this);

  String get formattedTime => DateFormat('HH:mm:ss').format(this);

  String get formattedMonthYear => DateFormat('MMM yyyy').format(this);

  String get formattedDateTime => DateFormat('yyyy-MM-dd HH:mm:ss').format(this);

  String get formattedDateTime12 => DateFormat('MMM d, yyyy  h:mm a').format(this);

  bool get isExpired => isBefore(DateTime.now().toUtc());


  bool get isValid => !isExpired;

  String get timeAgo {
    final Duration difference = DateTime.now().difference(this);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} ${AppStrings.secondsAgo}';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${AppStrings.minutesAgo}';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} ${AppStrings.hoursAgo}';
    }
    return '${difference.inDays} ${AppStrings.daysAgo}';
  }
}
