import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:roomfind/screens/customer/customer_home_page.dart';
import 'package:roomfind/register_screen/Customer_register.dart';
import 'package:roomfind/widgets/text_field.dart';
import 'package:roomfind/widgets/button.dart';
import 'package:roomfind/screens/CheckHotelProfileScreen.dart';
import 'package:roomfind/providers/customer_hotel_provider.dart';
class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = "Customer";



  // Default selected role is Customer

  void loginUser() async {
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your phone number and password.")),
      );
      return;
    }

    try {
      // Quering Firestore for a user document matching the phone number
      QuerySnapshot snapshot = await _firestore
          .collection("users")
          .where("phoneNumber", isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found. Please register first.")),
        );
        return;
      }

      // retrieve user data
      Map<String, dynamic> userData = snapshot.docs[0].data() as Map<String, dynamic>;

      debugPrint('userData: ${userData["role"]}');

      // Check  password
      if (userData["password"] != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect password. Please try again.")),
        );
        return;
      }

      // Check  selected role match
      if (userData["role"] != selectedRole) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You are not registered as a $selectedRole. Please select the correct role."),
          ),
        );
        return;
      }

      // go to the respective home screen
      if (selectedRole == "Customer") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerHomePage(phoneNumber: phone),
          ),
        );
      } else if (selectedRole == "Hotel Owner") {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CheckHotelProfileScreen(phoneNumber: phone),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                TextFieldinputc(
                  textEditingController: phoneController,
                  hintText: "Enter Phone Number",
                  icon: Icons.phone,
                ),
                TextFieldinputc(
                  textEditingController: passwordController,
                  hintText: "Enter Password",
                  icon: Icons.lock,
                  isPass: true,
                ),
                const SizedBox(height: 16),
                // Role selection dropdown
                DropdownButton<String>(
                  value: selectedRole,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                  },
                  items: <String>["Customer", "Hotel Owner"]
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                MyButton(
                  onTab: loginUser,
                  text: "Login",
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerSignup(),
                          ),
                        );
                      },
                      child: const Text(
                        " Signup",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Forgot Password functionality coming soon!")),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}