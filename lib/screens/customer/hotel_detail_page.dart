import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/customer_hotel_provider.dart';
import 'room_detail_page.dart';

class HotelDetailPage extends StatelessWidget {
  final String hotelId;

  HotelDetailPage({required this.hotelId});

  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<CustomerHotelProvider>(context);
    hotelProvider.fetchRoomsByHotelId(hotelId);

    final hotel = hotelProvider.hotels.firstWhere((hotel) => hotel['hotelId'] == hotelId);

    return Scaffold(
      appBar: AppBar(
        title: Text(hotel['name']),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Address: ${hotel['address']}", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("Description: ${hotel['description']}", style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: hotelProvider.rooms.isEmpty
                ? Center(
              child: Text(
                "No rooms available.",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: hotelProvider.rooms.length,
              itemBuilder: (context, index) {
                final room = hotelProvider.rooms[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text("Room ${room['roomNumber']}", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Type: ${room['type']}, Price: \$${room['price']}"),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailPage(room: room),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}