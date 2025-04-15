import 'package:flutter/material.dart';

class HotelOwnerHomeScreen extends StatelessWidget {
  const HotelOwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hotel Owner Home"),
      ),
      body: const Center(
        child: Text("Welcome, Hotel Owner!"),
      ),
    );
  }
}
