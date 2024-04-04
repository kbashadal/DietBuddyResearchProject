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
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String _selectedActivityLevel = 'Sedentary'; // Default to Sedentary

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> registerUser(BuildContext context) async {
    const url = 'http://127.0.0.1:5000/register';
    // const url = 'https://dietbuddyresearchproject.onrender.com/register';

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
      ..fields['targetWeight'] = _targetWeightController.text
      ..fields['duration'] = _durationController.text
      ..fields['dateOfBirth'] = "${_selectedDate.toLocal()}".split(' ')[0]
      ..fields['activityLevel'] = _selectedActivityLevel;

    // Image upload logic removed

    try {
      // Send the request
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
      var response = await request.send();
      Navigator.pop(context); // Close the loading dialog

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
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Data to calculate Calories',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Card(
                // Second frame for additional details
                color: Colors.transparent,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .start, // Align to the start of the row
                        children: [
                          SizedBox(
                            width:
                                140, // Set the width to a smaller value as needed
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Row(
                                    children: [
                                      Icon(Icons.male),
                                      SizedBox(width: 8),
                                      Text('Male'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Row(
                                    children: [
                                      Icon(Icons.female),
                                      SizedBox(width: 8),
                                      Text('Female'),
                                    ],
                                  ),
                                ),
                              ],
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
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90, // Adjust the width as needed
                            child: TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                labelText: 'Ht (cm)',
                                border: OutlineInputBorder(),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90, // Adjust the width as needed
                            child: TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Wt (kg)',
                                border: OutlineInputBorder(),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        child: DropdownButtonFormField<String>(
                          value: _selectedActivityLevel,
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                              value: 'Sedentary',
                              child: Row(
                                children: [
                                  Icon(Icons.airline_seat_recline_extra),
                                  SizedBox(width: 8),
                                  Text('Sedentary'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Lightly Active',
                              child: Row(
                                children: [
                                  Icon(Icons.directions_walk),
                                  SizedBox(width: 8),
                                  Text('Lightly Active'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Moderately Active',
                              child: Row(
                                children: [
                                  Icon(Icons.directions_run),
                                  SizedBox(width: 8),
                                  Text('Moderately Active'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Very Active',
                              child: Row(
                                children: [
                                  Icon(Icons.fitness_center),
                                  SizedBox(width: 8),
                                  Text('Very Active'),
                                ],
                              ),
                            ),
                          ],
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
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Set Goal',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.transparent,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160, // Adjusted width for side by side layout
                        child: TextFormField(
                          controller: _targetWeightController,
                          decoration: const InputDecoration(
                            labelText: 'Target Wt (kg)',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.fitness_center),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 160, // Adjusted width for side by side layout
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duration (wks)',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Handle registration logic
                  registerUser(context);
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
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
