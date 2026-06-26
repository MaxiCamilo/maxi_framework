import 'package:maxi_framework/maxi_framework.dart';

extension DateExtensions on DateTime {
  String toFormalText({bool useShortDays = false, bool insertDayOfWeek = true, bool insertYear = true, bool useShortYear = false, bool insertHourAndMinutes = false, bool insertSeconds = false, bool insertDate = true}) {
    final buffer = StringBuffer();

    final date = isUtc ? toLocal() : this;

    if (insertDate) {
      if (insertDayOfWeek) {
        switch (date.weekday) {
          case DateTime.monday:
            buffer.write(useShortDays ? const FixedOration(tokenID: 'short-monday', message: 'Mon').translateText() : const FixedOration(message: 'Monday').translateText());
            break;
          case DateTime.tuesday:
            buffer.write(useShortDays ? const FixedOration(tokenID: 'short-tuesday', message: 'Tue').translateText() : const FixedOration(message: 'Tuesday').translateText());
            break;
          case DateTime.wednesday:
            buffer.write(useShortDays ? const FixedOration(tokenID: 'short-wednesday', message: 'Wed').translateText() : const FixedOration(message: 'Wednesday').translateText());
            break;
          case DateTime.thursday:
            buffer.write(useShortDays ? const FixedOration(tokenID: 'short-thursday', message: 'Thu').translateText() : const FixedOration(message: 'Thursday').translateText());
            break;
          case DateTime.friday:
            buffer.write(useShortDays ? const FixedOration(tokenID: 'short-friday', message: 'Fri').translateText() : const FixedOration(message: 'Friday').translateText());
            break;
          case DateTime.saturday:
            buffer.write(useShortDays ? const FixedOration(tokenID: 'short-saturday', message: 'Sat').translateText() : const FixedOration(message: 'Saturday').translateText());
            break;
          case DateTime.sunday:
            buffer.write(useShortDays ? const FixedOration(tokenID: 'short-sunday', message: 'Sun').translateText() : const FixedOration(message: 'Sunday').translateText());
            break;
        }

        buffer.write(' ');
      }

      buffer.write(date.day.toString().padLeft(2, '0'));
      buffer.write('/');
      buffer.write(date.month.toString().padLeft(2, '0'));

      if (insertYear) {
        buffer.write('/');
        buffer.write(useShortYear ? date.year.toString().substring(2) : date.year.toString());
      }
    }

    if (insertHourAndMinutes) {
      if (insertDate) {
        buffer.write(' ');
      }
      buffer.write(date.hour.toString().padLeft(2, '0'));
      buffer.write(':');
      buffer.write(date.minute.toString().padLeft(2, '0'));

      if (insertSeconds) {
        buffer.write(':');
        buffer.write(date.second.toString().padLeft(2, '0'));
      }
    }
    return buffer.toString();
  }
}
