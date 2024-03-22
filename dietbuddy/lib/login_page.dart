import 'dart:convert';

import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/registration_page.dart';
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
    const url = 'http://127.0.0.1:5000/login';
    final Map<String, dynamic> loginData = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );

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
        title: const Text(
          'DietBuddy',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.green, // Adjust the color to match your branding
          ),
        ),
      ),
      // Remove the AppBar or make it transparent
      backgroundColor: Colors.white, // Set the background color to white
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 60), // Add space before the form fields
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email ID',
                  hintText: 'Enter Email Id',
                  // Add the border style as per the image
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  // Add the prefix icon if needed
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  // Add the border style as per the image
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  // Add the prefix icon if needed
                ),
                obscureText: true,
              ),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton(
              //     onPressed: () {
              //       // Forgot password button pressed
              //     },
              //     child: const Text('Forgot Password?'),
              //   ),
              // ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loginUser,
                style: ElevatedButton.styleFrom(
                  primary: Colors.green, // Set the button color to green
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30.0), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 80.0), // Padding inside the button
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegistrationPage()));
                  // Sign up button pressed
                },
                child: const Text(
                  'Don\'t have an account? Sign Up',
                  style: TextStyle(
                      color: Colors.green), // Set the text color to green
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
