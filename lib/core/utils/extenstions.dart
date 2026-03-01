import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pos/core/utils/date_time_utils.dart';

extension DurationFormatter on int {
  String toMinSecond() {
    final minutes = this ~/ 60;
    final seconds = this % 60;

    // Pad minutes and seconds with leading zeros if necessary
    final formattedMinutes = minutes.toString().padLeft(2, '0');
    final formattedSeconds = seconds.toString().padLeft(2, '0');

    return "$formattedMinutes:$formattedSeconds";
  }
}

extension DynamicExtensions on dynamic {
  bool isLocalBytes() {
    return this is List<int> || this is Uint8List;
  }

  bool isNullOrEmpty() {
    return this == null || this?.isEmpty;
  }
}

extension StringExtensions on String? {
  // String capitalize() {
  //   if (this.isEmpty) return this;
  //   return this[0].toUpperCase() + this.substring(1);
  // }
  bool isValidEmail() {
    if (this == null) return false;
    final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');
    if (this!.contains('@')) {
      String localPart = this!.split('@')[0];
      bool isAllLowerCase = RegExp(r'^[a-z0-9._%+-]+$').hasMatch(localPart);
      bool isCapitalThenLower = RegExp(r'^[A-Z][a-z0-9._%+-]*$').hasMatch(localPart);

      return emailRegex.hasMatch(this!) && (isAllLowerCase || isCapitalThenLower);
    }

    return false;
  }

  bool isValidWebsite() {
    // if (this == null || this!.isEmpty) {
    //   return false;
    // }

    // final websiteRegex = RegExp(
    //   r'^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w- .\/?%&=]*)?$',
    //   caseSensitive: false,
    //   multiLine: false,
    // );

    // if (!websiteRegex.hasMatch(this!)) {
    //   return false;
    // }

    // final lowercaseUrl = this!.toLowerCase();

    // // List of valid TLDs
    // final validTlds = [
    //   '.com',
    //   '.org',
    //   '.net',
    //   '.edu',
    //   '.gov',
    //   '.co',
    //   '.in',
    //   '.tech'
    // ];

    // // Check if any valid TLD is present and not followed by numbers
    // for (var tld in validTlds) {
    //   int tldIndex = lowercaseUrl.indexOf(tld);
    //   if (tldIndex != -1) {
    //     // Check if there are any characters after the TLD
    //     if (tldIndex + tld.length < lowercaseUrl.length) {
    //       // Get the character after TLD
    //       String afterTld = lowercaseUrl.substring(tldIndex + tld.length);
    //       // If there's anything after TLD, it should only be a slash or nothing
    //       if (!RegExp(r'^[\/]?$').hasMatch(afterTld)) {
    //         return false;
    //       }
    //     }
    //     return true;
    //   }
    // }

    // return false;
    final RegExp urlRegExp = RegExp(
      r"^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z]{1,63}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$",
      caseSensitive: false,
      multiLine: false,
    );
    return urlRegExp.hasMatch(this ?? '');
  }

  bool isNullOrEmpty() {
    return this == null || this!.isEmpty;
  }

  bool isLocalFile() {
    return this!.startsWith('/') || this!.startsWith('file://');
  }

  String toNumbersOnly() {
    if (isNullOrEmpty()) {
      return "";
    }
    return this!.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String toDateOnly({bool isViewFormat = false}) {
    if (isNullOrEmpty()) {
      return "";
    }

    try {
      DateTime dateAndTime;

      // First try to parse with DateFormat for dd-MM-yyyy format
      try {
        dateAndTime = DateFormat("yyyy-MM-dd HH:mm:ss.SSS").parse(this!);
      } catch (e) {
        // If that fails, try parsing as ISO format
        try {
          dateAndTime = DateTime.parse(this!);
        } catch (e) {
          // If both fail, try parsing as dd-MM-yyyy only
          dateAndTime = DateFormat("dd-MM-yyyy").parse(this!);
        }
      }

      final format = DateFormat(isViewFormat ? defaultDateViewFormat : defaultDateFormat);

      return format.format(dateAndTime);
    } catch (e) {
      print("Date parsing error: $e");
      return "";
    }
  }

  String toTimeOnly({bool showAmPm = false}) {
    if (this == null) return ''; // Handle null safety

    try {
      DateTime dateAndTime = DateFormat("$defaultDateFormat HH:mm").parse("01-01-1990 ${this!}"); //eg="01-01-1990 02:04 PM"

      // Use "h:mm:ss a" for 12-hour format with AM/PM
      // Use "HH:mm:ss" for 24-hour format
      String format = showAmPm ? "h:mm a" : "HH:mm:ss";
      String time = DateFormat(format).format(dateAndTime);

      return time;
    } catch (e) {
      return ''; // Return empty string if parsing fails
    }
  }

  String toTimeAgo() {
    // final year = int.parse(timestamp.substring(0, 4));
    // final month = int.parse(timestamp.substring(5, 7));
    // final day = int.parse(timestamp.substring(8, 10));
    // final hour = int.parse(timestamp.substring(11, 13));
    // final minute = int.parse(timestamp.substring(14, 16));

    final DateTime videoDate = DateTime.parse(this!).toLocal();
    final int diffInHours = DateTime.now().difference(videoDate).inHours;

    String timeAgo = '';
    String timeUnit = '';
    int timeValue = 0;

    if (diffInHours < 1) {
      final diffInMinutes = DateTime.now().difference(videoDate).inMinutes;
      timeValue = diffInMinutes;
      timeUnit = 'minute';
    } else if (diffInHours < 24) {
      timeValue = diffInHours;
      timeUnit = 'hour';
    } else if (diffInHours >= 24 && diffInHours < 24 * 7) {
      timeValue = (diffInHours / 24).floor();
      timeUnit = 'day';
    } else if (diffInHours >= 24 * 7 && diffInHours < 24 * 30) {
      timeValue = (diffInHours / (24 * 7)).floor();
      timeUnit = 'week';
    } else if (diffInHours >= 24 * 30 && diffInHours < 24 * 12 * 30) {
      timeValue = (diffInHours / (24 * 30)).floor();
      timeUnit = 'month';
    } else {
      timeValue = (diffInHours / (24 * 365)).floor();
      timeUnit = 'year';
    }

    timeAgo = '$timeValue $timeUnit';
    timeAgo += timeValue > 1 ? 's' : '';

    return '$timeAgo ago';
  }

  String replaceLeadingZero() {
    if (!isNullOrEmpty()) {
      return this!.replaceAll(RegExp(r'^0+(?=.)'), '');
    } else {
      return "";
    }
  }

  String toServerDateOnly() {
    DateTime dateAndTime = DateTime.parse(this!);
    final DateFormat format;
    format = DateFormat(defaultDateFormat);
    final date = format.format(dateAndTime);
    return date;
  }

  String toTimeWithAmPm() {
    if (isNullOrEmpty() || this == "00:00:00") {
      return "";
    } else {
      DateTime dateAndTime = DateTime.parse("1990-01-01 ${this!}");
      final format = DateFormat('hh:mm a');
      final date = format.format(dateAndTime);
      return date;
    }
  }

  String toDateTimeWithAmPm() {
    if (isNullOrEmpty() || this == "00:00:00") {
      return "";
    } else {
      DateTime dateAndTime = DateTime.parse(this!).toLocal();
      final format = DateFormat('dd-MM-yyyy hh:mm a');
      final date = format.format(dateAndTime);
      return date;
    }
  }

  String toTime24h() {
    try {
      // Parse the timestamp
      DateTime dateTime = DateTime.parse(this!);

      // Format to 24-hour time (HH:mm)
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      throw const FormatException('Invalid timestamp format');
    }
  }
  //
  // String toTime24h() {
  //
  //   DateTime dateAndTime = DateFormat("$defaultDateFormat hh:mm a").parse("01-01-1990 ${this!}");//eg="01-01-1990 02:04 PM"
  //   final format = DateFormat('HH:mm');
  //   final date = format.format(dateAndTime);
  //   return date;
  // }
  // String setIfNullEmpty() {
  //   return this==null?"":this!;
  // }
}

extension IntExtensions on int? {
  bool isNullOrZero() {
    return this == null || this == 0;
  }

  bool isGreaterThanZero() {
    return this != null && this! > 0;
  }

  String setIfNullEmpty() {
    return this == null ? "" : toString();
  }

  int getDaysInMonth(int year, int month) {
    List<int> daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))) {
      return 29; // February in a leap year
    }
    return daysInMonth[month - 1];
  }

  String toYearAndMonth() {
    int years = 0;
    int months = 0;
    int days = 0;
    if (!isNullOrZero()) {
      // Start from a base date
      DateTime startDate = DateTime(1, 1, 1); // Starting from year 1, month 1, day 1

      // Days to be added
      int daysToAdd = this!;

      // Calculate the end date
      DateTime endDate = startDate.add(Duration(days: daysToAdd));

      // Calculate years, months, and days
      years = endDate.year - startDate.year;
      months = endDate.month - startDate.month;
      days = endDate.day - startDate.day;

      if (days < 0) {
        // If days are negative, subtract one month and calculate days again
        months -= 1;
        // Handle month roll-back
        if (months < 0) {
          years -= 1;
          months += 12; // Roll back to December of the previous year
        }
        DateTime daysInPrevMonth = startDate.add(Duration(days: daysToAdd - days));
        days = daysInPrevMonth.day;
      }

      // Correct for the case where endDate.day is less than startDate.day
      if (endDate.day < startDate.day) {
        var tempDate = DateTime(endDate.year, endDate.month, 0); // Last day of the previous month
        days += tempDate.day;
      }
    }

    print("Years: $years, Months: $months, Days: $days");
    return "$years Y $months M $days D ";
  }
}

extension DoubleExtensions on double? {
  bool isNullOrZero() {
    return this == null || this == 0 || this == 0.0;
  }

  bool isGreaterThanZero() {
    return this != null && this! > 0;
  }
}

String formatDateinDdMmYYYY(String dateTimeStr) {
  // Handle ISO format dates first
  try {
    DateTime parsedDateTime = DateTime.parse(dateTimeStr);
    return DateFormat('MMM dd, yyyy hh:mm a').format(parsedDateTime);
  } catch (e) {
    // If not ISO format, proceed with other format handling
  }

  // First, separate date and time if present
  List<String> parts = dateTimeStr.split(':');
  String date = parts[0];
  String time = parts.length > 1 ? '${parts[1]}:${parts[2]}' : '';

  // List of possible date formats in descending priority
  final List<String> possibleFormats = [
    'dd-MM-yyyy', // Example: 19-12-2024
    'yyyy-MM-dd', // Example: 2024-12-19
    'MM/dd/yyyy', // Example: 12/19/2024
    'dd/MM/yyyy', // Example: 19/12/2024
    'dd MMM yyyy', // Example: 19 Dec 2024
    'Entry_Date: dd-MM-yyyy', // Example: Entry_Date: 19-12-2024
  ];

  DateTime? parsedDate;

  // Try parsing the date with each format
  for (var format in possibleFormats) {
    try {
      // Remove any 'Entry_Date: ' prefix if present
      String cleanDate = date.replaceAll('Entry_Date: ', '').trim();
      parsedDate = DateFormat(format).parseStrict(cleanDate);
      break; // Break if successful
    } catch (e) {
      continue; // Try next format if current fails
    }
  }

  if (parsedDate == null) {
    return dateTimeStr; // Return original if parsing fails
  }

  // Format the date part
  String formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate);

  // If time is present, parse and format it
  if (time.isNotEmpty) {
    try {
      List<String> timeParts = time.split(':');
      int hours = int.parse(timeParts[0].trim());
      int minutes = int.parse(timeParts[1].trim());

      // Create DateTime with both date and time
      DateTime dateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hours,
        minutes,
      );

      // Format with both date and time
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      // If time parsing fails, return just the formatted date
      return formattedDate;
    }
  }

  return formattedDate;
}
