import 'dart:io';
import 'dart:convert';
import 'package:logger/logger.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class HotelProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryPublic cloudinary;
  final _logger = Logger();
  String? _hotelId;
  String? _userId;
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _bookings = [];

  String? get hotelId => _hotelId;

  List<Map<String, dynamic>> get rooms => _rooms;

  List<Map<String, dynamic>> get bookings => _bookings;


  HotelProvider(this.cloudinary);


  Future<void> fetchUserId(String phoneNumber) async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception("User not found in Firestore");
      }

      _userId = userSnapshot.docs.first.id;
      notifyListeners();
    } catch (e) {
      print('Error fetching userId: $e');
      rethrow;
    }
  }


  Future<void> createHotelProfile({
    required String name,
    required String address,
    required String description,
    required String city,
    String? email,
    String? phoneNumber,
    String? website,
    required String checkInTime,
    required String checkOutTime,
    List<String> amenities = const [],
  }) async {
    if (_userId == null) {
      throw Exception("User ID not found. Please try again.");
    }

    try {
      // Create hotel profile in Firestore
      final hotelRef = await _firestore.collection('hotels').add({
        'userId': _userId,
        'name': name,
        'address': address,
        'description': description,
        'city': city,
        'email': email ?? "",
        'phoneNumber': phoneNumber ?? "",
        'website': website ?? "",
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'amenities': amenities,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Store the hotel ID
      _hotelId = hotelRef.id;
      
      // Update the user document with the hotel ID reference
      await _firestore.collection('users').doc(_userId).update({
        'hotelId': _hotelId,
        'role': 'hotelOwner'
      });
      
      notifyListeners();
    } catch (e) {
      _logger.e("Error creating hotel profile: $e");
      throw e;
    }
  }


  Future<Map<String, dynamic>?> fetchHotelProfile() async {
    try {
      if (_userId == null) throw Exception("User ID not found");

      // Get the user document
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      
      if (!userDoc.exists) {
        throw Exception("User not found");
      }
      
      // Check if user has a hotelId
      if (userDoc.data()?['hotelId'] == null) {
        // Try to find a hotel created by this user
        final hotelQuery = await _firestore
            .collection('hotels')
            .where('userId', isEqualTo: _userId)
            .limit(1)
            .get();
            
        if (hotelQuery.docs.isEmpty) {
          throw Exception("User is not associated with any hotel");
        }
        
        // Found a hotel, update the user document
        _hotelId = hotelQuery.docs.first.id;
        await _firestore.collection('users').doc(_userId).update({
          'hotelId': _hotelId
        });
      } else {
        _hotelId = userDoc.data()!['hotelId'];
      }

      // Get the hotel document
      final hotelDoc = await _firestore.collection('hotels')
          .doc(_hotelId)
          .get();
          
      if (!hotelDoc.exists) throw Exception("Hotel not found");

      return hotelDoc.data();
    } catch (e) {
      print('Error fetching hotel profile: $e');
      rethrow;
    }
  }


  Future<void> fetchRooms() async {
    if (_hotelId == null) throw Exception("Hotel ID not found");

    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: _hotelId)
          .get();

      _rooms = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching rooms: $e');
      rethrow;
    }
  }


  Future<void> addRoom(Map<String, dynamic> room, List<File> imageFiles) async {
    if (_hotelId == null) throw Exception("Hotel ID not found");

    try {

      List<String> imageUrls = [];
      for (final imageFile in imageFiles) {
        final imageUrl = await _uploadImageToCloudinary(imageFile);
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        } else {
          throw Exception("Failed to upload image to Cloudinary");
        }
      }


      room['imageUrls'] = imageUrls;
      room['hotelId'] = _hotelId;


      final roomRef = await _firestore.collection('rooms').add(room);


      room['id'] = roomRef.id;
      _rooms.add(room);
      notifyListeners();
    } catch (e) {
      print('Error adding room: $e');
      rethrow;
    }
  }
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    return await _uploadImageToCloudinary(imageFile);
  }


  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }
  // Update room status
  Future<void> updateRoomStatus(String roomId, String newStatus) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({'status': newStatus});
      await fetchRooms();
    } catch (e) {
      print('Error updating room status: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBookingsForRoom(String roomNumber) async {
    if (_hotelId == null) throw Exception("Hotel ID not found");

    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: _hotelId)
          .where('roomNumber', isEqualTo: roomNumber)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['startDate'] == null || data['endDate'] == null) {
          print("Warning: Booking data contains null values: $data");
          return null;
        }
        return data;
      }).whereType<Map<String, dynamic>>().toList(); // Remove null values
    } catch (e) {
      print('Error fetching bookings for room: $e');
      return [];
    }
  }
  Future<bool> isRoomNumberUnique(String roomNumber) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('roomNumber', isEqualTo: roomNumber)
          .get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      print("Error checking room number uniqueness: $e");
      return false;
    }
  }

  // update room details
  Future<void> updateRoom(String roomId, Map<String, dynamic> updatedRoom) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update(updatedRoom);
      await fetchRooms();
    } catch (e) {
      print('Error updating room: $e');
      rethrow;
    }
  }


  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).delete();


      _rooms.removeWhere((room) => room['id'] == roomId);
      notifyListeners();
    } catch (e) {
      print('Error deleting room: $e');
      rethrow;
    }
  }


  Future<void> fetchBookings() async {
    if (_hotelId == null) {
      print("Error: Hotel ID is null!");
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: _hotelId)
          .get();

      _bookings = snapshot.docs.map((doc) {
        final data = doc.data();


        if (data['date'] == null || data['roomNumber'] == null || data['status'] == null) {
          print("Warning: Booking data contains null values: $data");
          return null;
        }

        return data;
      }).whereType<Map<String, dynamic>>().toList(); // Remove null values

      notifyListeners();
    } catch (e) {
      print('Error fetching bookings: $e');
      rethrow;
    }
  }


  Future<void> addBooking(Map<String, dynamic> booking) async {
    if (_hotelId == null) throw Exception("Hotel ID not found");

    try {
      // Prepare the booking document
      final bookingData = {
        'guestCnic': booking['guestCnic'], // From text field
        'roomNumber': booking['roomNumber'],
        'roomId': booking['roomId'],
        'status': 'Confirmed',
        'hotelId': _hotelId,
        'startDate': booking['startDate'], // Already Timestamp from dialog
        'endDate': booking['endDate'],     // Already Timestamp from dialog
        'createdAt': Timestamp.now(),
        'bookingType': booking['bookingType'] ?? 'Offline',
        'lastUpdated': Timestamp.now(),
      };

      // Add to Firestore
      await _firestore.collection('bookings').add(bookingData);

      // Refresh local data
      await fetchRooms();
      notifyListeners();

    } catch (e) {
      print('Error adding booking: $e');
      rethrow;
    }
  }
  // Add to HotelProvider class

  Future<List<Map<String, dynamic>>> getBookingsForDateRange(
      String roomId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['startDate'] = (data['startDate'] as Timestamp).toDate();
        data['endDate'] = (data['endDate'] as Timestamp).toDate();
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching bookings for date range: $e');
      return [];
    }
  }
// In your HotelProvider class
  Future<List<Map<String, dynamic>>> getBookingsForWeek(
      String hotelId,
      DateTime startDate,
      DateTime endDate
      ) async {
    try {
      final query = FirebaseFirestore.instance
          .collection('bookings')
          .where('hotelId', isEqualTo: hotelId)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'startDate': (data['startDate'] as Timestamp).toDate(),
          'endDate': (data['endDate'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }
  // Add these methods to your HotelProvider class

  Future<List<Map<String, dynamic>>> getAvailableRooms(DateTime date) async {
    if (_hotelId == null) return [];

    try {
      final rooms = await _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: _hotelId)
          .get();

      final availableRooms = <Map<String, dynamic>>[];

      for (final room in rooms.docs) {
        final roomData = room.data();
        roomData['id'] = room.id;

        // Check availability for this specific date
        final availability = await getRoomAvailability(room.id, date, 1);
        if (availability[date] ?? true) {
          availableRooms.add(roomData);
        }
      }

      return availableRooms;
    } catch (e) {
      print('Error getting available rooms: $e');
      return [];
    }
  }

  Future<bool> isRoomAvailable(String roomId, DateTime startDate, DateTime endDate) async {
    try {
      // Get availability for the entire date range
      final days = endDate.difference(startDate).inDays + 1;
      final availability = await getRoomAvailability(roomId, startDate, days);

      // Check if all dates in range are available
      for (var date = startDate;
      date.isBefore(endDate.add(Duration(days: 1)));
      date = date.add(Duration(days: 1))) {
        if (!(availability[date] ?? false)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking room availability: $e');
      return false;
    }
  }

// Your existing method with the fixes
  Future<Map<DateTime, bool>> getRoomAvailability(
      String roomId, DateTime startDate, int days) async {
    final availability = <DateTime, bool>{};
    final endDate = startDate.add(Duration(days: days - 1));

    // Initialize all dates as available
    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      availability[date] = true;
    }

    try {
      // Get all bookings for this room that overlap with our date range
      final bookings = await _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      // Mark booked dates
      for (final booking in bookings.docs) {
        final bookingData = booking.data();
        final bookingStart = (bookingData['startDate'] as Timestamp).toDate();
        final bookingEnd = (bookingData['endDate'] as Timestamp).toDate();

        for (var date = bookingStart;
        date.isBefore(bookingEnd.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
          if (date.isAfter(startDate.subtract(Duration(days: 1))) &&
              date.isBefore(endDate.add(Duration(days: 1)))) {
            availability[date] = false;
          }
        }
      }
    } catch (e) {
      print('Error checking room availability: $e');
    }

    return availability;
  }
  // Add to your HotelProvider class
  List<Map<String, dynamic>> cachedBookings = [];
  bool _isBookingCacheValid = false;

  Future<void> cacheBookings() async {
    if (_hotelId == null) return;

    try {
      final snapshot = await _firestore.collection('bookings')
          .where('hotelId', isEqualTo: _hotelId)
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
          .get();

      cachedBookings = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'startDate': (data['startDate'] as Timestamp).toDate(),
          'endDate': (data['endDate'] as Timestamp).toDate(),
        };
      }).toList();

      _isBookingCacheValid = true;
      notifyListeners();
    } catch (e) {
      print('Error caching bookings: $e');
      _isBookingCacheValid = false;
    }
  }

  Future<void> ensureBookingsLoaded() async {
    if (!_isBookingCacheValid) {
      await cacheBookings();
    }
  }

  // Add to your HotelProvider class
  String? get currentHotelId => _hotelId;

  // Setter for hotelId with notification
  set currentHotelId(String? value) {
    if (_hotelId != value) {
      _hotelId = value;
      notifyListeners();
    }
  }


  Future<void> ensureHotelIdLoaded() async {
    try {
      // Return if already loaded
      if (_hotelId != null && _hotelId!.isNotEmpty) return;

      // Try to get from rooms collection
      final roomsSnapshot = await _firestore.collection('rooms')
          .where('hotelId', isNotEqualTo: null)
          .limit(1)
          .get();

      if (roomsSnapshot.docs.isNotEmpty) {
        final hotelId = roomsSnapshot.docs.first.get('hotelId') as String?;
        if (hotelId != null) {
          currentHotelId = hotelId;
          return;
        }
      }

      // Fallback to hotels collection
      final hotelsSnapshot = await _firestore.collection('hotels')
          .limit(1)
          .get();

      if (hotelsSnapshot.docs.isNotEmpty) {
        currentHotelId = hotelsSnapshot.docs.first.id;
        return;
      }

      // Final fallback
      _logger.w('No hotelId found in database');
      currentHotelId = null;
    } catch (e) {
      _logger.e('Error loading hotelId', error: e);
      currentHotelId = null;
    }
  }

  Future<String?> getHotelIdForRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        final hotelId = doc.get('hotelId') as String?;
        if (hotelId != null) {
          currentHotelId = hotelId;
          return hotelId;
        }
      }

      await ensureHotelIdLoaded();
      return _hotelId;
    } catch (e) {
      _logger.e('Error getting hotelId for room $roomId', error: e);
      await ensureHotelIdLoaded();
      return _hotelId;
    }
  }



  Future<void> addOnlineBooking({
    required String roomId,
    required String roomNumber,
    required String hotelId,
    required DateTime startDate,
    required DateTime endDate,
    required String guestName,
    required String guestCnic,
    required String guestPhone,
    required String userId,
    required String paymentMethod,
  }) async {
    try {
      // First verify availability again (in case something changed)
      final isAvailable = await isRoomAvailable(roomId, startDate, endDate);
      if (!isAvailable) {
        throw Exception('Room is no longer available for the selected dates');
      }

      final bookingData = {
        'roomId': roomId,
        'roomNumber': roomNumber,
        'hotelId': hotelId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'guestName': guestName,
        'guestCnic': guestCnic,
        'guestPhone': guestPhone,
        'userId': userId,
        'paymentMethod': paymentMethod,
        'status': 'Confirmed',
        'createdAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      };

      await _firestore.collection('bookings').add(bookingData);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding online booking: $e');
      rethrow;
    }
  }
  Future<String> _resolveDefaultHotelId() async {
    try {
      final snapshot = await _firestore.collection('hotels').limit(1).get();
      return snapshot.docs.first.id;
    } catch (e) {
      _logger.e('Could not resolve default hotel', error: e);
      return 'default_hotel_id';
    }
  }

  Future<List<DateTime>> getUnavailableDates(String roomId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final unavailableDates = <DateTime>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final start = (data['startDate'] as Timestamp).toDate();
        final end = (data['endDate'] as Timestamp).toDate();

        // Add all dates in the booking range to unavailable dates
        for (var date = start;
        date.isBefore(end.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
          unavailableDates.add(date);
        }
      }
      return unavailableDates;
    } catch (e) {
      print('Error getting unavailable dates: $e');
      return [];
    }
  }

  // Update hotel profile
  Future<void> updateHotelProfile({
    required String name,
    required String address,
    required String description,
    required String city,
    String? phoneNumber,
    String? email,
    String? website,
    List<String>? amenities,
    String? checkInTime,
    String? checkOutTime,
    File? profileImage,
  }) async {
    try {
      if (_hotelId == null) {
        throw Exception("Hotel ID not found. Please try again.");
      }
      
      // Prepare update data
      final Map<String, dynamic> updateData = {
        'name': name,
        'address': address,
        'description': description,
        'city': city,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add optional fields if provided
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (email != null) updateData['email'] = email;
      if (website != null) updateData['website'] = website;
      if (amenities != null) updateData['amenities'] = amenities;
      if (checkInTime != null) updateData['checkInTime'] = checkInTime;
      if (checkOutTime != null) updateData['checkOutTime'] = checkOutTime;
      
      // Upload profile image if provided
      if (profileImage != null) {
        try {
          final imageUrl = await _uploadImageToCloudinary(profileImage);
          if (imageUrl != null) {
            updateData['profileImageUrl'] = imageUrl;
          }
        } catch (e) {
          _logger.w('Failed to upload profile image: $e');
          // Continue with update even if image upload fails
        }
      }
      
      // Update hotel profile in Firestore
      await _firestore.collection('hotels').doc(_hotelId).update(updateData);
      
      // Log successful update
      _logger.i('Hotel profile updated successfully: $_hotelId');
      
      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      _logger.e('Error updating hotel profile: $e');
      
      // Provide more specific error messages based on the exception
      if (e is FirebaseException) {
        if (e.code == 'not-found') {
          throw Exception("Hotel profile not found. Please create a profile first.");
        } else if (e.code == 'permission-denied') {
          throw Exception("You don't have permission to update this hotel profile.");
        } else {
          throw Exception("Database error: ${e.message}");
        }
      } else {
        throw Exception("Failed to update hotel profile: ${e.toString()}");
      }
    }
  }

  // Get hotel statistics
  Future<Map<String, dynamic>> getHotelStatistics() async {
    if (_hotelId == null) throw Exception("Hotel ID not found");
    
    try {
      // Get total rooms
      final roomsSnapshot = await _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: _hotelId)
          .get();
      
      final totalRooms = roomsSnapshot.docs.length;
      
      // Get available rooms
      final availableRooms = roomsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'Available')
          .length;
      
      // Get current bookings
      final now = DateTime.now();
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: _hotelId)
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();
      
      final currentBookings = bookingsSnapshot.docs.length;
      
      // Calculate occupancy rate
      final occupancyRate = totalRooms > 0 
          ? ((totalRooms - availableRooms) / totalRooms * 100).toStringAsFixed(1) 
          : '0';
      
      // Get revenue (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final recentBookingsSnapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: _hotelId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      double monthlyRevenue = 0;
      for (var doc in recentBookingsSnapshot.docs) {
        final data = doc.data();
        if (data['totalAmount'] != null) {
          monthlyRevenue += (data['totalAmount'] as num).toDouble();
        }
      }
      
      return {
        'totalRooms': totalRooms,
        'availableRooms': availableRooms,
        'currentBookings': currentBookings,
        'occupancyRate': '$occupancyRate%',
        'monthlyRevenue': monthlyRevenue,
      };
    } catch (e) {
      _logger.e('Error getting hotel statistics: $e');
      rethrow;
    }
  }

  // Get popular room types
  Future<List<Map<String, dynamic>>> getPopularRoomTypes() async {
    if (_hotelId == null) throw Exception("Hotel ID not found");
    
    try {
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: _hotelId)
          .get();
      
      // Count bookings by room type
      final Map<String, int> roomTypeCount = {};
      
      for (var doc in bookingsSnapshot.docs) {
        final roomId = doc.data()['roomId'];
        if (roomId != null) {
          final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
          if (roomDoc.exists) {
            final roomType = roomDoc.data()?['type'];
            if (roomType != null) {
              roomTypeCount[roomType] = (roomTypeCount[roomType] ?? 0) + 1;
            }
          }
        }
      }
      
      // Convert to list and sort by popularity
      final List<Map<String, dynamic>> popularRoomTypes = roomTypeCount.entries
          .map((entry) => {
                'type': entry.key,
                'bookings': entry.value,
              })
          .toList();
      
      popularRoomTypes.sort((a, b) => b['bookings'].compareTo(a['bookings']));
      
      return popularRoomTypes;
    } catch (e) {
      _logger.e('Error getting popular room types: $e');
      return [];
    }
  }

  // Get booking trends
  Future<Map<String, int>> getBookingTrends() async {
    if (_hotelId == null) throw Exception("Hotel ID not found");
    
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
      
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: _hotelId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();
      
      // Group bookings by month
      final Map<String, int> monthlyBookings = {};
      
      for (var doc in bookingsSnapshot.docs) {
        final createdAt = doc.data()['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthlyBookings[monthKey] = (monthlyBookings[monthKey] ?? 0) + 1;
        }
      }
      
      return monthlyBookings;
    } catch (e) {
      _logger.e('Error getting booking trends: $e');
      return {};
    }
  }

  // Export hotel data
  Future<String> exportHotelData() async {
    if (_hotelId == null) throw Exception("Hotel ID not found");
    
    try {
      // Get hotel profile
      final hotelDoc = await _firestore.collection('hotels').doc(_hotelId).get();
      final hotelData = hotelDoc.data() ?? {};
      
      // Get rooms
      final roomsSnapshot = await _firestore
          .collection('rooms')
          .where('hotelId', isEqualTo: _hotelId)
          .get();
      
      final roomsData = roomsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Get bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('hotelId', isEqualTo: _hotelId)
          .get();
      
      final bookingsData = bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Combine all data
      final exportData = {
        'hotel': hotelData,
        'rooms': roomsData,
        'bookings': bookingsData,
        'exportDate': DateTime.now().toIso8601String(),
      };
      
      // Convert to JSON
      return jsonEncode(exportData);
    } catch (e) {
      _logger.e('Error exporting hotel data: $e');
      throw Exception("Failed to export hotel data: ${e.toString()}");
    }
  }
}
