import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/hotel_provider.dart';
import 'dart:math' as math;

class HotelProfileEditPage extends StatefulWidget {
  final Map<String, dynamic>? hotelProfile;

  HotelProfileEditPage({this.hotelProfile});

  @override
  _HotelProfileEditPageState createState() => _HotelProfileEditPageState();
}

class _HotelProfileEditPageState extends State<HotelProfileEditPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _checkInController;
  late TextEditingController _checkOutController;
  
  // Amenities
  List<String> _selectedAmenities = [];
  final List<String> _availableAmenities = [
    'WiFi', 'Parking', 'Pool', 'Gym', 'Restaurant', 
    'Room Service', 'Spa', 'Air Conditioning', 'TV',
    'Breakfast', 'Bar', 'Laundry', 'Pet Friendly'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _backgroundAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    
    // Initialize controllers with hotel profile data
    _nameController = TextEditingController(text: widget.hotelProfile?['name'] ?? '');
    _addressController = TextEditingController(text: widget.hotelProfile?['address'] ?? '');
    _descriptionController = TextEditingController(text: widget.hotelProfile?['description'] ?? '');
    _cityController = TextEditingController(text: widget.hotelProfile?['city'] ?? '');
    _phoneController = TextEditingController(text: widget.hotelProfile?['phoneNumber'] ?? '');
    _emailController = TextEditingController(text: widget.hotelProfile?['email'] ?? '');
    _websiteController = TextEditingController(text: widget.hotelProfile?['website'] ?? '');
    _checkInController = TextEditingController(text: widget.hotelProfile?['checkInTime'] ?? '14:00');
    _checkOutController = TextEditingController(text: widget.hotelProfile?['checkOutTime'] ?? '12:00');
    
    // Initialize amenities
    if (widget.hotelProfile?['amenities'] != null) {
      _selectedAmenities = List<String>.from(widget.hotelProfile!['amenities']);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveHotelProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      
      await hotelProvider.updateHotelProfile(
        name: _nameController.text,
        address: _addressController.text,
        description: _descriptionController.text,
        city: _cityController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
        amenities: _selectedAmenities,
        checkInTime: _checkInController.text,
        checkOutTime: _checkOutController.text,
        profileImage: _profileImage,
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hotel profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update hotel profile: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Edit Hotel Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(_backgroundAnimation.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    
                    SizedBox(height: 24),
                    
                    // Form
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Update Your Hotel Profile",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Make changes to your hotel information below",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImage != null 
                        ? FileImage(_profileImage!) 
                        : (widget.hotelProfile?['profileImageUrl'] != null 
                            ? NetworkImage(widget.hotelProfile!['profileImageUrl']) as ImageProvider 
                            : null),
                    child: _profileImage == null && widget.hotelProfile?['profileImageUrl'] == null
                        ? Icon(Icons.hotel, size: 60, color: Colors.green.shade700)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildForm() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              
              _buildAnimatedTextField(
                controller: _nameController,
                label: "Hotel Name",
                hint: "Enter your hotel name",
                icon: Icons.business,
                index: 0,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a hotel name";
                  }
                  return null;
                },
              ),
              
              _buildAnimatedTextField(
                controller: _addressController,
                label: "Address",
                hint: "Enter your hotel address",
                icon: Icons.location_on,
                index: 1,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter an address";
                  }
                  return null;
                },
              ),
              
              _buildAnimatedTextField(
                controller: _cityController,
                label: "City",
                hint: "Enter your hotel city",
                icon: Icons.location_city,
                index: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a city";
                  }
                  return null;
                },
              ),
              
              _buildAnimatedTextField(
                controller: _descriptionController,
                label: "Description",
                hint: "Enter your hotel description",
                icon: Icons.description,
                index: 3,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a description";
                  }
                  return null;
                },
              ),
              
              _buildAnimatedTextField(
                controller: _emailController,
                label: "Email (Optional)",
                hint: "Enter hotel email address",
                icon: Icons.email,
                index: 4,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Simple email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return "Please enter a valid email";
                    }
                  }
                  return null;
                },
              ),
              
              _buildAnimatedTextField(
                controller: _phoneController,
                label: "Phone Number (Optional)",
                hint: "Enter hotel phone number",
                icon: Icons.phone,
                index: 5,
                validator: (value) => null,
              ),
              
              _buildAnimatedTextField(
                controller: _websiteController,
                label: "Website (Optional)",
                hint: "Enter hotel website",
                icon: Icons.web,
                index: 6,
                validator: (value) => null,
              ),
              
              // Check-in/Check-out times
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedTextField(
                      controller: _checkInController,
                      label: "Check-in Time",
                      hint: "14:00",
                      icon: Icons.login,
                      index: 7,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Required";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildAnimatedTextField(
                      controller: _checkOutController,
                      label: "Check-out Time",
                      hint: "12:00",
                      icon: Icons.logout,
                      index: 7,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Required";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              // Amenities
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "Amenities",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: Colors.green.shade700,
                  );
                }).toList(),
              ),
              
              SizedBox(height: 24),
              
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int index,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 200)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(50 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(
                  icon,
                  color: Colors.green.shade600,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.green.shade600,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 2,
                  ),
                ),
                errorStyle: TextStyle(color: Colors.red.shade400),
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _saveHotelProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            shadowColor: Colors.green.withOpacity(0.5),
          ),
          child: Text(
            'Save Changes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.green.shade800,
          Colors.green.shade600,
          Colors.green.shade400,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Draw animated wave patterns
    _drawWave(
      canvas,
      size,
      animationValue,
      amplitude: 30,
      frequency: 0.01,
      horizontalOffset: 0,
      color: Colors.white.withOpacity(0.1),
    );

    _drawWave(
      canvas,
      size,
      animationValue + 0.5,
      amplitude: 40,
      frequency: 0.008,
      horizontalOffset: size.width * 0.5,
      color: Colors.white.withOpacity(0.05),
    );

    _drawWave(
      canvas,
      size,
      animationValue + 0.2,
      amplitude: 25,
      frequency: 0.015,
      horizontalOffset: size.width * 0.3,
      color: Colors.white.withOpacity(0.07),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double animationValue, {
    required double amplitude,
    required double frequency,
    required double horizontalOffset,
    required Color color,
  }) {
    final path = Path();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x++) {
      double y = math.sin((x * frequency) + (animationValue * math.pi * 2) + horizontalOffset) * amplitude;
      path.lineTo(x, size.height * 0.5 + y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


