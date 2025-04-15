import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/hotel_provider.dart';

class CalendarBookingDialog extends StatefulWidget {
  final HotelProvider hotelProvider;
  final Map<String, dynamic> room;

  const CalendarBookingDialog({
    required this.hotelProvider,
    required this.room,
    Key? key,
  }) : super(key: key);

  @override
  _CalendarBookingDialogState createState() => _CalendarBookingDialogState();
}

class _CalendarBookingDialogState extends State<CalendarBookingDialog> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final _cnicController = TextEditingController();
  int _nights = 1;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      child: ConstrainedBox(
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
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _rangeStart = null;
                                _rangeEnd = null;
                              });
                            },
                            onRangeSelected: (start, end, focusedDay) {
                              setState(() {
                                _rangeStart = start;
                                _rangeEnd = end;
                                _selectedDay = start!;
                                _focusedDay = focusedDay;
                                _nights = end!.difference(start).inDays;
                              });
                            },
                            calendarStyle: CalendarStyle(
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
                        TextFormField(
                          controller: _cnicController,
                          decoration: InputDecoration(
                            labelText: 'Guest CNIC (XXXXX-XXXXXXX-X)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter CNIC';
                            }
                            if (!RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(value)) {
                              return 'Enter valid CNIC format (XXXXX-XXXXXXX-X)';
                            }
                            return null;
                          },
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
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_rangeStart == null || _rangeEnd == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please select dates')),
                          );
                          return;
                        }

                        try {
                          final booking = {
                            'guestCnic': _cnicController.text,
                            'roomNumber': widget.room['roomNumber'],
                            'roomId': widget.room['id'],
                            'status': 'Confirmed',
                            'hotelId': widget.hotelProvider.hotelId,
                            'startDate': Timestamp.fromDate(_rangeStart!),
                            'endDate': Timestamp.fromDate(_rangeEnd!),
                            'createdAt': Timestamp.now(),
                            'bookingType': 'Offline',
                          };

                          await widget.hotelProvider.addBooking(booking);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Booking successful!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Booking failed: $e')),
                          );
                        }
                      },
                      child: Text('Book Now', style: TextStyle(color: Colors.white)),
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