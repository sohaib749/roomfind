import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/providers/hotel_provider.dart';
import 'package:roomfind/screens/dashboard_screen.dart';

class HotelSetupScreen extends StatefulWidget {
  final String phoneNumber;

  HotelSetupScreen({required this.phoneNumber});

  @override
  _HotelSetupScreenState createState() => _HotelSetupScreenState();
}

class _HotelSetupScreenState extends State<HotelSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

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
      );

      // Redirect to the DashboardScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HotelDashboard()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to create hotel profile: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Set Up Hotel Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Hotel Name",
                  hintText: "Enter your hotel name",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a hotel name";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: "Hotel Address",
                  hintText: "Enter your hotel address",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a hotel address";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Hotel Description",
                  hintText: "Enter a brief description of your hotel",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a hotel description";
                  }
                  return null;
                },
                maxLines: 3,
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: Text("Save Hotel Profile"),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}