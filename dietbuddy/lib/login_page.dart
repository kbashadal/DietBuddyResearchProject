import 'dart:convert';

import 'package:dietbuddy/basic_info_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    const url = 'https://dietbuddyresearchproject.onrender.com/login';
    // const url = 'http://127.0.0.1:5000/login';

    final Map<String, dynamic> loginData = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                Text("Loading"),
              ],
            ),
          );
        },
      );
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Close the loading dialog
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return; // Check if the widget is still in the widget tree
        // Navigate to MealSummaryPage upon successful login
        Provider.of<UserProvider>(context, listen: false)
            .setEmail(_emailController.text);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MealSummaryPage(email: _emailController.text)),
        );
      } else {
        // Handle login error
        if (kDebugMode) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${responseBody['message']}'),
              backgroundColor: Colors.red,
            ),
          );
          print('Login failed: ${responseBody['message']}');
        }
        // Show error message
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred while sending login data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // Remove shadow for a cleaner look
        backgroundColor: Colors.transparent, // Make AppBar transparent
        title: Image.asset(
          'assets/name.png', // Assuming 'logo.png' is a more professional asset name
          width: 120, // Slightly reduced for elegance
          height: 120,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.blue[50], // Use a clean white background
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0), // Uniform padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                  height: 80), // Increased space for a more airy layout
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(8.0), // Softened border radius
                  ),
                  prefixIcon: const Icon(Icons.email), // Email icon for clarity
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon:
                      const Icon(Icons.lock), // Password icon for clarity
                ),
                obscureText: true,
              ),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton(
              //     onPressed: () {
              //       // Forgot password button pressed
              //     },
              //     child: const Text(
              //       'Forgot Password?',
              //       style: TextStyle(
              //           color: Colors
              //               .deepPurple), // Use theme color for consistency
              //     ),
              //   ),
              // ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Theme color for consistency
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 36.0),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                      fontSize: 18), // Slightly larger text for readability
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BasicInfoPage()));
                },
                child: const Text(
                  'Don\'t have an account? Sign Up',
                  style: TextStyle(
                    color: Colors.deepPurple, // Use theme color for consistency
                    decoration:
                        TextDecoration.underline, // Underline for emphasis
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
