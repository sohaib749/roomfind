import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/customer_hotel_provider.dart';
// import 'package:roomfind/widgets/custom_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'room_detail_page.dart';

class HotelDetailPage extends StatefulWidget {
  final String hotelId;

  const HotelDetailPage({Key? key, required this.hotelId}) : super(key: key);

  @override
  _HotelDetailPageState createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _filterType;
  RangeValues _priceRange = RangeValues(0, 1000);
  String _sortOption = 'Price: Low to High';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hotel Details'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final hotelProvider = Provider.of<CustomerHotelProvider>(context, listen: true);
    final hotel = hotelProvider.hotels.firstWhere(
      (h) => h['hotelId'] == widget.hotelId,
      orElse: () => {'name': 'Hotel not found', 'address': '', 'profileImageUrl': []},
    );
    
    final filteredRooms = _getFilteredRooms(hotelProvider.rooms);
    
    return Column(
      children: [
        // Hotel header with image
        if (hotel['profileImageUrl'] != null)
          Image.network(
            hotel['profileImageUrl'],
            height: 80,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 80,
              color: Colors.grey.shade200,
              child: Icon(Icons.hotel, size: 80, color: Colors.green),
            ),
          )
        else
          Container(
            height: 200,
            color: Colors.grey.shade200,
            child: Icon(Icons.hotel, size: 80, color: Colors.green),
          ),
        
        // Hotel info
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hotel['name'] ?? 'Hotel Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    hotel['address'] ?? 'Address not available',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                hotel['description'] ?? '',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        
        // Tab bar for rooms
        TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          tabs: [
            Tab(text: 'Rooms'),
            Tab(text: 'Details'),
            Tab(text: 'Reviews'),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Rooms tab
              _buildRoomsTab(filteredRooms),
              
              // Details tab
              _buildHotelInfoTab(hotel),
              
              // Reviews tab (placeholder)
              Center(child: Text('No reviews yet')),
            ],
          ),
        ),
      ],
    );
  }
  double _maxPrice = 1000;
  int _selectedCapacity = 0;
  List<String> _selectedAmenities = [];
  
  // For date selection
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  
  // For search
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Don't call _fetchHotelData() directly here
    // Schedule it for after the first build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHotelData();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchHotelData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final hotelProvider = Provider.of<CustomerHotelProvider>(context, listen: false);
      await hotelProvider.fetchAllHotels();
      await hotelProvider.fetchRoomsByHotelId(widget.hotelId);
      
      // Set max price based on available rooms
      if (hotelProvider.rooms.isNotEmpty) {
        final highestPrice = hotelProvider.rooms
            .map((room) => (room['price'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);
        
        setState(() {
          _maxPrice = highestPrice.ceilToDouble();
          _priceRange = RangeValues(0, _maxPrice);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading hotel data: $e"))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _resetFilters() {
    setState(() {
      _filterType = null;
      _priceRange = RangeValues(0, _maxPrice);
      _selectedCapacity = 0;
      _selectedAmenities = [];
      _searchController.clear();
    });
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _checkInDate ?? DateTime.now(),
      end: _checkOutDate ?? DateTime.now().add(Duration(days: 1)),
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDateRange != null) {
      setState(() {
        _checkInDate = pickedDateRange.start;
        _checkOutDate = pickedDateRange.end;
      });
    }
  }
  
  List<Map<String, dynamic>> _getFilteredRooms(List<Map<String, dynamic>> rooms) {
    return rooms.where((room) {
      // Filter by search text
      final searchText = _searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        final roomNumber = room['roomNumber'].toString().toLowerCase();
        final roomType = (room['type'] ?? '').toString().toLowerCase();
        final roomDesc = (room['description'] ?? '').toString().toLowerCase();
        
        if (!roomNumber.contains(searchText) && 
            !roomType.contains(searchText) && 
            !roomDesc.contains(searchText)) {
          return false;
        }
      }
      
      // Filter by room type
      if (_filterType != null && room['type'] != _filterType) {
        return false;
      }
      
      // Filter by price range
      final price = (room['price'] as num).toDouble();
      if (price < _priceRange.start || price > _priceRange.end) {
        return false;
      }
      
      // Filter by capacity
      if (_selectedCapacity > 0) {
        final capacity = room['capacity'] ?? 1;
        if (capacity < _selectedCapacity) {
          return false;
        }
      }
      
      // Filter by amenities
      if (_selectedAmenities.isNotEmpty) {
        final roomAmenities = room['amenities'] as List?;
        if (roomAmenities == null) return false;
        
        for (final amenity in _selectedAmenities) {
          if (!roomAmenities.contains(amenity)) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();
  }
  
  List<String> _getUniqueRoomTypes(List<Map<String, dynamic>> rooms) {
    final types = rooms.map((room) => room['type'].toString()).toSet().toList();
    types.sort();
    return types;
  }
  
  List<String> _getAllAmenities(List<Map<String, dynamic>> rooms) {
    final Set<String> amenities = {};
    
    for (final room in rooms) {
      final roomAmenities = room['amenities'] as List?;
      if (roomAmenities != null) {
        for (final amenity in roomAmenities) {
          amenities.add(amenity.toString());
        }
      }
    }
    
    final result = amenities.toList();
    result.sort();
    return result;
  }
  
  void _toggleAmenityFilter(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }
  
  void _showFilterBottomSheet(BuildContext context, List<Map<String, dynamic>> rooms) {
    final roomTypes = _getUniqueRoomTypes(rooms);
    final allAmenities = _getAllAmenities(rooms);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter Rooms",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _resetFilters();
                          });
                        },
                        child: Text("Reset All"),
                      ),
                    ],
                  ),
                  Divider(),
                  
                  // Filters in a scrollable container
                  Expanded(
                    child: ListView(
                      children: [
                        // Price Range
                        Text(
                          "Price Range",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "\$${_priceRange.start.toInt()}",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "\$${_priceRange.end.toInt()}",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: _maxPrice,
                          divisions: 20,
                          activeColor: Colors.green,
                          inactiveColor: Colors.green.withOpacity(0.2),
                          labels: RangeLabels(
                            "\$${_priceRange.start.toInt()}",
                            "\$${_priceRange.end.toInt()}",
                          ),
                          onChanged: (values) {
                            setModalState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Room Type
                        Text(
                          "Room Type",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: Text("Any"),
                              selected: _filterType == null,
                              onSelected: (selected) {
                                setModalState(() {
                                  _filterType = null;
                                });
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green,
                            ),
                            ...roomTypes.map((type) {
                              return FilterChip(
                                label: Text(type),
                                selected: _filterType == type,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _filterType = selected ? type : null;
                                  });
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: Colors.green.shade100,
                                checkmarkColor: Colors.green,
                              );
                            }).toList(),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Capacity
                        Text(
                          "Capacity",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: Text("Any"),
                              selected: _selectedCapacity == 0,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedCapacity = 0;
                                });
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green,
                            ),
                            for (int i = 1; i <= 5; i++)
                              FilterChip(
                                label: Text("$i ${i == 1 ? 'Person' : 'People'}"),
                                selected: _selectedCapacity == i,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedCapacity = selected ? i : 0;
                                  });
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: Colors.green.shade100,
                                checkmarkColor: Colors.green,
                              ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Amenities
                        Text(
                          "Amenities",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allAmenities.map((amenity) {
                            return FilterChip(
                              label: Text(amenity),
                              selected: _selectedAmenities.contains(amenity),
                              onSelected: (selected) {
                                setModalState(() {
                                  _toggleAmenityFilter(amenity);
                                });
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          // Filters are already applied in the modal state
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Apply Filters",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  
  
  Widget _buildRoomsTab(List<Map<String, dynamic>> rooms) {
    final filteredRooms = _getFilteredRooms(rooms);
    
    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              // Search bar
              // TextField(
              //   controller: _searchController,
              //   decoration: InputDecoration(
              //     hintText: "Search rooms...",
              //     prefixIcon: Icon(Icons.search, color: Colors.grey),
              //     filled: true,
              //     fillColor: Colors.grey.shade100,
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(12),
              //       borderSide: BorderSide.none,
              //     ),
              //     contentPadding: EdgeInsets.symmetric(vertical: 0),
              //   ),
              //   onChanged: (_) => setState(() {}),
              // ),
              
              // SizedBox(height: 12),
              
              // Filter chips
              // SingleChildScrollView(
              //   scrollDirection: Axis.horizontal,
              //   child:
                
              //    Row(
              //     children: [
              //       // Filter button
                   
                    
              //       SizedBox(width: 8),
                    
              //       // Room type filters
              //       // ..._getUniqueRoomTypes(rooms).map((type) {
              //       //   final isSelected = _filterType == type;
              //       //   return Padding(
              //       //     padding: const EdgeInsets.only(right: 8),
              //       //     child: FilterChip(
              //       //       label: Text(type),
              //       //       selected: isSelected,
              //       //       onSelected: (selected) {
              //       //         setState(() {
              //       //           _filterType = selected ? type : null;
              //       //         });
              //       //       },
              //       //       backgroundColor: Colors.grey.shade200,
              //       //       selectedColor: Colors.green.shade100,
              //       //       checkmarkColor: Colors.green,
              //       //     ),
              //       //   );
              //       // }).toList(),
              //     ],
              //   ),
              // ),
              
            ],
          ),
        ),
        
        // Room count
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${filteredRooms.length} ${filteredRooms.length == 1 ? 'Room' : 'Rooms'} Available",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              
              // Sort dropdown
              // DropdownButton<String>(
              //   value: _sortOption,
              //   icon: Icon(Icons.sort),
              //   underline: SizedBox(),
              //   onChanged: (String? newValue) {
              //     if (newValue != null) {
              //       setState(() {
              //         _sortOption = newValue;
              //         // Implement sorting logic here
              //       });
              //     }
              //   },
              //   items: <String>['Price: Low to High', 'Price: High to Low']
              //       .map<DropdownMenuItem<String>>((String value) {
              //     return DropdownMenuItem<String>(
              //       value: value,
              //       child: Text(value),
              //     );
              //   }).toList(),
              // ),
               IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.green),
                  tooltip: "Filters",
                  onPressed: () => _showFilterBottomSheet(context, rooms),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Rooms list
        Expanded(
          child: filteredRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No rooms match your filters",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _resetFilters();
                          });
                        },
                        child: Text("Reset Filters"),
                      ),
                    ],
                  ),
                )
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildRoomCardDetailed(room),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildRoomCardDetailed(Map<String, dynamic> room) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room image with status badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  room['imageUrls']?[0] ?? '',
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.hotel, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              
              // Price badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "\$${room['price']}/night",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Room details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room number and type
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Room ${room['roomNumber']}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            room['type'] ?? 'Standard Room',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Capacity indicator
                    if (room['capacity'] != null) ...[
                      Row(
                        children: [
                          for (int i = 0; i < (room['capacity'] as int); i++)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Icon(Icons.person, size: 16, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Description
                if (room['description'] != null) ...[
                  Text(
                    room['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                ],
                
                // Amenities
                if (room['amenities'] != null && (room['amenities'] as List).isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (room['amenities'] as List).take(4).map<Widget>((amenity) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          amenity.toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if ((room['amenities'] as List).length > 4) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "+${(room['amenities'] as List).length - 4} more",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 16),
                ],
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: BorderSide(color: Colors.green),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomDetailPage(room: room),
                            ),
                          );
                        },
                        child: Text("View Details"),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Book now logic
                        },
                        child: Text("Book Now"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHotelInfoTab(Map<String, dynamic> hotel) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            "About This Hotel",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            hotel['description'] ?? "No description available.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          
          // Hotel Amenities
          if (hotel['amenities'] != null && (hotel['amenities'] as List).isNotEmpty) ...[
            Text(
              "Hotel Amenities",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: (hotel['amenities'] as List).map<Widget>((amenity) {
                IconData iconData;
                
                // Assign icons based on common amenities
                if (amenity.toString().toLowerCase().contains('wifi')) {
                  iconData = Icons.wifi;
                } else if (amenity.toString().toLowerCase().contains('parking')) {
                  iconData = Icons.local_parking;
                } else if (amenity.toString().toLowerCase().contains('breakfast')) {
                  iconData = Icons.free_breakfast;
                } else if (amenity.toString().toLowerCase().contains('pool')) {
                  iconData = Icons.pool;
                } else if (amenity.toString().toLowerCase().contains('gym')) {
                  iconData = Icons.fitness_center;
                } else if (amenity.toString().toLowerCase().contains('spa')) {
                  iconData = Icons.spa;
                } else if (amenity.toString().toLowerCase().contains('restaurant')) {
                  iconData = Icons.restaurant;
                } else if (amenity.toString().toLowerCase().contains('bar')) {
                  iconData = Icons.local_bar;
                } else if (amenity.toString().toLowerCase().contains('air')) {
                  iconData = Icons.ac_unit;
                } else {
                  iconData = Icons.check_circle_outline;
                }
                
                return Container(
                  width: MediaQuery.of(context).size.width / 2 - 24,
                  child: Row(
                    children: [
                      Icon(iconData, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          amenity.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
          ],
          
          // Policies
          Text(
            "Hotel Policies",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildPolicyItem(
            Icons.access_time,
            "Check-in Time",
            hotel['checkInTime'] ?? "2:00 PM",
          ),
          SizedBox(height: 8),
          _buildPolicyItem(
            Icons.access_time,
            "Check-out Time",
            hotel['checkOutTime'] ?? "12:00 PM",
          ),
          // SizedBox(height: 8),
          // _buildPolicyItem(
          //   Icons.pets,
          //   "Pet Policy",
          //   hotel['petPolicy'] ?? "Pets not allowed",
          // ),
          // SizedBox(height: 8),
          // _buildPolicyItem(
          //   Icons.smoke_free,
          //   "Smoking Policy",
          //   hotel['smokingPolicy'] ?? "Non-smoking hotel",
          // ),
          // SizedBox(height: 24),
          
          // Contact Information
          Text(
            "Contact Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          if (hotel['phoneNumber'] != null)
            _buildContactItem(
              Icons.phone,
              "Phone",
              hotel['phoneNumber'],
              () => launch("tel:${hotel['phoneNumber']}"),
            ),
          if (hotel['email'] != null)
            _buildContactItem(
              Icons.email,
              "Email",
              hotel['email'],
              () => launch("mailto:${hotel['email']}"),
            ),
          if (hotel['website'] != null)
            _buildContactItem(
              Icons.language,
              "Website",
              hotel['website'],
              () => launch(hotel['website']),
            ),
          SizedBox(height: 24),
          
          // Location
          Text(
            "Location",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  hotel['address'] ?? "Address not available",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Map placeholder - in a real app, you would integrate Google Maps here
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: TextButton.icon(
                icon: Icon(Icons.map, color: Colors.green),
                label: Text(
                  "Open in Maps",
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: () {
                  if (hotel['address'] != null) {
                    launch("https://maps.google.com/?q=${Uri.encodeComponent(hotel['address'])}");
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPolicyItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildContactItem(IconData icon, String title, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.green),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
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
}
