import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/utils/extenstions.dart';

String defaultDateFormat = "yyyy-MM-dd";
String defaultDateViewFormat = 'MMM d, yyyy';
String yearMonthMask = "00 yr 00 mo 00 dy";
String getAmPmTimeFromTimeOfDay(TimeOfDay timeOfDay) {
  final now = DateTime.now();
  final dateTime = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);

  final format = DateFormat('hh:mm a');
  final amPm = format.format(dateTime);

  return amPm;
}

class DateTimeUtils {
  static Duration getDurationBetweenTime(String startTime, String endTime) {
    Duration duration = const Duration(seconds: 0);
    if (startTime.isNotEmpty && endTime.isNotEmpty && isTimeFormat(startTime) && isTimeFormat(endTime)) {
      var format = DateFormat("yyyy-MM-dd hh:mm a");
      var one = format.parse("${DateTime.now().toString().split(" ")[0]} $startTime");
      var two = format.parse("${DateTime.now().toString().split(" ")[0]} $endTime");
      duration = two.difference(one);
    }
    return duration;
  }

  static String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '$hours h $minutes m';
  }

  static bool isTimeFormat(String time) {
    try {
      DateFormat("dd-MM-yyyy hh:mm a").parse("${DateTime.now().toString().toDateOnly()} $time");
      return true;
    } catch (e) {
      return false;
    }
  }

  static String getDayFromDate(String date, {bool showFullDayName = false, bool showIsToday = true}) {
    String dayName = "";
    if (!date.isNullOrEmpty()) {
      if (showFullDayName) {
        dayName = (showIsToday && date.toDateOnly() == DateTime.now().toString().toDateOnly()) ? "Today" : DateFormat("EEEE").format(DateTime.parse(date));
      } else {
        dayName = (showIsToday && date.toDateOnly() == DateTime.now().toString().toDateOnly()) ? "Today" : DateFormat("E").format(DateTime.parse(date));
      }
    }

    return dayName;
  }

  static DateTime? getMaxDateFromList(List<String> dateStrings) {
    if (dateStrings.isEmpty) {
      // Return null or a default value if the list is empty
      return null;
    }

    List<DateTime> dateTimes = dateStrings.map((dateString) => DateFormat(defaultDateViewFormat).parse(dateString)).toList();

    return dateTimes.reduce((maxDate, date) => date.isAfter(maxDate) ? date : maxDate);
  }

  static (List<String>, List<DateTime>) getDatesBetweenTwoDates(DateTime startDate, DateTime endDate) {
    List<String> dates = [];
    List<DateTime> dateTime = [];
    for (var i = startDate; i.isBefore(endDate) || i.isAtSameMomentAs(endDate); i = i.add(const Duration(days: 1))) {
      dates.add(i.toString().toServerDateOnly());
      dateTime.add(i);
    }
    return (dates, dateTime);
  }

  int timeToSeconds(String timeString) {
    List<String> parts = timeString.split(':');
    if (parts.length == 3) {
      try {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);

        return hours * 3600 + minutes * 60 + seconds;
      } catch (e) {
        // Handle parsing errors, if any.
      }
    }

    // Return a default value or an error indicator as needed.
    return -1; // You can choose your own error indicator.
  }

  static DateTime getFromDate(int? calenderType) {
    // calenderType 1 = day
    // calenderType 2 = week
    // calenderType 3 = month
    // calenderType 4 = year

    DateTime lastDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 0);
    DateTime lastYear = DateTime(DateTime.now().year, 1, 0);

    if (calenderType == 1) {
      DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return today;
    } else if (calenderType == 2) {
      DateTime weekDate = DateTime.now().subtract(const Duration(days: 7));

      if (lastDayOfMonth.isBefore(weekDate)) {
        return weekDate;
      } else {
        return lastDayOfMonth.add(const Duration(days: 1));
      }
    } else if (calenderType == 3) {
      int totalDays = DateTimeRange(start: DateTime(DateTime.now().year, DateTime.now().month, 1), end: DateTime(DateTime.now().year, DateTime.now().month + 1)).duration.inDays;

      DateTime monthDate = DateTime.now().subtract(Duration(days: totalDays));

      if (lastDayOfMonth.isBefore(monthDate)) {
        return monthDate;
      } else {
        return lastDayOfMonth.add(const Duration(days: 1));
      }
    } else if (calenderType == 4) {
      int totalDays = DateTimeRange(start: DateTime(DateTime.now().year, 1, 1), end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).duration.inDays;

      DateTime yearDate = DateTime.now().subtract(Duration(days: totalDays));

      if (lastYear.isBefore(yearDate)) {
        return yearDate;
      } else {
        return lastYear.add(const Duration(days: 1));
      }
    } else {
      return DateTime.now();
    }
  }

  static List<String> generateTime(DateTime startDate, DateTime endDate, int interva) {
    Duration step = Duration(seconds: interva);

    List<String> timeSlots = [];
    timeSlots.add(DateFormat("hh:mm a").format(startDate));
    while (startDate.millisecondsSinceEpoch < (endDate.millisecondsSinceEpoch)) {
      DateTime timeIncrement = startDate.add(step);
      timeSlots.add(DateFormat("hh:mm a").format(timeIncrement));
      startDate = timeIncrement;
    }
    return timeSlots;
  }

  static (int year, int month, int day) getYearAndMonthFromDays(int totaldays) {
    // DateTime minDateTime = DateTime(1900);
    // DateTime maxDateTime = DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day);
    // int years = 0;
    // int months = 0;
    // int days = 0;
    // DateTime dateTime = DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day).subtract(Duration(days: totaldays));
    //
    // if (dateTime.isAfter(minDateTime) && dateTime.isBefore(maxDateTime)) {
    //
    //   DateTime startDate=DateFormat(defaultDateFormat).parse(DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day).subtract(Duration(days: totaldays)).toString());
    //   DateTime endDate=DateFormat(defaultDateFormat).parse(DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day).toString());
    //   if (startDate.isAfter(endDate)) {
    //     final temp = startDate;
    //     startDate = endDate;
    //     endDate = temp;
    //   }
    //
    //   years = endDate.year - startDate.year;
    //   months = endDate.month - startDate.month;
    //   days = endDate.day - startDate.day;
    //
    //   if (days < 0) {
    //     months--;
    //     days += DateTime(startDate.year, startDate.month + 1, 0).day;
    //   }
    //   // if (days < 0) {
    //   //   days =0;
    //   // }
    //
    //   if (months < 0) {
    //     years--;
    //     months += 12;
    //   }
    //
    //   // print(years.toString()+"-"+months.toString()+"-"+days.toString()+"----");
    // }

    DateTime startDate = DateTime(1, 1, 1); // Starting from year 1, month 1, day 1

    // Days to be added
    int daysToAdd = totaldays;

    // Calculate the end date
    DateTime endDate = startDate.add(Duration(days: daysToAdd));

    // Calculate years, months, and days
    int years = endDate.year - startDate.year;
    int months = endDate.month - startDate.month;
    int days = endDate.day - startDate.day;

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
    return (years, months, days);
  }

  static String getDateFromDays(int totalDays) {
    String date = DateTime.now().subtract(Duration(days: totalDays)).toString().split(" ")[0];

    return date;
  }

  static int getDaysFromDate(String date) {
    int days = DateTime.now().difference(DateTime.parse(date)).inDays;

    return days;
  }

  static int yearsMonthsToDays(String yr, String mon, String day) {
    int years = int.tryParse(yr) ?? 0;
    int months = int.tryParse(mon) ?? 0;
    int days = int.tryParse(day) ?? 0;

    // Define the number of days in a non-leap year and a leap year
    const daysInYear = 365;

    // // Define the number of days in each month
    final daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    // Calculate the number of days in the years
    int totalDays = years * daysInYear;

    // If there are any months, add the days for those months
    if (months > 0) {
      // Check if the current year is a leap year
      bool isLeapYear = DateTime.now().year % 4 == 0;

      // Calculate the days in the partial year
      for (int i = 0; i < months; i++) {
        totalDays += daysInMonth[i];
        if (isLeapYear && i == 1) {
          totalDays++; // Add an extra day for February in a leap year
        }
      }
    }

    // Add the days to the total
    totalDays += days;
    final dateTime = DateTime.now().difference(DateTime(DateTime.now().year - years, DateTime.now().month - months, DateTime.now().day - days)).inDays;
    // print(dateTime.year.toString()+"-"+dateTime.month.toString()+"-"+dateTime.day.toString()+"----");
    return dateTime;
  }
// static int yearsMonthsToDays(String yr, String mon) {
//
//   int years=int.tryParse(yr)??0;
//   int months=int.tryParse(mon)??0;
//   // Define the number of days in a non-leap year and a leap year
//   final daysInYear = 365;
//   final daysInLeapYear = 366;
//
//   // Define the number of days in each month
//   final daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
//
//   // Calculate the number of days in the years
//   int totalDays = years * daysInYear;
//
//   // If there are any months, add the days for those months
//   if (months > 0) {
//     // Check if the current year is a leap year
//     bool isLeapYear = DateTime.now().year % 4 == 0 &&
//         (DateTime.now().year % 100 != 0 || DateTime.now().year % 400 == 0);
//
//     // Calculate the days in the partial year
//     for (int i = 0; i < months; i++) {
//       totalDays += daysInMonth[i];
//       if (isLeapYear && i == 1) {
//         totalDays++; // Add an extra day for February in a leap year
//       }
//     }
//   }
//
//   return totalDays;
// }
}

class TimeTextInputFormatter extends TextInputFormatter {
  RegExp _exp = RegExp(r'^[0-9:]+$');
  TimeTextInputFormatter() {
    _exp = RegExp(r'^[0-9:]+$');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_exp.hasMatch(newValue.text)) {
      TextSelection newSelection = newValue.selection;

      String value = newValue.text;
      String newText;

      String leftChunk = '';
      String rightChunk = '';

      if (value.length >= 8) {
        if (value.substring(0, 7) == '00:00:0') {
          leftChunk = '00:00:';
          rightChunk = value.substring(leftChunk.length + 1, value.length);
        } else if (value.substring(0, 6) == '00:00:') {
          leftChunk = '00:0';
          rightChunk = "${value.substring(6, 7)}:${value.substring(7)}";
        } else if (value.substring(0, 4) == '00:0') {
          leftChunk = '00:';
          rightChunk = "${value.substring(4, 5)}${value.substring(6, 7)}:${value.substring(7)}";
        } else if (value.substring(0, 3) == '00:') {
          leftChunk = '0';
          rightChunk = "${value.substring(3, 4)}:${value.substring(4, 5)}${value.substring(6, 7)}:${value.substring(7, 8)}${value.substring(8)}";
        } else {
          leftChunk = '';
          rightChunk = "${value.substring(1, 2)}${value.substring(3, 4)}:${value.substring(4, 5)}${value.substring(6, 7)}:${value.substring(7)}";
        }
      } else if (value.length == 7) {
        if (value.substring(0, 7) == '00:00:0') {
          leftChunk = '';
          rightChunk = '';
        } else if (value.substring(0, 6) == '00:00:') {
          leftChunk = '00:00:0';
          rightChunk = value.substring(6, 7);
        } else if (value.substring(0, 1) == '0') {
          leftChunk = '00:';
          rightChunk = "${value.substring(1, 2)}${value.substring(3, 4)}:${value.substring(4, 5)}${value.substring(6, 7)}";
        } else {
          leftChunk = '';
          rightChunk = "${value.substring(1, 2)}${value.substring(3, 4)}:${value.substring(4, 5)}${value.substring(6, 7)}:${value.substring(7)}";
        }
      } else {
        leftChunk = '00:00:0';
        rightChunk = value;
      }

      if (oldValue.text.isNotEmpty && oldValue.text.substring(0, 1) != '0') {
        if (value.length > 7) {
          return oldValue;
        } else {
          leftChunk = '0';
          rightChunk = "${value.substring(0, 1)}:${value.substring(1, 2)}${value.substring(3, 4)}:${value.substring(4, 5)}${value.substring(6, 7)}";
        }
      }

      newText = leftChunk + rightChunk;

      newSelection = newValue.selection.copyWith(
        baseOffset: math.min(newText.length, newText.length),
        extentOffset: math.min(newText.length, newText.length),
      );

      return TextEditingValue(
        text: newText,
        selection: newSelection,
        composing: TextRange.empty,
      );
    }
    return oldValue;
  }
}
