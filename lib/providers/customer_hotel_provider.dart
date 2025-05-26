import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerHotelProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _rooms = [];
  String? _customerName;
  String? _customerId;
  String? _customerPhone;
  bool _isLoading = false;

  // Getters
  List<Map<String, dynamic>> get hotels => _hotels;
  List<Map<String, dynamic>> get rooms => _rooms;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;
  String? get customerId => _customerId;
  bool get isLoading => _isLoading;

  

  Future<void> fetchHotelsByCity(String city, {DateTime? checkIn, DateTime? checkOut}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _hotels.clear();
      
      Query query = _firestore.collection('hotels');
      
      // Only apply city filter if city is not empty
      if (city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }
      
      final snapshot = await query.get();
      
      List<Map<String, dynamic>> newHotels = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data.addAll({'hotelId': doc.id});
        newHotels.add(data);
      }
      
      _hotels = newHotels;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching hotels by city: $e');
      _hotels = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllHotels() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _hotels.clear();
      
      final snapshot = await _firestore
          .collection('hotels')
          .get();
      
      List<Map<String, dynamic>> newHotels = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['hotelId'] = doc.id;
        newHotels.add(data as Map<String, dynamic>);
      }
      
      _hotels = newHotels;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching all hotels: $e');
      _hotels = [];
      _isLoading = false;
      notifyListeners();
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
        _customerPhone = userData['phoneNumber'] ?? phoneNumber;
        _customerId = userData['userId'] ?? '';  // Add null check here
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
