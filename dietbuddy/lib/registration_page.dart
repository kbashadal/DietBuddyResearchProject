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
    const url = 'http://127.0.0.1:5000/register';
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
      ..fields['dateOfBirth'] = "${_selectedDate.toLocal()}".split(' ')[0];

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
        title: const Text(
          'DietBuddy',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.green, // Adjust the color to match your branding
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.1), // Adjust the space as needed

            const SizedBox(height: 20),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email ID',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.check_circle_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Re-enter Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
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
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Date of Birth'),
              subtitle: Text(
                "${_selectedDate.toLocal()}".split(' ')[0],
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle registration logic
                registerUser(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
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
    );
  }
}
