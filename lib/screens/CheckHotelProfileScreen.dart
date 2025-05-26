import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/hotel_provider.dart';
import 'package:roomfind/screens/hotel_setup_screen.dart';
import 'package:roomfind/screens/dashboard_screen.dart';

class CheckHotelProfileScreen extends StatelessWidget {
  final String phoneNumber;

  CheckHotelProfileScreen({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);

    return Scaffold(
      body: FutureBuilder(
        future: hotelProvider.fetchUserId(phoneNumber).then((_) => hotelProvider.fetchHotelProfile()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 20),
                  Text("Checking your hotel profile...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            print("Error in CheckHotelProfileScreen: ${snapshot.error}");
            
            // If the error message indicates no hotel association, go to setup
            if (snapshot.error.toString().contains("not associated with any hotel")) {
              // Short delay before navigation to show the error briefly
              Future.delayed(Duration(milliseconds: 100), () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HotelSetupScreen(phoneNumber: phoneNumber),
                  ),
                );
              });
              
              return Center(
                child: Text("No hotel profile found. Redirecting to setup...",
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              );
            }
            
            // For other errors, show the error message
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text("Error: ${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => HotelSetupScreen(phoneNumber: phoneNumber),
                          ),
                        );
                      },
                      child: Text("Create Hotel Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Successfully fetched hotel profile, go to dashboard
            Future.delayed(Duration.zero, () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HotelDashboard(),
                ),
              );
            });
            
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          }
        },
      ),
    );
  }
}
