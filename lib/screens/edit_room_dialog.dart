import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/hotel_provider.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class EditRoomDialog extends StatefulWidget {
  final HotelProvider hotelProvider;
  final Map<String, dynamic> room;

  EditRoomDialog({required this.hotelProvider, required this.room});

  @override
  _EditRoomDialogState createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  final _roomNumberController = TextEditingController();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _amenitiesController = TextEditingController();
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form fields with existing room data
    _roomNumberController.text = widget.room['roomNumber'];
    _typeController.text = widget.room['type'];
    _priceController.text = widget.room['price'].toString();
    _amenitiesController.text = (widget.room['amenities'] as List?)?.join(', ') ?? '';
    _existingImageUrls = List.from(widget.room['imageUrls'] ?? []);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _updateRoom() async {
    if (_roomNumberController.text.isEmpty ||
        _typeController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    // Validate price input
    double? price = double.tryParse(_priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid price format")));
      return;
    }

    final updatedRoom = {
      "roomNumber": _roomNumberController.text,
      "type": _typeController.text,
      "price": price,
      "status": widget.room['status'], // Keep the existing status
      "amenities": _amenitiesController.text.split(',').map((e) => e.trim()).toList(),
    };

    try {
      // upload new images to cloudinary
      List<String> newImageUrls = [];
      for (final imageFile in _selectedImages) {
        final imageUrl = await widget.hotelProvider.uploadImageToCloudinary(imageFile);
        if (imageUrl != null) {
          newImageUrls.add(imageUrl);
        }
      }

      // combine existing and new image URLs
      updatedRoom['imageUrls'] = [..._existingImageUrls, ...newImageUrls];

      // update the room in Firestore
      await widget.hotelProvider.updateRoom(widget.room['id'], updatedRoom);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Room updated successfully")));
      Navigator.pop(context); // Close the dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update room: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Room"),
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
              child: Text("Add More Images", style: TextStyle(color: Colors.white)),
            ),
            if (_existingImageUrls.isNotEmpty)
              Column(
                children: _existingImageUrls.map((url) => Image.network(url, width: 50, height: 50, fit: BoxFit.cover)).toList(),
              ),
            if (_selectedImages.isNotEmpty)
              Column(
                children: _selectedImages.map((image) => Text("New Image: ${image.path}")).toList(),
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
          onPressed: _updateRoom,
          child: Text("Save"),
        ),
      ],
    );
  }
}