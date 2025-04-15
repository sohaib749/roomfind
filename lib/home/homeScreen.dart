import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to ROOMQUEST!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Explore your dream rooms!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 40),
            //ElevatedButton(
            //   onPressed: () {
            // Logic to log out or navigate to another screen
            // For now, we can just go back to the login screen
            //   Navigator.of(context).pushReplacement(
            //   MaterialPageRoute(builder: (context) => UserLogin()),
            //);
            // },
            //child: Text('Log Out'),
            // ),
          ],
        ),
      ),
    );
  }
}
