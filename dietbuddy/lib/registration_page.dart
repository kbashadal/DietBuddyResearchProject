// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:dietbuddy/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _selectedGender = 'Male'; // Defa
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedActivityLevel = 'Sedentary'; // Default to Sedentary

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> registerUser(BuildContext context) async {
    // const url = 'http://127.0.0.1:5000/register';
    const url = 'https://dietbuddyresearchproject.onrender.com/register';

    final Uri uri = Uri.parse(url);

    // Create a multipart request
    var request = http.MultipartRequest('POST', uri)
      ..fields['fullName'] = _fullNameController.text
      ..fields['email'] = _emailController.text
      ..fields['password'] = _passwordController.text
      ..fields['confirmPassword'] = _confirmPasswordController.text
      ..fields['gender'] = _selectedGender
      ..fields['height'] = _heightController.text
      ..fields['weight'] = _weightController.text
      ..fields['dateOfBirth'] = "${_selectedDate.toLocal()}".split(' ')[0]
      ..fields['activityLevel'] = _selectedActivityLevel;

    // Image upload logic removed

    try {
      // Send the request
      var response = await request.send();

      // Listen for response
      response.stream.transform(utf8.decoder).listen((value) {
        final responseBody = json.decode(value);

        if (response.statusCode == 201) {
          if (!mounted) {
            return; // Check if the widget is still in the widget tree
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'])),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          if (!mounted) {
            return; // Check if the widget is still in the widget tree
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'])),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred while sending registration data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // from your existing code
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
                SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.05), // Reduced space for a tighter layout

                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.person_outline),
                    fillColor:
                        Colors.white, // Added fill color for a cleaner look
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
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
                const SizedBox(height: 20),
                TextFormField(
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
                const SizedBox(height: 20),
                TextFormField(
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
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: <String>['Male', 'Female', 'Other']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedActivityLevel,
                  items: <String>[
                    'Sedentary',
                    'Lightly Active',
                    'Moderately Active',
                    'Very Active'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedActivityLevel = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Date of Birth'),
                  subtitle: Text(
                    "${_selectedDate.toLocal()}".split(' ')[0],
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Handle registration logic
                    registerUser(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Changed button color for a
                    // Changed button color for a more academic look
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    textStyle: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ));
  }
}
