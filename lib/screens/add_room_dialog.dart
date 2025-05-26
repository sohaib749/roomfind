import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/hotel_provider.dart';

class AddRoomDialog extends StatefulWidget {
  final HotelProvider hotelProvider;

  const AddRoomDialog({super.key, required this.hotelProvider});

  @override
  _AddRoomDialogState createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _amenitiesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  
  String _selectedStatus = 'Available';
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  final List<String> _roomStatuses = [
    'Available',
    'Occupied',
    'Maintenance',
    'Reserved'
  ];

  final List<String> _commonRoomTypes = [
    'Single',
    'Double',
    'Twin',
    'Suite',
    'Deluxe',
    'Family',
    'Presidential',
    'Other'
  ];

  final List<String> _commonAmenities = [
    'Wi-Fi',
    'TV',
    'Air Conditioning',
    'Mini Bar',
    'Safe',
    'Balcony',
    'Sea View',
    'Bathtub',
    'Shower',
    'Coffee Machine',
    'Refrigerator'
  ];

  @override
  void dispose() {
    _roomNumberController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    _amenitiesController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _addSelectedAmenity(String amenity) {
    final currentAmenities = _amenitiesController.text.isEmpty 
        ? <String>[] 
        : _amenitiesController.text.split(',').map((e) => e.trim()).toList();
    
    if (!currentAmenities.contains(amenity)) {
      currentAmenities.add(amenity);
      _amenitiesController.text = currentAmenities.join(', ');
    }
  }

  void _addRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one image"))
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Check if room number is unique
    bool isUnique = await widget.hotelProvider.isRoomNumberUnique(_roomNumberController.text);
    if (!isUnique) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Room number already exists"))
        );
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    final room = {
      "roomNumber": _roomNumberController.text,
      "type": _typeController.text,
      "price": double.parse(_priceController.text),
      "status": _selectedStatus,
      "amenities": _amenitiesController.text.isEmpty 
          ? [] 
          : _amenitiesController.text.split(',').map((e) => e.trim()).toList(),
      "description": _descriptionController.text,
      "capacity": int.tryParse(_capacityController.text) ?? 1,
    };

    try {
      await widget.hotelProvider.addRoom(room, _selectedImages);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Room added successfully"))
        );
        Navigator.pop(context); // Close the dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add room: $e"))
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Add New Room",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Basic Information
                const Text(
                  "Basic Information",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Room Number
                TextFormField(
                  controller: _roomNumberController,
                  decoration: const InputDecoration(
                    labelText: "Room Number *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Room number is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Room Type
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Room Type *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.hotel),
                  ),
                  value: _typeController.text.isEmpty ? null : _typeController.text,
                  items: _commonRoomTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _typeController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Room type is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Room Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: "Price per Night \$ *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Price is required";
                    }
                    if (double.tryParse(value) == null) {
                      return "Please enter a valid price";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Room Status
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Room Status",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  value: _selectedStatus,
                  items: _roomStatuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Room Capacity
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(
                    labelText: "Capacity (persons)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
                        return "Please enter a valid number";
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Room Description
                const Text(
                  "Room Description",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                    hintText: "Enter room description...",
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // Room Amenities
                const Text(
                  "Room Amenities",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(
                    labelText: "Amenities (comma-separated)",
                    border: OutlineInputBorder(),
                    hintText: "Wi-Fi, TV, Air Conditioning...",
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                
                // Common Amenities Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonAmenities.map((amenity) {
                    return ActionChip(
                      label: Text(amenity),
                      onPressed: () => _addSelectedAmenity(amenity),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Room Images
                const Text(
                  "Room Images *",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Image Selection Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Gallery"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Selected Images Preview
                if (_selectedImages.isNotEmpty) ...[
                  const Text(
                    "Selected Images:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 13,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _addRoom,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Add Room",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
