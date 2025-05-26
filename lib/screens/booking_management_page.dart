import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hotel_provider.dart';
import '../widgets/weekly_booking_table.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../screens/calendar_booking_dialog.dart';

class BookingManagementScreen extends StatefulWidget {
  @override
  _BookingManagementScreenState createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  final _guestNameController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    try {
      await hotelProvider.fetchRooms();
    } catch (e) {
      print("Error fetching rooms: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context);

    // hotelId can not not null
    if (hotelProvider.hotelId == null) {
      return Scaffold(
        body: Center(
            child: Text("Hotel ID not found. Please set up your hotel profile first.")),
      );
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Management"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: WeeklyBookingTable(hotelId: hotelProvider.hotelId!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _showOfflineBookingDialog(context, hotelProvider),
              child: Text("Add Offline Booking",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCalendarBookingDialog(
      BuildContext context,
      HotelProvider hotelProvider,
      Map<String, dynamic> room,
      ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CalendarBookingDialog(
        hotelProvider: hotelProvider,
        room: room,
      ),
    );
  }

  void _showOfflineBookingDialog(
      BuildContext context, HotelProvider hotelProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Offline Booking"),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: hotelProvider.getAvailableRooms(DateTime.now()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Text("Error loading rooms: ${snapshot.error}");
              }

              final availableRooms = snapshot.data ?? [];

              if (availableRooms.isEmpty) {
                return Text("No available rooms");
              }

              return SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _guestNameController,
                        decoration: InputDecoration(
                          labelText: "Guest Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        hint: Text("Select Room"),
                        isExpanded: true,
                        items: availableRooms.map((room) {
                          return DropdownMenuItem<String>(
                            value: room['id'],
                            child: Text(
                                "Room ${room['roomNumber']} (${room['type']})"),
                          );
                        }).toList(),
                        onChanged: (roomId) async {
                          if (roomId != null) {
                            final selectedRoom = availableRooms.firstWhere(
                                    (r) => r['id'] == roomId);
                            Navigator.of(context)
                                .pop(); // Close room selection dialog
                            await _showCalendarBookingDialog(
                                context, hotelProvider, selectedRoom);
                          }
                        },
                      ),
                    ]),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}