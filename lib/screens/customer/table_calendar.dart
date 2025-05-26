//table_calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarDialog extends StatefulWidget {
  final List<DateTime> unavailableDates;
  final Function(DateTime start, DateTime end) onDateRangeSelected;

  const CalendarDialog({
    required this.unavailableDates,
    required this.onDateRangeSelected,
    Key? key,
  }) : super(key: key);

  @override
  _CalendarDialogState createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  bool _isUnavailable(DateTime day) {
    return widget.unavailableDates.any((d) =>
    d.year == day.year && d.month == day.month && d.day == day.day);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Booking Range'),
      content: SizedBox(
        height: 400,
        width: 300,
        child: TableCalendar(
          focusedDay: _focusedDay,
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          calendarFormat: CalendarFormat.month,
          rangeSelectionMode: _rangeSelectionMode,
          onDaySelected: (selectedDay, focusedDay) {
            if (_isUnavailable(selectedDay)) return;

            setState(() {
              _focusedDay = focusedDay;
              if (_rangeSelectionMode == RangeSelectionMode.toggledOn &&
                  _rangeStart != null &&
                  _rangeEnd == null &&
                  selectedDay.isAfter(_rangeStart!)) {
                _rangeEnd = selectedDay;
                widget.onDateRangeSelected(_rangeStart!, _rangeEnd!);
                Navigator.pop(context);
              } else {
                _rangeStart = selectedDay;
                _rangeEnd = null;
                _rangeSelectionMode = RangeSelectionMode.toggledOn;
              }
            });
          },
          enabledDayPredicate: (day) => !_isUnavailable(day),
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            rangeStartDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            rangeEndDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            withinRangeDecoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            disabledBuilder: (context, day, focusedDay) {
              return Center(
                child: Text(
                  '${day.day}',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}