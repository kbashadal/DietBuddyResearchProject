// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:dietbuddy/demographic_page.dart';
import 'package:dietbuddy/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BasicInfoPage extends StatefulWidget {
  const BasicInfoPage({super.key});

  @override
  BasicInfoPageState createState() => BasicInfoPageState();
}

class BasicInfoPageState extends State<BasicInfoPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[50], // Changed to a more academic color
        title: Image.asset(
          'assets/name.png', // Changed asset name for a more academic look
          width: 150, // Adjusted size for a more refined look
          height: 150,
          fit: BoxFit.contain,
        ),
        centerTitle: true, // Centered the title for a more balanced look
      ),
      body: Container(
        color: Colors.blue[50], // Matching the appBar color for consistency
        padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 12.0), // Adjusted padding for better spacing
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Basic Info',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Divider(
                    thickness: 2,
                    indent: 20,
                    endIndent: 20,
                    color: Colors.grey,
                  ),
                ],
              ),
              Card(
                color: Colors.transparent,
                elevation: 0,
                // First frame for personal details
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.person_outline),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email ID',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.email_outlined),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.lock_outline),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              obscureText: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.lock_reset),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Gather data from the controllers
                  final String fullName = _fullNameController.text;
                  final String email = _emailController.text;
                  final String password = _passwordController.text;

                  // Assuming DemographicPage accepts data through its constructor
                  // You might need to adjust this part based on how DemographicPage is set up
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DemographicPage(
                        fullName: _fullNameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
