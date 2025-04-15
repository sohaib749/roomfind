import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:roomfind/providers/hotel_provider.dart';

class OnlineBookingDialog extends StatefulWidget {
  final HotelProvider hotelProvider;
  final Map<String, dynamic> room;

  const OnlineBookingDialog({
    required this.hotelProvider,
    required this.room,
    super.key,
  });

  @override
  _OnlineBookingDialogState createState() => _OnlineBookingDialogState();
}

class _OnlineBookingDialogState extends State<OnlineBookingDialog> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int _nights = 1;
  final _formKey = GlobalKey<FormState>();
  List<DateTime> _unavailableDates = [];
  bool _isLoading = true;

  // Guest details controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'Credit Card';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadUnavailableDates();
  }

  Future<void> _loadUnavailableDates() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await widget.hotelProvider.getBookingsForDateRange(
        widget.room['roomId'],
        DateTime.now(),
        DateTime.now().add(Duration(days: 365)),
      );

      _unavailableDates = bookings.expand((booking) {
        final start = booking['startDate'] as DateTime;
        final end = booking['endDate'] as DateTime;
        final dates = <DateTime>[];
        for (var date = start; date.isBefore(end.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
          dates.add(date);
        }
        return dates;
      }).toList();
    } catch (e) {
      print('Error loading unavailable dates: $e');
    }
    setState(() => _isLoading = false);
  }

  bool _isDateUnavailable(DateTime date) {
    return _unavailableDates.any((unavailable) =>
        isSameDay(unavailable, date));
  }

  bool _hasUnavailableInRange(DateTime start, DateTime end) {
    for (var date = start; date.isBefore(end.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      if (_isDateUnavailable(date)) return true;
    }
    return false;
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select valid dates')),
      );
      return;
    }

    try {
      // Get hotelId directly from room data
      final hotelId = widget.room['hotelId'];
      if (hotelId == null || hotelId.isEmpty) {
        throw Exception('Room is not associated with any hotel');
      }

      final isAvailable = await widget.hotelProvider.isRoomAvailable(
          widget.room['roomId'],
          _rangeStart!,
          _rangeEnd!
      );

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected dates are no longer available')),
        );
        await _loadUnavailableDates();
        return;
      }

      await widget.hotelProvider.addOnlineBooking(
        roomId: widget.room['roomId'],
        roomNumber: widget.room['roomNumber'],
        startDate: _rangeStart!,
        endDate: _rangeEnd!,
        guestName: _nameController.text,
        guestEmail: _emailController.text,
        guestPhone: _phoneController.text,
        paymentMethod: _paymentMethod,
        hotelId: hotelId, // Use the hotelId from room data
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Book Room ${widget.room['roomNumber']}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 400,
                          child: TableCalendar(
                            firstDay: DateTime.now(),
                            lastDay: DateTime.now().add(Duration(days: 365)),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            rangeStartDay: _rangeStart,
                            rangeEndDay: _rangeEnd,
                            calendarFormat: CalendarFormat.month,
                            rangeSelectionMode: RangeSelectionMode.toggledOn,
                            availableGestures: AvailableGestures.all,
                            enabledDayPredicate: (day) {
                              return !day.isBefore(DateTime.now().subtract(Duration(days: 1))) &&
                                  !_isDateUnavailable(day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              if (_isDateUnavailable(selectedDay)) return;
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _rangeStart = null;
                                _rangeEnd = null;
                              });
                            },
                            onRangeSelected: (start, end, focusedDay) {
                              if (_hasUnavailableInRange(start!, end!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Selected range contains unavailable dates')),
                                );
                                return;
                              }
                              setState(() {
                                _rangeStart = start;
                                _rangeEnd = end;
                                _selectedDay = start;
                                _focusedDay = focusedDay;
                                _nights = end.difference(start).inDays;
                              });
                            },
                            calendarStyle: CalendarStyle(
                              unavailableStyle: TextStyle(
                                color: Colors.grey[400],
                                decoration: TextDecoration.lineThrough,
                              ),
                              rangeHighlightColor: Colors.green.shade100,
                              rangeStartDecoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              rangeEndDecoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        if (_rangeStart != null && _rangeEnd != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Selected: ${DateFormat('MMM dd').format(_rangeStart!)} - '
                                  '${DateFormat('MMM dd').format(_rangeEnd!)} (${_nights} nights)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer']
                              .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _paymentMethod = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: _confirmBooking,
                      child: Text('Confirm Booking', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}