import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/hotel_provider.dart';
import 'package:roomfind/screens/dashboard_screen.dart';
import 'dart:math' as math;

class HotelSetupScreen extends StatefulWidget {
  final String phoneNumber;

  HotelSetupScreen({required this.phoneNumber});

  @override
  _HotelSetupScreenState createState() => _HotelSetupScreenState();
}

class _HotelSetupScreenState extends State<HotelSetupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _checkInController = TextEditingController(text: '14:00');
  final _checkOutController = TextEditingController(text: '12:00');
  
  List<String> _selectedAmenities = [];
  final List<String> _availableAmenities = [
    'WiFi', 'Parking', 'Breakfast', 'Pool', 'Gym', 'Restaurant', 'Room Service', 'AC'
  ];

  bool _isLoading = false;
  String? _errorMessage;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  
  // Current form field focus
  int _currentFieldIndex = 0;
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Setup animations
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    // Start animation
    _animationController.forward();
    
    // Setup focus listeners
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() {
            _currentFieldIndex = i;
          });
        }
      });
    }
    
    // Set initial focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch userId
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      await hotelProvider.fetchUserId(widget.phoneNumber);

      // Call the HotelProvider
      await hotelProvider.createHotelProfile(
        name: _nameController.text,
        address: _addressController.text,
        description: _descriptionController.text,
        city: _cityController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        website: _websiteController.text,
        checkInTime: _checkInController.text,
        checkOutTime: _checkOutController.text,
        amenities: _selectedAmenities,
      );

      // Success animation
      await _playSuccessAnimation();

      // Redirect to the DashboardScreen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HotelDashboard(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to create hotel profile: ${e.toString()}";
      });
      
      // Shake animation for error
      _playErrorAnimation();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _playSuccessAnimation() async {
    // Reset and play animation
    _animationController.reset();
    await _animationController.forward();
  }
  
  void _playErrorAnimation() {
    // Shake animation
    final shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    final offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: shakeController,
      curve: ShakeCurve(count: 8, intensity: 0.05),
    ));
    
    final Widget errorContainer = SlideTransition(
      position: offsetAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _errorMessage ?? "An error occurred",
          style: TextStyle(color: Colors.red.shade800),
        ),
      ),
    );
    
    // Show error with shake animation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: errorContainer,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    
    shakeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            "Create Your Hotel",
            style: TextStyle(
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
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.green.shade800,
              Colors.green.shade600,
              Colors.green.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: RotationTransition(
                                turns: _rotateAnimation,
                                child: Icon(
                                  Icons.hotel,
                                  size: 80,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Hotel Name
                            _buildAnimatedFormField(
                              controller: _nameController,
                              focusNode: _focusNodes[0],
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
                            
                            // City
                            _buildAnimatedFormField(
                              controller: _cityController,
                              focusNode: _focusNodes[1],
                              label: "City",
                              hint: "Enter your hotel's city",
                              icon: Icons.location_city,
                              index: 1,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter a city";
                                }
                                return null;
                              },
                            ),
                            
                            // Hotel Address
                            _buildAnimatedFormField(
                              controller: _addressController,
                              focusNode: _focusNodes[2],
                              label: "Hotel Address",
                              hint: "Enter your hotel address",
                              icon: Icons.location_on,
                              index: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter a hotel address";
                                }
                                return null;
                              },
                            ),
                            
                            // Hotel Description
                            _buildAnimatedFormField(
                              controller: _descriptionController,
                              focusNode: _focusNodes[3],
                              label: "Hotel Description",
                              hint: "Enter a brief description of your hotel",
                              icon: Icons.description,
                              index: 3,
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter a hotel description";
                                }
                                return null;
                              },
                            ),
                            
                            // Email
                            _buildAnimatedFormField(
                              controller: _emailController,
                              focusNode: _focusNodes[4],
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
                            
                            // Phone
                            _buildAnimatedFormField(
                              controller: _phoneController,
                              focusNode: _focusNodes[5],
                              label: "Phone Number (Optional)",
                              hint: "Enter hotel phone number",
                              icon: Icons.phone,
                              index: 5,
                              validator: (value) => null,
                            ),
                            
                            // Website
                            _buildAnimatedFormField(
                              controller: _websiteController,
                              focusNode: _focusNodes[6],
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
                                  child: _buildAnimatedFormField(
                                    controller: _checkInController,
                                    focusNode: _focusNodes[7],
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
                                  child: _buildAnimatedFormField(
                                    controller: _checkOutController,
                                    focusNode: _focusNodes[7], // Same focus node as check-in
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
                            
                            const SizedBox(height: 32),
                            
                            // Submit Button
                            Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _isLoading ? 60 : 220,
                                height: 60,
                                child: _isLoading
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.green.shade700,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shadowColor: Colors.green.shade200,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 24,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.hotel),
                                            SizedBox(width: 12),
                                            Text(
                                              "Create Hotel",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ),
                            ),)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required int index,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    final isActive = _currentFieldIndex == index;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 500 + (index * 200)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(50 * (1 - value), 0),
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive ? Colors.green.shade50 : Colors.transparent,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.green.shade200.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: isActive ? Colors.green.shade700 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isActive ? Colors.green.shade700 : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.green.shade700,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isActive ? Colors.green.shade50 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade900,
            ),
            maxLines: maxLines,
            validator: validator,
            onFieldSubmitted: (_) {
              if (index < _focusNodes.length - 1) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                _submit();
              }
            },
          ),
        ),
      ),
    );
  }
}

// Custom shake curve for error animation
class ShakeCurve extends Curve {
  final int count;
  final double intensity;

  const ShakeCurve({this.count = 3, this.intensity = 0.1});

  @override
  double transformInternal(double t) {
    return math.sin(count * 2 * math.pi * t) * intensity * (1 - t);
  }
}
