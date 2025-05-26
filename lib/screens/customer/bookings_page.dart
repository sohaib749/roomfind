import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/customer_hotel_provider.dart';

class BookingsPage extends StatefulWidget {
  final bool showUpcoming;

  const BookingsPage({Key? key, required this.showUpcoming}) : super(key: key);

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late final Stream<QuerySnapshot> _bookingsStream;
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    final phoneNumber = context.read<CustomerHotelProvider>().customerPhone;

    // Use this simpler query while waiting for index to build
    _bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('guestPhone', isEqualTo: phoneNumber)
        .snapshots();

    // OR after index is created, use this more efficient query:
    /*
    _bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('guestPhone', isEqualTo: phoneNumber)
        .orderBy('startDate', descending: !widget.showUpcoming)
        .snapshots();
    */
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showUpcoming ? 'Upcoming Bookings' : 'Past Bookings'),
        backgroundColor: Colors.green,
      ),
        body: StreamBuilder<QuerySnapshot>(
            stream: _bookingsStream,
            builder: (context, snapshot) {
              {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      widget.showUpcoming
                          ? 'No upcoming bookings found'
                          : 'No past bookings found',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }

                final bookings = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final endDate = (data['endDate'] as Timestamp).toDate();
                  return widget.showUpcoming
                      ? endDate.isAfter(_now)
                      : endDate.isBefore(_now);
                }).toList();
                bookings.sort((a, b) {
                  final aDate = (a.data() as Map<String, dynamic>)['startDate'] as Timestamp;
                  final bDate = (b.data() as Map<String, dynamic>)['startDate'] as Timestamp;
                  return widget.showUpcoming
                      ? aDate.compareTo(bDate)
                      : bDate.compareTo(aDate);
                });

                if (bookings.isEmpty) {
                  return Center(
                    child: Text(
                      widget.showUpcoming
                          ? 'No upcoming bookings found'
                          : 'No past bookings found',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final data = booking.data() as Map<String, dynamic>;
                    final startDate = (data['startDate'] as Timestamp).toDate();
                    final endDate = (data['endDate'] as Timestamp).toDate();
                    final nights = endDate
                        .difference(startDate)
                        .inDays;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['roomNumber'] ?? 'Room',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${DateFormat('MMM dd, yyyy').format(
                                  startDate)} - '
                                  '${DateFormat('MMM dd, yyyy').format(
                                  endDate)} '
                                  '($nights night${nights > 1 ? 's' : ''})',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: ${data['status'] ?? 'Confirmed'}',
                              style: TextStyle(
                                color: data['status'] == 'Cancelled'
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (widget.showUpcoming &&
                                data['status'] != 'Cancelled')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      _showCancelDialog(context, booking.id),
                                  child: const Text(
                                    'Cancel Booking',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            }
        )
    );
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              _cancelBooking(context, bookingId);
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'Cancelled',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: $e')),
      );
    }
  }
}