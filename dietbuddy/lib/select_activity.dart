import 'dart:convert';

import 'package:dietbuddy/select_activty_level.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SelectActivityPage extends StatefulWidget {
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String fullName;
  final String email;
  final String password;

  const SelectActivityPage(
      {super.key,
      required this.age,
      required this.gender,
      required this.height,
      required this.weight,
      required this.fullName,
      required this.email,
      required this.password});

  @override
  _SelectActivityPageState createState() => _SelectActivityPageState();
}

class _SelectActivityPageState extends State<SelectActivityPage> {
  List<String> activities = [];

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  void fetchActivities() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:5000/fetch_all_exercises'));
    if (response.statusCode == 200) {
      setState(() {
        activities = List<String>.from(
            json.decode(response.body).map((data) => data['workout_type']));
      });
    } else {
      throw Exception('Failed to load activities');
    }
  }

  // Track selected activities
  final List<String> _selectedActivities = [];

  void _toggleActivity(String value) {
    setState(() {
      if (_selectedActivities.contains(value)) {
        _selectedActivities.remove(value);
      } else {
        _selectedActivities.add(value);
      }
    });
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Select Activities',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(
              thickness: 2,
              indent: 20,
              endIndent: 20,
              color: Colors.grey,
            ),
            ...activities.map((activity) {
              return CheckboxListTile(
                title: Text(activity),
                value: _selectedActivities.contains(activity),
                onChanged: (bool? selected) {
                  _toggleActivity(activity);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectActivityLevelPage(
                      fullName: widget.fullName,
                      email: widget.email,
                      password: widget.password,
                      age: widget.age,
                      gender: widget.gender,
                      height: widget.height,
                      weight: widget.weight,
                      selectedActivities:
                          _selectedActivities, // Pass the selected activities
                    ),
                  ),
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
