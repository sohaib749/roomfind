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
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final _cnicController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _nights = 1;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  void dispose() {
    _cnicController.dispose();
    _guestNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Book Room ${widget.room['roomNumber']} (${widget.room['type']})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Calendar Section
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[100],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: TableCalendar(
                            firstDay: DateTime.now(),
                            lastDay: DateTime.now().add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            rangeStartDay: _rangeStart,
                            rangeEndDay: _rangeEnd,
                            calendarFormat: CalendarFormat.month,
                            rangeSelectionMode: RangeSelectionMode.toggledOn,
                            availableGestures: AvailableGestures.all,
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                                // For single day selection
                                _rangeStart = selectedDay;
                                _rangeEnd = selectedDay.add(const Duration(days: 1));
                                _nights = 1;
                              });
                            },
                            onRangeSelected: (start, end, focusedDay) {
                              setState(() {
                                _rangeStart = start;
                                _rangeEnd = end;
                                _focusedDay = focusedDay;
                                if (start != null && end != null) {
                                  _nights = end.difference(start).inDays;
                                }
                              });
                            },
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Colors.green.shade200,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
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
                              withinRangeTextStyle: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Guest Information Section
                        TextFormField(
                          controller: _guestNameController,
                          decoration: const InputDecoration(
                            labelText: 'Guest Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter guest name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cnicController,
                          decoration: const InputDecoration(
                            labelText: 'CNIC (XXXXX-XXXXXXX-X)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Selected Dates Display
                        if (_rangeStart != null && _rangeEnd != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${DateFormat('MMM dd, yyyy').format(_rangeStart!)} - '
                                      '${DateFormat('MMM dd, yyyy').format(_rangeEnd!)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '($_nights ${_nights == 1 ? 'night' : 'nights'})',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : _submitBooking,
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Confirm Booking',
                        style: TextStyle(color: Colors.white),
                      ),
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

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final booking = {
        'guestName': _guestNameController.text,
        'guestCnic': _cnicController.text,
        'guestPhone': _phoneController.text,
        'roomNumber': widget.room['roomNumber'],
        'roomId': widget.room['id'],
        'roomType': widget.room['type'],
        'status': 'Confirmed',
        'hotelId': widget.hotelProvider.hotelId,
        'startDate': Timestamp.fromDate(_rangeStart!),
        'endDate': Timestamp.fromDate(_rangeEnd!),
        'createdAt': Timestamp.now(),
        'bookingType': 'Offline',
        'totalNights': _nights,
      };

      await widget.hotelProvider.addBooking(booking);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}