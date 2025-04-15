import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/hotel_provider.dart';
import 'package:provider/provider.dart';

class WeeklyBookingTable extends StatefulWidget {
  final String hotelId;

  const WeeklyBookingTable({required this.hotelId, Key? key}) : super(key: key);

  @override
  _WeeklyBookingTableState createState() => _WeeklyBookingTableState();
}

class _WeeklyBookingTableState extends State<WeeklyBookingTable> {
  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('hotelId', isEqualTo: widget.hotelId)
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
          .snapshots(),
      builder: (context, snapshot) {
        // Use cached data immediately while waiting for fresh data
        if (snapshot.connectionState == ConnectionState.waiting &&
            hotelProvider.cachedBookings.isNotEmpty) {
          return _buildMainContent(hotelProvider, hotelProvider.cachedBookings);
        }

        // If no cached data and still loading, show spinner
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Process fresh data
        final bookings = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'startDate': (data['startDate'] as Timestamp).toDate(),
            'endDate': (data['endDate'] as Timestamp).toDate(),
          };
        }).toList();

        // Update cache for next time
        WidgetsBinding.instance.addPostFrameCallback((_) {
          hotelProvider.cachedBookings = bookings;
        });

        return _buildMainContent(hotelProvider, bookings);
      },
    );
  }

  Widget _buildMainContent(HotelProvider hotelProvider, List<Map<String, dynamic>> bookings) {
    final startOfWeek = DateTime.now();
    final weekDateRange = _getWeekDateRange(startOfWeek);
    final weekDays = _getWeekDays(startOfWeek);

    if (hotelProvider.rooms.isEmpty) {
      return Center(child: Text('No rooms available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Week: $weekDateRange',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateColor.resolveWith(
                    (states) => Colors.green.shade700,
              ),
              columns: [
                DataColumn(
                  label: Text(
                    "Room Number",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ...weekDays.map((day) => DataColumn(
                  label: Text(
                    day,
                    style: TextStyle(color: Colors.white),
                  ),
                )),
              ],
              rows: hotelProvider.rooms.map((room) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        "Room ${room['roomNumber']}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...weekDays.map((day) {
                      final dayDate = startOfWeek.add(
                        Duration(days: weekDays.indexOf(day)),
                      );
                      final isBooked = _isRoomBookedForDate(
                          bookings, room['id'], dayDate);

                      return DataCell(
                        Container(

                          decoration: BoxDecoration(
                            color: isBooked
                                ? Colors.red[100]?.withAlpha(230)  // 230 ≈ 0.9 * 255
                                : Colors.green[100]?.withAlpha(230),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              isBooked ? "Booked" : "Vacant",
                              style: TextStyle(
                                color: isBooked
                                    ? Colors.red[800]
                                    : Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  bool _isRoomBookedForDate(
      List<Map<String, dynamic>> bookings,
      String roomId,
      DateTime date,
      ) {
    return bookings.any((booking) {
      if (booking['roomId'] != roomId) return false;

      final startDate = booking['startDate'] as DateTime;
      final endDate = booking['endDate'] as DateTime;

      return date.isAtSameMomentAs(startDate) ||
          date.isAtSameMomentAs(endDate) ||
          (date.isAfter(startDate) && date.isBefore(endDate));
    });
  }

  String _getWeekDateRange(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    final dateFormat = DateFormat('MMM dd');
    return '${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}';
  }

  List<String> _getWeekDays(DateTime startOfWeek) {
    final dateFormat = DateFormat('E'); // Short day name (Mon, Tue, etc.)
    return List.generate(7, (index) {
      return dateFormat.format(startOfWeek.add(Duration(days: index)));
    });
  }
}