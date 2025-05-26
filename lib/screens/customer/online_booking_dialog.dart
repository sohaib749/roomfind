//online_booking_dialog.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:roomfind/providers/hotel_provider.dart';
import 'package:flutter/services.dart';
import 'package:roomfind/services/formatters.dart';
import 'package:roomfind/providers/customer_hotel_provider.dart';
import 'package:roomfind/screens/customer/table_calendar.dart';
class OnlineBookingDialog extends StatefulWidget {
  final HotelProvider hotelProvider;
  final CustomerHotelProvider customerProvider;
  final Map<String, dynamic> room;
  final String userPhoneNumber; // The unique phone number identifier

  const OnlineBookingDialog({
    required this.hotelProvider,
    required this.customerProvider,
    required this.room,
    required this.userPhoneNumber,
    Key? key,
  }) : super(key: key);

  @override
  _OnlineBookingDialogState createState() => _OnlineBookingDialogState();
}
// Add this above the _OnlineBookingDialogState class


class _OnlineBookingDialogState extends State<OnlineBookingDialog> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final _formKey = GlobalKey<FormState>();
  List<DateTime> _unavailableDates = [];
  bool _isLoading = true;
  String? _customerName;

  // Only these fields are collected from user
  final _cnicController = TextEditingController();
  String _paymentMethod = 'Credit Card';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadCustomerData();
    _loadUnavailableDates();
  }

  Future<void> _loadCustomerData() async {
    try {
      await widget.customerProvider.fetchCustomerProfile(widget.userPhoneNumber);
      setState(() {
        _customerName = widget.customerProvider.customerName;
      });
    } catch (e) {
      debugPrint('Error loading customer data: $e');
    }
  }

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _loadUnavailableDates() async {
    setState(() => _isLoading = true);
    try {
      _unavailableDates = await widget.hotelProvider.getUnavailableDates(
        widget.room['roomId'],
      );
    } catch (e) {
      debugPrint('Error loading unavailable dates: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select booking dates')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking availability...'),
          ],
        ),
      ),
    );

    try {
      // First check availability
      final isAvailable = await widget.hotelProvider.isRoomAvailable(
        widget.room['roomId'],
        _rangeStart!,
        _rangeEnd!,
      );

      if (!isAvailable) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected dates are no longer available'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // If available, proceed with booking
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing your booking...'),
              ],
            ),
          ),
        );
      }

      await widget.hotelProvider.addOnlineBooking(
        roomId: widget.room['id'] ?? widget.room['roomId'],
        roomNumber: widget.room['roomNumber'],
        hotelId: widget.room['hotelId'] ?? widget.hotelProvider.currentHotelId,
        startDate: _rangeStart!,
        endDate: _rangeEnd!,
        guestName: widget.customerProvider.customerName ?? '',
        guestCnic: _cnicController.text.trim(),
        guestPhone: widget.customerProvider.customerPhone ?? '',
        userId: widget.customerProvider.customerId ?? '',
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context, true); // Close dialog with success

        // Show confirmation
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Confirmed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Room: ${widget.room['roomNumber']}'),
                const SizedBox(height: 8),
                Text('${DateFormat('MMM dd, yyyy').format(_rangeStart!)} - '
                    '${DateFormat('MMM dd, yyyy').format(_rangeEnd!)}'),
                const SizedBox(height: 16),
                const Text('Confirmation sent to your phone number.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Book Room ${widget.room['roomNumber']}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // Display customer info
                if (_customerName != null)
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Booking for'),
                    subtitle: Text(
                      _customerName!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                // Date selection
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) => CalendarDialog(
                        unavailableDates: _unavailableDates,
                        onDateRangeSelected: (start, end) {
                          setState(() {
                            _rangeStart = start;
                            _rangeEnd = end;
                          });
                        },
                      ),
                    );
                  },

                  child: Text(
                    _rangeStart == null
                        ? 'Select Dates'
                        : '${DateFormat('MMM dd').format(_rangeStart!)} - '
                        '${DateFormat('MMM dd').format(_rangeEnd!)}',
                  ),
                ),
                const SizedBox(height: 16),

                // CNIC Input
                TextFormField(
                  controller: _cnicController,
                  decoration: const InputDecoration(
                    labelText: 'CNIC Number',
                    hintText: 'XXXXX-XXXXXXX-X',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                    CnicInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your CNIC';
                    }
                    if (!RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(value)) {
                      return 'Invalid CNIC format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Method
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
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
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _confirmBooking,
                      child: const Text('CONFIRM BOOKING'),
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