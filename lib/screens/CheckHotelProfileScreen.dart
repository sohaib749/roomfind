import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/hotel_provider.dart';
import 'package:roomfind/screens/hotel_setup_screen.dart';
import 'package:roomfind/screens/dashboard_screen.dart';

class CheckHotelProfileScreen extends StatelessWidget {
  final String phoneNumber; // Accept phoneNumber as a parameter

  CheckHotelProfileScreen({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);

    return FutureBuilder(
      future: hotelProvider.fetchUserId(phoneNumber).then((_) => hotelProvider.fetchHotelProfile()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // If the user doesn't have a hotel profile, redirect to Hotel Setup Screen
          return HotelSetupScreen(phoneNumber: phoneNumber);
        } else {
          // If the user has a hotel profile, redirect to Hotel Dashboard
          return HotelDashboard();
        }
      },
    );
  }
}