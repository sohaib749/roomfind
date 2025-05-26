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
  late DateTime _startOfWeek;
  late List<String> _weekDays;
  late String _weekDateRange;
  bool _isLoading = true;
  String? _errorMessage;
  bool _usingOptimizedQuery = true;

  @override
  void initState() {
    super.initState();
    _startOfWeek = _getStartOfWeek(DateTime.now());
    _weekDays = _getWeekDays(_startOfWeek);
    _weekDateRange = _getWeekDateRange(_startOfWeek);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endOfWeek = _startOfWeek.add(const Duration(days: 6));
      QuerySnapshot querySnapshot;

      // Try optimized query first
      if (_usingOptimizedQuery) {
        try {
          querySnapshot = await FirebaseFirestore.instance
              .collection('bookings')
              .where('hotelId', isEqualTo: widget.hotelId)
              .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
              .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfWeek))
              .get();
        } catch (e) {
          if (e.toString().contains('index')) {
            // Fall back to simpler query if index doesn't exist
            _usingOptimizedQuery = false;
            querySnapshot = await FirebaseFirestore.instance
                .collection('bookings')
                .where('hotelId', isEqualTo: widget.hotelId)
                .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfWeek))
                .get();
          } else {
            rethrow;
          }
        }
      } else {
        // Use fallback query
        querySnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('hotelId', isEqualTo: widget.hotelId)
            .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfWeek))
            .get();
      }

      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      hotelProvider.cachedBookings = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'startDate': (data['startDate'] as Timestamp).toDate(),
          'endDate': (data['endDate'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading bookings: ${e.toString()}';
      });
      debugPrint('Error loading bookings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isRoomBookedForDate(
      List<Map<String, dynamic>> bookings,
      String roomId,
      DateTime date,
      ) {
    final checkDate = DateTime(date.year, date.month, date.day);

    return bookings.where((b) => b['roomId'] == roomId).any((booking) {
      final startDate = (booking['startDate'] as DateTime);
      final endDate = (booking['endDate'] as DateTime);
      final bookingStart = DateTime(startDate.year, startDate.month, startDate.day);
      final bookingEnd = DateTime(endDate.year, endDate.month, endDate.day);

      return checkDate.isAtSameMomentAs(bookingStart) ||
          checkDate.isAtSameMomentAs(bookingEnd) ||
          (checkDate.isAfter(bookingStart) && checkDate.isBefore(bookingEnd));
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            if (_errorMessage!.contains('index'))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Please create the required Firestore index',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadBookings,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                'Week: $_weekDateRange',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _startOfWeek = _startOfWeek.add(Duration(days: -7));
                    _weekDays = _getWeekDays(_startOfWeek);
                    _weekDateRange = _getWeekDateRange(_startOfWeek);
                  });
                  _loadBookings();
                },
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _startOfWeek = _startOfWeek.add(Duration(days: 7));
                    _weekDays = _getWeekDays(_startOfWeek);
                    _weekDateRange = _getWeekDateRange(_startOfWeek);
                  });
                  _loadBookings();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildBookingTable(hotelProvider),
        ),
      ],
    );
  }

  Widget _buildBookingTable(HotelProvider hotelProvider) {
    if (hotelProvider.rooms.isEmpty) {
      return Center(child: Text('No rooms available'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
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
            ..._weekDays.map((day) => DataColumn(
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
                ..._weekDays.map((day) {
                  final dayDate = _startOfWeek.add(
                    Duration(days: _weekDays.indexOf(day)),
                  );
                  final isBooked = _isRoomBookedForDate(
                      hotelProvider.cachedBookings, room['id'], dayDate);

                  return DataCell(
                    Container(
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.red[100]?.withAlpha(230)
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
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _getWeekDateRange(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    final dateFormat = DateFormat('MMM dd');
    return '${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}';
  }

  List<String> _getWeekDays(DateTime startOfWeek) {
    final dateFormat = DateFormat('E');
    return List.generate(7, (index) {
      return dateFormat.format(startOfWeek.add(Duration(days: index)));
    });
  }
}