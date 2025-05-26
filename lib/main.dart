import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/customer_hotel_provider.dart';
import 'package:roomfind/screens/customer/customer_home_page.dart';
import 'package:roomfind/widgets/splash.dart';
import 'package:roomfind/providers/hotel_provider.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // Use correct Cloudinary package

// Initialize Cloudinary instance
final cloudinary = CloudinaryPublic("dop8d9mig", "hotel_room_images", cache: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HotelProvider(cloudinary)), // Register HotelProvider
        Provider.value(value: cloudinary),
        ChangeNotifierProvider(create: (_) => CustomerHotelProvider()),//  Cloudinary instance
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner
      title: 'RoomFind App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: CustomerHomePage(phoneNumber: '03085265734'), //  initial screen
    );
  }
}
