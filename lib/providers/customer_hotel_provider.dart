import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerHotelProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _rooms = [];
  String _customerName = '';

  List<Map<String, dynamic>> get hotels => _hotels;
  List<Map<String, dynamic>> get rooms => _rooms;
  String get customerName => _customerName;

  Future<void> fetchAllHotels() async {
    try {
      final snapshot = await _firestore.collection('hotels').get();

      _hotels = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'hotelId': doc.id,
          'name': data['name'],
          'address': data['address'],
          'city': data['city'],
          'description': data['description'],
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching all hotels: $e');
    }
  }

  Future<void> fetchHotelsByCity(String city) async {
    try {
      final snapshot = await _firestore
          .collection('hotels')
          .where('city', isEqualTo: city)
          .get();

      _hotels = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'hotelId': doc.id,
          'name': data['name'],
          'address': data['address'],
          'city': data['city'],
          'description': data['description'],
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching hotels: $e');
    }
  }

  Future<void> fetchRoomsByHotelId(String hotelId) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: hotelId)
          .get();

      _rooms = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'roomId': doc.id,
          'hotelId': data['hotelId'],
          'roomNumber': data['roomNumber'],
          'type': data['type'],
          'price': data['price'],
          'imageUrl': data['imageUrl'] ?? [],
          'imageUrls': data['imageUrls'] ?? [],
          'amenities': data['amenities'] ?? [],
          'status': data['status'],
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching rooms by hotelId: $e');
    }
  }

  Future<void> fetchCustomerProfile(String phoneNumber) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        _customerName = userData['name'] ?? 'Customer';
        notifyListeners();
      } else {
        print("No user found with phone number: $phoneNumber");
      }
    } catch (e) {
      print('Error fetching customer profile: $e');
    }
  }

  Future<void> updateCustomerName(String phoneNumber, String newName) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userId = snapshot.docs.first.id;
        await _firestore.collection('users').doc(userId).update({'name': newName});
        _customerName = newName;
        notifyListeners();
      } else {
        print("No user found with phone number: $phoneNumber");
      }
    } catch (e) {
      print('Error updating customer name: $e');
    }
  }
}