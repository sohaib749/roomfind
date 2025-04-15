import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hotel_provider.dart';
import 'package:roomfind/screens/room_management_page.dart';
import 'package:roomfind/screens/booking_management_page.dart';
import 'package:roomfind/login_screen/user_login.dart';

class HotelDashboard extends StatefulWidget {
  @override
  _HotelDashboardState createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _hotelProfile;

  @override
  void initState() {
    super.initState();
    _fetchHotelProfile();
  }

  Future<void> _fetchHotelProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {

      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      final hotelProfile = await hotelProvider.fetchHotelProfile();

      setState(() {
        _hotelProfile = hotelProfile;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load hotel profile: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() async {

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => UserLogin(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          'Hotel Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchHotelProfile,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Hotel Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.room_service, color: Colors.green[800]),
              title: Text('Room Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.book_online, color: Colors.green[800]),
              title: Text('Booking Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingManagementScreen(),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.green[800]),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Name
            Text(
              "Welcome to ${_hotelProfile?['name'] ?? 'Your Hotel'}",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[900], // Dark green text
              ),
            ),
            SizedBox(height: 20),

            //  Image (Placeholder)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green[100], // Placeholder color
              ),
              child: Center(
                child: Icon(
                  Icons.hotel,
                  size: 100,
                  color: Colors.green[800],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Hotel Address
            _buildInfoCard(
              icon: Icons.location_on,
              title: "Address",
              value: _hotelProfile?['address'] ?? 'Not available',
            ),
            SizedBox(height: 16),

            // Hotel Description
            _buildInfoCard(
              icon: Icons.description,
              title: "Description",
              value: _hotelProfile?['description'] ?? 'Not available',
            ),
            SizedBox(height: 16),

            // Contact Information
            _buildInfoCard(
              icon: Icons.phone,
              title: "Contact",
              value: _hotelProfile?['contact'] ?? 'Not available',
            ),
            SizedBox(height: 16),

            // Amenities

          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.green[800]),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}