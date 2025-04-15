import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/hotel_provider.dart';
import 'package:roomfind/screens/customer/online_booking_dialog.dart';
class RoomDetailPage extends StatelessWidget {
  final Map<String, dynamic> room;

  const RoomDetailPage({
    required this.room,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    print("Room Data: $room");


    final List<String> imageUrls = _convertToList(room['imageUrls'] ?? room['imageUrl']);
    final List<String> amenities = _convertToList(room['amenities']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Room ${room['roomNumber']?.toString() ?? 'N/A'}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display images (handle multiple images or no images)
            if (imageUrls.isNotEmpty)
              Column(
                children: [
                  // Main image (First image)
                  GestureDetector(
                    onTap: () => _showImageDialog(context, imageUrls[0]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrls[0],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Other images in horizontal scroll
                  if (imageUrls.length > 1)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showImageDialog(context, imageUrls[index]),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrls[index],
                                  height: 100,
                                  width: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      width: 150,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                ),
              ),
            SizedBox(height: 20),

            // Room Details
            Text("Room Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 10),
            _buildDetailRow(icon: Icons.king_bed, label: "Type", value: room['type']?.toString() ?? 'N/A'),
            SizedBox(height: 10),
            _buildDetailRow(icon: Icons.attach_money, label: "Price", value: "\$${room['price']?.toString() ?? 'N/A'}"),
            SizedBox(height: 10),
            _buildDetailRow(icon: Icons.info, label: "Status", value: room['status']?.toString() ?? 'N/A'),
            SizedBox(height: 20),

            // Amenities
            Text("Amenities", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 10),
            if (amenities.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amenities.map((amenity) {
                  return Chip(
                    label: Text(amenity, style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  );
                }).toList(),
              )
            else
              Text("No amenities available", style: TextStyle(fontSize: 16, color: Colors.grey)),

            // Book Now Button
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
                showDialog(
                  context: context,
                  builder: (context) => OnlineBookingDialog(
                    hotelProvider: hotelProvider,
                    room: room,
                  ),
                );
              },
              child: Text(
                'Book Now',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }


  List<String> _convertToList(dynamic value) {
    if (value == null) {
      return [];
    } else if (value is String) {
      return [value];
    } else if (value is List) {
      return value.map((e) => e.toString()).toList();
    } else {
      return [];
    }
  }
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 3.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        SizedBox(width: 10),
        Text("$label: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 18, color: Colors.black54), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}