import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hotel_provider.dart';
import '../screens/add_room_dialog.dart';
import '../screens/edit_room_dialog.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class RoomManagementScreen extends StatefulWidget {
  @override
  _RoomManagementScreenState createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  bool _isLoading = false;
  String? _filterStatus;
  String? _filterType;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Fetch rooms only once when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRooms();
    });
  }
  
  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      await hotelProvider.fetchRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching rooms: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  List<Map<String, dynamic>> _filterRooms(List<Map<String, dynamic>> rooms) {
    if (_searchController.text.isEmpty && _filterStatus == null && _filterType == null) {
      return rooms;
    }
    
    return rooms.where((room) {
      // Apply search filter
      final searchTerm = _searchController.text.toLowerCase();
      final matchesSearch = searchTerm.isEmpty || 
          room['roomNumber'].toString().toLowerCase().contains(searchTerm) ||
          (room['type']?.toString().toLowerCase() ?? '').contains(searchTerm) ||
          (room['amenities']?.join(' ').toLowerCase() ?? '').contains(searchTerm);
      
      // Apply status filter
      final matchesStatus = _filterStatus == null || room['status'] == _filterStatus;
      
      // Apply type filter
      final matchesType = _filterType == null || room['type'] == _filterType;
      
      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }
  
  List<String> _getUniqueRoomTypes(List<Map<String, dynamic>> rooms) {
    final Set<String> types = {};
    for (var room in rooms) {
      if (room['type'] != null && room['type'].toString().isNotEmpty) {
        types.add(room['type']);
      }
    }
    return types.toList()..sort();
  }

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
    
    final filteredRooms = _filterRooms(hotelProvider.rooms);
    final roomTypes = _getUniqueRoomTypes(hotelProvider.rooms);

    return Scaffold(
      appBar: AppBar(
        title: Text("Room Management"),
        backgroundColor: Colors.green,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await hotelProvider.fetchRooms();
              setState(() {
                _isLoading = false;
              });
            },
          ),
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilterBar(roomTypes),
                _buildRoomStats(hotelProvider.rooms),
                Expanded(
                  child: filteredRooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "No rooms found",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: Icon(Icons.add),
                                label: Text("Add Room"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _showAddRoomDialog(context, hotelProvider),
                              ),
                            ],
                          ),
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: EdgeInsets.all(8),
                            itemCount: filteredRooms.length,
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildRoomCard(context, hotelProvider, filteredRooms[index]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text("Add New Room"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showAddRoomDialog(context, hotelProvider),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSearchAndFilterBar(List<String> roomTypes) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search rooms...",
              prefixIcon: Icon(Icons.search, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.green),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Filter by Status",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _filterStatus,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text("All Statuses"),
                    ),
                    ...["Available", "Occupied", "Maintenance", "Reserved"].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Filter by Type",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _filterType,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text("All Types"),
                    ),
                    ...roomTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterType = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomStats(List<Map<String, dynamic>> rooms) {
    // Calculate statistics
    final totalRooms = rooms.length;
    final availableRooms = rooms.where((room) => room['status'] == 'Available').length;
    final occupiedRooms = rooms.where((room) => room['status'] == 'Occupied').length;
    final maintenanceRooms = rooms.where((room) => room['status'] == 'Maintenance').length;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(totalRooms, "Total", Colors.blue),
          _buildStatItem(availableRooms, "Available", Colors.green),
          _buildStatItem(occupiedRooms, "Occupied", Colors.orange),
          _buildStatItem(maintenanceRooms, "Maintenance", Colors.red),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(int count, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRoomCard(BuildContext context, HotelProvider hotelProvider, Map<String, dynamic> room) {
    Color statusColor;
    IconData statusIcon;
    
    switch (room['status']) {
      case 'Available':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Occupied':
        statusColor = Colors.orange;
        statusIcon = Icons.person;
        break;
      case 'Maintenance':
        statusColor = Colors.red;
        statusIcon = Icons.build;
        break;
      case 'Reserved':
        statusColor = Colors.blue;
        statusIcon = Icons.bookmark;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showRoomDetails(context, room),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room image with gradient overlay and status badge
              Stack(
                children: [
                  // Room image
                  Container(
                    height: 180,
                    width: double.infinity,
                    child: room['imageUrls'] != null && room['imageUrls'].isNotEmpty
                        ? Hero(
                            tag: 'room_image_${room['id']}',
                            child: Image.network(
                              room['imageUrls'][0],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.hotel, size: 50, color: Colors.green),
                          ),
                  ),
                  
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Room number on bottom left
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Text(
                      "Room ${room['roomNumber']}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Price on bottom right
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "\$${room['price']}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  // Status badge on top right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            room['status'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Room details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room type with icon
                    Row(
                      children: [
                        Icon(Icons.hotel, size: 18, color: Colors.grey.shade700),
                        SizedBox(width: 6),
                        Text(
                          "${room['type']}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        
                        // Capacity indicator if available
                        if (room['capacity'] != null) ...[
                          SizedBox(width: 16),
                          Icon(Icons.person, size: 18, color: Colors.grey.shade700),
                          SizedBox(width: 4),
                          Text(
                            "${room['capacity']} ${room['capacity'] == 1 ? 'Person' : 'People'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Amenities chips
                    if (room['amenities'] != null && room['amenities'].isNotEmpty)
                      Container(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: (room['amenities'] as List).take(5).map<Widget>((amenity) {
                            IconData? amenityIcon;
                            
                            // Assign icons based on common amenities
                            if (amenity.toString().toLowerCase().contains('wifi')) {
                              amenityIcon = Icons.wifi;
                            } else if (amenity.toString().toLowerCase().contains('tv')) {
                              amenityIcon = Icons.tv;
                            } else if (amenity.toString().toLowerCase().contains('air')) {
                              amenityIcon = Icons.ac_unit;
                            } else if (amenity.toString().toLowerCase().contains('bath')) {
                              amenityIcon = Icons.bathtub;
                            } else if (amenity.toString().toLowerCase().contains('coffee')) {
                              amenityIcon = Icons.coffee;
                            } else if (amenity.toString().toLowerCase().contains('bar')) {
                              amenityIcon = Icons.local_bar;
                            } else if (amenity.toString().toLowerCase().contains('safe')) {
                              amenityIcon = Icons.lock;
                            } else if (amenity.toString().toLowerCase().contains('view')) {
                              amenityIcon = Icons.landscape;
                            } else {
                              amenityIcon = Icons.check_circle_outline;
                            }
                            
                            return Container(
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(amenityIcon, size: 14, color: Colors.green.shade700),
                                  SizedBox(width: 4),
                                  Text(
                                    amenity,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Action buttons with divider
              Column(
                children: [
                  Divider(height: 1, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // View details button
                        Expanded(
                          child: TextButton.icon(
                            icon: Icon(Icons.visibility, size: 18),
                            label: Text("View"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _showRoomDetails(context, room),
                          ),
                        ),
                        
                        // Vertical divider
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        
                        // Edit button
                        Expanded(
                          child: TextButton.icon(
                            icon: Icon(Icons.edit, size: 18),
                            label: Text("Edit"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _showEditRoomDialog(context, hotelProvider, room),
                          ),
                        ),
                        
                        // Vertical divider
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        
                        // Delete button
                        Expanded(
                          child: TextButton.icon(
                            icon: Icon(Icons.delete, size: 18),
                            label: Text("Delete"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _deleteRoom(context, hotelProvider, room),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showRoomDetails(BuildContext context, Map<String, dynamic> room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Room ${room['roomNumber']} Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              if (room['imageUrls'] != null && room['imageUrls'].isNotEmpty)
                Container(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: room['imageUrls'].length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 250,
                        margin: EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            room['imageUrls'][index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 20),
              _buildDetailItem("Room Number", room['roomNumber'].toString()),
              _buildDetailItem("Type", room['type']),
              _buildDetailItem("Price", "\$${room['price']}"),
              _buildDetailItem("Status", room['status']),
              if (room['amenities'] != null && room['amenities'].isNotEmpty)
                _buildDetailItem("Amenities", room['amenities'].join(', ')),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text("Edit Room"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditRoomDialog(context, Provider.of<HotelProvider>(context, listen: false), room);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text("Delete Room"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteRoom(context, Provider.of<HotelProvider>(context, listen: false), room);
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ":",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
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
    ).then((_) {
      // Refresh the room list after adding a room
      _fetchRooms();
    });
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
    ).then((_) {
      // Refresh the room list after editing a room
      _fetchRooms();
    });
  }
  
  void _deleteRoom(BuildContext context, HotelProvider hotelProvider, Map<String, dynamic> room) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Room"),
        content: Text("Are you sure you want to delete Room ${room['roomNumber']}? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text("Cancel"),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text("Delete"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await hotelProvider.deleteRoom(room['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Room ${room['roomNumber']} deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        // No need to call fetchRooms here as deleteRoom already updates the rooms list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete room: $e"),
            backgroundColor: Colors.red,
          ),
        );
        // Refresh the room list in case of error to ensure UI is in sync
        _fetchRooms();
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
