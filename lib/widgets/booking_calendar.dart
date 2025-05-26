import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingCalendar extends StatefulWidget {
  final Set<DateTime> bookedDates;
  final void Function(DateTime?, DateTime?) onRangeSelected;

  const BookingCalendar({
    Key? key,
    required this.bookedDates,
    required this.onRangeSelected,
  }) : super(key: key);

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  bool _isDateDisabled(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return widget.bookedDates.contains(d);
  }

  bool _isWithinBookedRange(DateTime day) {
    return widget.bookedDates.any((booked) =>
    day.isAtSameMomentAs(booked) || (day.isAfter(booked) && day.isBefore(booked.add(const Duration(days: 1)))));
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) =>
      _rangeStart != null && _rangeEnd != null && day.isAfter(_rangeStart!.subtract(const Duration(days: 1))) && day.isBefore(_rangeEnd!.add(const Duration(days: 1))),
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      rangeSelectionMode: _rangeSelectionMode,
      onDaySelected: (selectedDay, focusedDay) {
        if (_isDateDisabled(selectedDay)) return;

        if (_rangeStart != null &&
            _rangeSelectionMode == RangeSelectionMode.toggledOn &&
            !selectedDay.isBefore(_rangeStart!)) {
          // Valid range selection
          setState(() {
            _rangeEnd = selectedDay;
            _rangeSelectionMode = RangeSelectionMode.toggledOff;
          });
          widget.onRangeSelected(_rangeStart, _rangeEnd);
        } else {
          // Start new selection
          setState(() {
            _rangeStart = selectedDay;
            _rangeEnd = null;
            _rangeSelectionMode = RangeSelectionMode.toggledOn;
          });
          widget.onRangeSelected(_rangeStart, null);
        }
        _focusedDay = focusedDay;
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        rangeStartBuilder: (context, day, _) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        },
        rangeEndBuilder: (context, day, _) {
          // Similar to rangeStartBuilder
        },
        rangeHighlightBuilder: (context, day, isWithinRange) {
          if (isWithinRange) {
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }
          return null;
        },
        disabledBuilder: (context, day, _) {
          return Center(
            child: Text(
              '${day.day}',
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
      enabledDayPredicate: (day) => !_isDateDisabled(day),
    );
  }
}
