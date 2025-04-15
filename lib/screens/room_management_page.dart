import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hotel_provider.dart';
import '../screens/add_room_dialog.dart';
import '../screens/edit_room_dialog.dart';
class RoomManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context);

    // Fetch rooms
    if (hotelProvider.rooms.isEmpty) {
      hotelProvider.fetchRooms();
    }

    if (hotelProvider.hotelId == null) {
      return Scaffold(
        body: Center(child: Text("Hotel ID not found. Please set up your hotel profile first.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Room Management"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: hotelProvider.rooms.length,
              itemBuilder: (context, index) {
                final room = hotelProvider.rooms[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: room['imageUrls'] != null && room['imageUrls'].isNotEmpty
                        ? Image.network(room['imageUrls'][0], width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.image, size: 50, color: Colors.green),
                    title: Text("Room ${room['roomNumber']}", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Type: ${room['type']}", style: TextStyle(color: Colors.black87)),
                        Text("Price: \$${room['price']}", style: TextStyle(color: Colors.black87)),
                        Text("Status: ${room['status']}", style: TextStyle(color: Colors.green)),
                        Text("Amenities: ${room['amenities']?.join(', ') ?? 'None'}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.green),
                          onPressed: () => _showEditRoomDialog(context, hotelProvider, room),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRoom(context, hotelProvider, room),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _showAddRoomDialog(context, hotelProvider),
              child: Text("Add Room", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context, HotelProvider hotelProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AddRoomDialog(hotelProvider: hotelProvider);
      },
    );
  }

  void _showEditRoomDialog(BuildContext context, HotelProvider hotelProvider, Map<String, dynamic> room) {
    showDialog(
      context: context,
      builder: (context) {
        return EditRoomDialog(
          hotelProvider: hotelProvider,
          room: room,
        );
      },
    );
  }
  void _deleteRoom(BuildContext context, HotelProvider hotelProvider, Map<String, dynamic> room) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Room"),
        content: Text("Are you sure you want to delete this room?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Yes")),
        ],
      ),
    );
    if (confirmed == true) {
      await hotelProvider.deleteRoom(room['id']);
    }
  }
}