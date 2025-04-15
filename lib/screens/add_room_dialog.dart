import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/hotel_provider.dart';

class AddRoomDialog extends StatefulWidget {
  final HotelProvider hotelProvider;

  AddRoomDialog({required this.hotelProvider});

  @override
  _AddRoomDialogState createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _roomNumberController = TextEditingController();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _amenitiesController = TextEditingController();
  List<File> _selectedImages = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _addRoom() async {
    if (_roomNumberController.text.isEmpty ||
        _typeController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select at least one image")));
      return;
    }

    // Validate price input
    double? price = double.tryParse(_priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid price format")));
      return;
    }

    // Check if room number is unique
    bool isUnique = await widget.hotelProvider.isRoomNumberUnique(_roomNumberController.text);
    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Room number already exists")));
      return;
    }

    final room = {
      "roomNumber": _roomNumberController.text,
      "type": _typeController.text,
      "price": price,
      "status": "Available",
      "amenities": _amenitiesController.text.split(',').map((e) => e.trim()).toList(),
    };

    try {
      await widget.hotelProvider.addRoom(room, _selectedImages);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Room added successfully")));
      Navigator.pop(context); // Close the dialog immediately
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add room: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Room"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _roomNumberController, decoration: InputDecoration(labelText: "Room Number")),
            TextField(controller: _typeController, decoration: InputDecoration(labelText: "Room Type")),
            TextField(controller: _priceController, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: _amenitiesController, decoration: InputDecoration(labelText: "Amenities (comma-separated)")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _pickImage,
              child: Text("Pick Room Image", style: TextStyle(color: Colors.white)),
            ),
            if (_selectedImages.isNotEmpty)
              Column(
                children: _selectedImages.map((image) => Text("Image Selected: ${image.path}")).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: _addRoom,
          child: Text("Save"),
        ),
      ],
    );
  }
}