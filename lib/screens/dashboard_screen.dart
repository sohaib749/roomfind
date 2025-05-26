import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:roomfind/screens/customer/customer_home_page.dart';
import 'dart:math' as math;
import '../providers/hotel_provider.dart';
import 'package:roomfind/screens/room_management_page.dart';
import 'package:roomfind/screens/booking_management_page.dart';
import 'package:roomfind/screens/hotel_profile_edit_page.dart';
import 'package:roomfind/login_screen/user_login.dart';

class HotelDashboard extends StatefulWidget {
  @override
  _HotelDashboardState createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _hotelProfile;
  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;
  
  // For animated stats
  int _displayedRoomCount = 0;
  int _displayedBookingCount = 0;
  double _displayedRevenue = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _backgroundAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    
    _fetchHotelProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchHotelProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      final hotelProfile = await hotelProvider.fetchHotelProfile();
      
      // Fetch rooms and bookings for stats
      await hotelProvider.fetchRooms();
      await hotelProvider.fetchBookings();

      setState(() {
        _hotelProfile = hotelProfile;
        _isLoading = false;
      });
      
      // Animate stats
      _animateStats(
        roomCount: hotelProvider.rooms.length,
        bookingCount: hotelProvider.bookings.length,
        revenue: _calculateTotalRevenue(hotelProvider.bookings),
      );
      
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load hotel profile: ${e.toString()}";
        _isLoading = false;
      });
    }
  }
  
  double _calculateTotalRevenue(List<Map<String, dynamic>> bookings) {
    double total = 0;
    for (var booking in bookings) {
      if (booking['totalAmount'] != null) {
        total += (booking['totalAmount'] as num).toDouble();
      }
    }
    return total;
  }
  
  void _animateStats({required int roomCount, required int bookingCount, required double revenue}) {
    const duration = Duration(milliseconds: 1500);
    
    int roomStep = (roomCount / 50).ceil();
    int bookingStep = (bookingCount / 50).ceil();
    double revenueStep = revenue / 50;
    
    Future.delayed(Duration(milliseconds: 300), () {
      var timer = Stream.periodic(Duration(milliseconds: 30), (i) => i);
      var subscription = timer.take(50).listen((i) {
        setState(() {
          _displayedRoomCount = math.min((i + 1) * roomStep, roomCount);
          _displayedBookingCount = math.min((i + 1) * bookingStep, bookingCount);
          _displayedRevenue = math.min((i + 1) * revenueStep, revenue);
        });
      });
      
      Future.delayed(duration, () {
        subscription.cancel();
        setState(() {
          _displayedRoomCount = roomCount;
          _displayedBookingCount = bookingCount;
          _displayedRevenue = revenue;
        });
      });
    });
  }

  void _logout() async {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => UserLogin(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: TweenAnimationBuilder(
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
            'Hotel Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchHotelProfile,
          ),
        ],
      ),
      drawer: _buildAnimatedDrawer(),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : Stack(
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
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome header
                              _buildWelcomeHeader(),
                              
                              SizedBox(height: 24),
                              
                              // Stats cards
                              _buildStatsCards(),
                              
                              SizedBox(height: 24),
                              
                              // Quick actions
                              _buildQuickActions(),
                              
                              SizedBox(height: 24),
                              
                              // Recent bookings
                              _buildRecentBookings(),
                              
                              SizedBox(height: 24),
                              
                              // Hotel info
                              _buildHotelInfo(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.green.shade800,
            Colors.green.shade600,
            Colors.green.shade400,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              "Loading your hotel dashboard...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.red.shade800, Colors.red.shade600],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 80,
              ),
              SizedBox(height: 24),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _fetchHotelProfile,
                icon: Icon(Icons.refresh),
                label: Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade800,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWelcomeHeader() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome back,",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "${_hotelProfile?['name'] ?? 'Your Hotel'}",
            style: TextStyle(
              fontSize: 32,
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
        ],
      ),
    );
  }
  
  Widget _buildStatsCards() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.hotel,
              title: "Rooms",
              value: _displayedRoomCount.toString(),
              color: Colors.blue,
            ),
            _buildDivider(),
            _buildStatItem(
              icon: Icons.book_online,
              title: "Bookings",
              value: _displayedBookingCount.toString(),
              color: Colors.orange,
            ),
            _buildDivider(),
            _buildStatItem(
              icon: Icons.attach_money,
              title: "Revenue",
              value: "\$${_displayedRevenue.toStringAsFixed(0)}",
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickActions() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 20,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.add_circle,
                label: "Add Room",
                color: Colors.green.shade400,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomManagementScreen(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.edit,
                label: "Edit Profile",
                color: Colors.blue.shade400,
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => 
                        HotelProfileEditPage(hotelProfile: _hotelProfile),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutCubic;
                        
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        
                        return SlideTransition(position: offsetAnimation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.book,
                label: "Bookings",
                color: Colors.orange.shade400,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentBookings() {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    final recentBookings = hotelProvider.bookings.take(3).toList();
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Bookings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingManagementScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "View All",
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            recentBookings.isNotEmpty
                ? Column(
                    children: recentBookings.map((booking) {
                      return _buildBookingItem(booking);
                    }).toList(),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No recent bookings",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedDrawer() {
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
                      radius: 40,
                      child: Image.network( _hotelProfile?['profileImageUrl'] ?? 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwLXFLbtIMfnOOGpk1LM0TlgAYJsOOl9TN1A&s' )
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _hotelProfile?['name'] ?? 'Your Hotel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
              },
              delay: 0,
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.hotel,
              title: 'Rooms',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomManagementScreen(),
                  ),
                );
              },
              delay: 100,
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.book_online,
              title: 'Bookings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingManagementScreen(),
                  ),
                );
              },
              delay: 200,
            ),
            _buildAnimatedDrawerItem(
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HotelProfileEditPage(hotelProfile: _hotelProfile),
                  ),
                );
              },
              delay: 300,
            ),
            Divider(color: Colors.white.withOpacity(0.3)),
            _buildAnimatedDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _logout,
              delay: 400,
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

  Widget _buildBookingItem(Map<String, dynamic> booking) {
    final startDate = booking['checkInDate'] is DateTime 
        ? booking['checkInDate'] 
        : booking['checkInDate']?.toDate() ?? DateTime.now();
    
    final endDate = booking['checkOutDate'] is DateTime 
        ? booking['checkOutDate'] 
        : booking['checkOutDate']?.toDate() ?? DateTime.now();
    
    final customerName = booking['customerName'] ?? 'Guest';
    final roomName = booking['roomName'] ?? 'Room';
    final amount = booking['totalAmount'] != null 
        ? '\$${(booking['totalAmount'] as num).toStringAsFixed(2)}' 
        : 'N/A';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$roomName • ${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelInfo() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hotel Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.green.shade800),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HotelProfileEditPage(hotelProfile: _hotelProfile),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.location_on,
              title: "Address",
              value: _hotelProfile?['address'] ?? 'Not specified',
            ),
            _buildInfoItem(
              icon: Icons.description,
              title: "Description",
              value: _hotelProfile?['description'] ?? 'No description available',
            ),
            _buildInfoItem(
              icon: Icons.location_city,
              title: "City",
              value: _hotelProfile?['city'] ?? 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.green.shade700,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.green.shade800,
          Colors.green.shade600,
          Colors.green.shade400,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Draw animated wave patterns
    _drawWave(
      canvas,
      size,
      animationValue,
      amplitude: 30,
      frequency: 0.01,
      horizontalOffset: 0,
      color: Colors.white.withOpacity(0.1),
    );

    _drawWave(
      canvas,
      size,
      animationValue + 0.5,
      amplitude: 40,
      frequency: 0.008,
      horizontalOffset: size.width * 0.5,
      color: Colors.white.withOpacity(0.05),
    );

    _drawWave(
      canvas,
      size,
      animationValue + 0.2,
      amplitude: 25,
      frequency: 0.015,
      horizontalOffset: size.width * 0.3,
      color: Colors.white.withOpacity(0.07),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double animationValue, {
    required double amplitude,
    required double frequency,
    required double horizontalOffset,
    required Color color,
  }) {
    final path = Path();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x++) {
      double y = math.sin((x * frequency) + (animationValue * math.pi * 2) + horizontalOffset) * amplitude;
      path.lineTo(x, size.height * 0.5 + y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
