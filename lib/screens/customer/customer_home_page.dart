import 'package:flutter/material.dart';

import 'package:roomfind/providers/customer_hotel_provider.dart';
import 'package:provider/provider.dart';
import 'hotel_detail_page.dart';
import 'package:roomfind/login_screen/user_login.dart';
class CustomerHomePage extends StatefulWidget {
  final String phoneNumber;

  CustomerHomePage({required this.phoneNumber});

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerProvider = Provider.of<CustomerHotelProvider>(context, listen: false);
      customerProvider.fetchCustomerProfile(widget.phoneNumber);
      customerProvider.fetchAllHotels();
    });
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
    // Log the customer name only when it changes
    final hotelProvider = Provider.of<CustomerHotelProvider>(context);
    if (hotelProvider.customerName != null) {
      print("Building Home Page. Current customer name: ${hotelProvider.customerName}");
    }

    return Scaffold(
      appBar: AppBar(
        title: Consumer<CustomerHotelProvider>(
          builder: (context, hotelProvider, child) {
            return Text("Welcome, ${hotelProvider.customerName}");
          },
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _showNameChangeDialog(context, hotelProvider);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout), // Logout button
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: "Enter City",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onPressed: () {
                    final city = _cityController.text.trim();
                    if (city.isNotEmpty) {
                      hotelProvider.fetchHotelsByCity(city);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter a city name.")),
                      );
                    }
                  },
                  child: Text("Search", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<CustomerHotelProvider>(
              builder: (context, hotelProvider, child) {
                return hotelProvider.hotels.isEmpty
                    ? Center(
                  child: Text(
                    "No hotels found.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: hotelProvider.hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = hotelProvider.hotels[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(hotel['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(hotel['address']),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HotelDetailPage(hotelId: hotel['hotelId']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNameChangeDialog(BuildContext context, CustomerHotelProvider hotelProvider) {
    final _nameController = TextEditingController(text: hotelProvider.customerName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Change Name"),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Enter new name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  hotelProvider.updateCustomerName(widget.phoneNumber, newName);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
}