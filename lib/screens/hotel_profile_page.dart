import 'package:flutter/material.dart';
//no more
class HotelProfilePage extends StatefulWidget {
  @override
  _HotelProfilePageState createState() => _HotelProfilePageState();
}

class _HotelProfilePageState extends State<HotelProfilePage> {
  bool _showHotelDetails = false;
  bool _isEditing = false;


  TextEditingController _hotelNameController =
  TextEditingController(text: 'MY HOTEL');
  TextEditingController _hotelAddressController =
  TextEditingController(text: '123 Hotel St, City, Country');
  TextEditingController _hotelDescriptionController = TextEditingController(
      text: 'A luxurious hotel offering the best amenities for your stay.');

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://www.pakistantravelguide.pk/wp-content/uploads/2020/02/Walnut-heights-Kalam-1024x682.jpeg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.start, // Aligns all to the left
            children: [
              Center(
                child: Text(
                  'Hotel Profile Management',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showHotelDetails = !_showHotelDetails;
                    });
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Container(
                      width: screenWidth * 0.6,
                      height: screenHeight * 0.2,
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel,
                              size: screenWidth * 0.1, color: Colors.green),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'MY HOTEL',
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_showHotelDetails)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditableField(
                          'Hotel Name:',
                          _hotelNameController,
                          screenWidth,
                          screenHeight,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildEditableField(
                          'Address:',
                          _hotelAddressController,
                          screenWidth,
                          screenHeight,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildEditableField(
                          'Description:',
                          _hotelDescriptionController,
                          screenWidth,
                          screenHeight,
                          maxLines: 4,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (_isEditing) {
                                    if (_formKey.currentState!.validate()) {
                                      // Save action
                                      setState(() {
                                        _isEditing = false;
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.02,
                                    horizontal: screenWidth * 0.08,
                                  ),
                                ),
                                child: Text(
                                  _isEditing ? 'Save' : 'Edit',
                                  style:
                                  TextStyle(fontSize: screenWidth * 0.045),
                                ),
                              ),
                              if (_isEditing)
                                SizedBox(width: screenWidth * 0.05),
                              if (_isEditing)
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.02,
                                      horizontal: screenWidth * 0.08,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.045),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
      String label,
      TextEditingController controller,
      double screenWidth,
      double screenHeight, {
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        _isEditing
            ? TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: label,
            labelStyle: TextStyle(color: Colors.green),
          ),
          style: TextStyle(color: Colors.black),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field cannot be empty';
            }
            return null;
          },
        )
            : Container(
          width: double.infinity,
          child: Text(
            controller.text,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
