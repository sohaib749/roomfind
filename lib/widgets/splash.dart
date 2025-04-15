import 'package:flutter/material.dart';
import 'dart:async';
import 'package:roomfind/login_screen/user_login.dart'; // Import the login page
import 'package:roomfind/home/homeScreen.dart'; // Import the home page

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoggedIn = false; // Simulate login state

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  Future<void> _startTimer() async {
    // Wait for 3 seconds before navigating to the next screen
    await Future.delayed(Duration(seconds: 3));
    _openNextScreen();
  }

  void _openNextScreen() {
    if (isLoggedIn) {
      // If the user is logged in, navigate to HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // If the user is not logged in, navigate to UserLogin
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => UserLogin()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            Text(
              'ROOMQUEST',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your Adventure Awaits!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
