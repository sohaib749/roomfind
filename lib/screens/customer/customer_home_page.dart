import 'package:flutter/material.dart';
import 'package:roomfind/providers/customer_hotel_provider.dart';
import 'package:provider/provider.dart';
import 'hotel_detail_page.dart';
import 'package:roomfind/login_screen/user_login.dart';
import 'package:roomfind/screens/customer/bookings_page.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerHomePage extends StatefulWidget {
  final String phoneNumber;

  const CustomerHomePage({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> 
    with TickerProviderStateMixin {
  final _cityController = TextEditingController();
  
  // Animation controllers
  late AnimationController _searchBarAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _floatingActionButtonController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _cityFilterAnimationController;
  
  // Animations
  late Animation<double> _searchBarAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _cityFilterAnimation;

  List<String> _availableCities = [];
  String? _selectedCity;

  // For time selection
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;

  // Add this key to your class
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Map<String, dynamic>> _previousHotels = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _searchBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _floatingActionButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();
    
    _cityFilterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Setup animations
    _searchBarAnimation = CurvedAnimation(
      parent: _searchBarAnimationController,
      curve: Curves.easeOutBack,
    );
    
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    );
    
    _cityFilterAnimation = CurvedAnimation(
      parent: _cityFilterAnimationController,
      curve: Curves.elasticOut,
    );
    
    // Start animations
    _searchBarAnimationController.forward();
    _listAnimationController.forward();
    _floatingActionButtonController.forward();
    _cityFilterAnimationController.forward();
    
    // Fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerProvider = Provider.of<CustomerHotelProvider>(context, listen: false);
      customerProvider.fetchCustomerProfile(widget.phoneNumber);
      customerProvider.fetchHotelsByCity("");
      _fetchAvailableCities();
    });
  }

  @override
  void dispose() {
    _searchBarAnimationController.dispose();
    _listAnimationController.dispose();
    _floatingActionButtonController.dispose();
    _backgroundAnimationController.dispose();
    _cityFilterAnimationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const UserLogin(),
      ),
    );
  }

  Future<void> _fetchAvailableCities() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('hotels').get();
      
      // Create a Set to remove duplicates
      final Set<String> citySet = {};
      
      // Safely add non-null cities to the set
      for (var doc in snapshot.docs) {
        final city = doc.data()['city'];
        if (city != null && city.toString().isNotEmpty) {
          citySet.add(city.toString());
        }
      }
      
      // Convert set to list
      setState(() {
        _availableCities = citySet.toList();
      });
    } catch (e) {
      print('Error fetching cities: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<CustomerHotelProvider>(context);
    if (hotelProvider.customerName != null) {
      debugPrint("Building Home Page. Current customer name: ${hotelProvider.customerName}");
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipPath(
          clipper: WaveClipper(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        title: Consumer<CustomerHotelProvider>(
          builder: (context, hotelProvider, _) {
            return Row(
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.green.shade700),
                  ),
                ),
                const SizedBox(width: 10),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    "Welcome, ${hotelProvider.customerName ?? 'Customer'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      drawer: _buildAnimatedDrawer(hotelProvider),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _floatingActionButtonController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.green.shade700,
          child: const Icon(Icons.refresh),
          onPressed: () {
            hotelProvider.fetchHotelsByCity("");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Refreshing hotels..."),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(_backgroundAnimation.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // City filter
                _buildCityFilter(),
                
                const SizedBox(height: 20),
                
                // Hotels list with staggered animation
                _buildHotelsList(hotelProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelsList(CustomerHotelProvider hotelProvider) {
    // If loading, show loading indicator
    if (hotelProvider.isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    // If no hotels, show empty state
    if (hotelProvider.hotels.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: value,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  Icons.hotel,
                  size: 80,
                  color: Colors.green.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "No hotels found",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show hotels list
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: hotelProvider.hotels.length,
        itemBuilder: (context, index) {
          final hotel = hotelProvider.hotels[index];
          
          // Create a staggered animation effect
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (index * 100)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(100 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildHotelCard(hotel),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCityFilter() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_cityFilterAnimation),
      child: FadeTransition(
        opacity: _cityFilterAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  "Filter by City",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 50,
                child: _availableCities.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableCities.length + 1, // +1 for "All" option
                        itemBuilder: (context, index) {
                          // First item is "All"
                          if (index == 0) {
                            return _buildCityChip(
                              "All Cities",
                              isSelected: _selectedCity == null,
                              onTap: () {
                                setState(() {
                                  _selectedCity = null;
                                });
                                final hotelProvider = Provider.of<CustomerHotelProvider>(context, listen: false);
                                hotelProvider.fetchHotelsByCity("");
                              },
                            );
                          }
                          
                          final city = _availableCities[index - 1];
                          return _buildCityChip(
                            city,
                            isSelected: _selectedCity == city,
                            onTap: () {
                              setState(() {
                                _selectedCity = city;
                              });
                              final hotelProvider = Provider.of<CustomerHotelProvider>(context, listen: false);
                              hotelProvider.fetchHotelsByCity(city);
                            },
                          );
                        },
                      ),
              ),
              
              // Time filter
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeFilterChip(
                      label: _checkInTime == null 
                          ? "Check-in Time" 
                          : "In: ${_checkInTime!.format(context)}",
                      icon: Icons.access_time,
                      onTap: () => _selectCheckInTime(context),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildTimeFilterChip(
                      label: _checkOutTime == null 
                          ? "Check-out Time" 
                          : "Out: ${_checkOutTime!.format(context)}",
                      icon: Icons.access_time_filled,
                      onTap: () => _selectCheckOutTime(context),
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

  Widget _buildCityChip(String city, {required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        elevation: isSelected ? 4 : 2,
        shadowColor: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        color: isSelected ? Colors.green.shade700 : Colors.white.withOpacity(0.9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                Text(
                  city,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip({
    required String label, 
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white.withOpacity(0.9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.green.shade700,
                size: 16,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCheckInTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _checkInTime ?? TimeOfDay(hour: 14, minute: 0),
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
    
    if (picked != null) {
      setState(() {
        _checkInTime = picked;
      });
      
      // Apply time filters
      _applyTimeFilters();
    }
  }

  Future<void> _selectCheckOutTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _checkOutTime ?? TimeOfDay(hour: 12, minute: 0),
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
    
    if (picked != null) {
      setState(() {
        _checkOutTime = picked;
      });
      
      // Apply time filters
      _applyTimeFilters();
    }
  }

  void _applyTimeFilters() {
    final hotelProvider = Provider.of<CustomerHotelProvider>(context, listen: false);
    
    // Fetch hotels with time filters
    if (_selectedCity != null) {
      hotelProvider.fetchHotelsByCity(_selectedCity!, checkIn: DateTime.now().copyWith(hour: _checkInTime!.hour, minute: _checkInTime!.minute), checkOut: DateTime.now().copyWith(hour: _checkOutTime!.hour, minute: _checkOutTime!.minute));
    } else {
      hotelProvider.fetchHotelsByCity("", checkIn: DateTime.now().copyWith(hour: _checkInTime!.hour, minute: _checkInTime!.minute), checkOut: DateTime.now().copyWith(hour: _checkOutTime!.hour, minute: _checkOutTime!.minute));
    }
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return Card(
      elevation: 6,
      shadowColor: Colors.green.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                HotelDetailPage(hotelId: hotel['hotelId']),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;
                
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Hotel icon or image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.hotel,
                    size: 40,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Hotel details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hotel['address'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFeatureChip("WiFi"),
                        const SizedBox(width: 8),
                        _buildFeatureChip("AC"),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(8 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildAnimatedDrawer(CustomerHotelProvider hotelProvider) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade700, Colors.green.shade500],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                //  const SizedBox(height: 12),
                  Consumer<CustomerHotelProvider>(
                    builder: (context, hotelProvider, _) {
                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotelProvider.customerName ?? 'Customer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.phoneNumber,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                _showNameChangeDialog(context, hotelProvider);
              },
              delay: 100,
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.history,
              title: 'Past Bookings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingsPage(showUpcoming: false),
                  ),
                );
              },
              delay: 200,
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.calendar_today,
              title: 'Upcoming Bookings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingsPage(showUpcoming: true),
                  ),
                );
              },
              delay: 300,
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                // TODO: Add navigation to settings page
              },
              delay: 400,
            ),
            const Divider(color: Colors.white30),
            _buildAnimatedDrawerItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                // TODO: Add navigation to help page
              },
              delay: 500,
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _logout,
              delay: 600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }

  void _showNameChangeDialog(BuildContext context, CustomerHotelProvider hotelProvider) {
    final _nameController = TextEditingController(text: hotelProvider.customerName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Name"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Enter new name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  hotelProvider.updateCustomerName(widget.phoneNumber, newName);
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 4, size.height * 0.8, size.width / 2, size.height);
    path.quadraticBezierTo(size.width * 3 / 4, size.height * 1.2, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class BackgroundPainter extends CustomPainter {
  final double progress;

  BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = LinearGradient(
      colors: [Colors.green.shade700, Colors.green.shade500],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.3, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
