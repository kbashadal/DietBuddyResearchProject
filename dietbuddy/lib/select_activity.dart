import 'dart:convert';
import 'package:dietbuddy/select_activty_level.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// SelectActivityPage allows users to select their preferred activities.
class SelectActivityPage extends StatefulWidget {
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String fullName;
  final String email;
  final String password;

  const SelectActivityPage({
    super.key,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  SelectActivityPageState createState() => SelectActivityPageState();
}

class SelectActivityPageState extends State<SelectActivityPage> {
  List<String> activities = [];
  final List<String> _selectedActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  /// Fetches activities from the server.
  Future<void> _fetchActivities() async {
    try {
      // final response = await http
      //     .get(Uri.parse('http://127.0.0.1:5000/fetch_all_exercises'));
      final response = await http.get(Uri.parse(
          'https://dietbuddyresearchproject.onrender.com/fetch_all_exercises'));
      if (response.statusCode == 200) {
        setState(() {
          activities = List<String>.from(
              json.decode(response.body).map((data) => data['workout_type']));
        });
      } else {
        throw Exception('Failed to load activities');
      }
    } catch (e) {
      // Handle exceptions by showing a dialog or a snackbar
      if (kDebugMode) {
        print('Error fetching activities: $e');
      } // Consider replacing with a user-friendly error handling
    }
  }

  /// Toggles the selection state of an activity.
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
        backgroundColor: Colors.indigo, // Updated color for a professional look
        elevation: 0, // Added for a flatter appearance
        title: Image.asset(
          'assets/name.png',
          width: 120, // Adjusted size for better proportion
          height: 60, // Adjusted size for better proportion
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Select Activities',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          Colors.deepPurple, // Added color for a vibrant look
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Divider(
                  thickness: 2,
                  indent: 20,
                  endIndent: 20,
                  color: Colors
                      .deepPurple.shade200, // Added color to match the theme
                ),
                ...activities
                    .map((activity) => CheckboxListTile(
                          title: Text(activity),
                          value: _selectedActivities.contains(activity),
                          onChanged: (bool? selected) {
                            _toggleActivity(activity);
                          },
                          checkColor:
                              Colors.white, // Added for better visibility
                          activeColor:
                              Colors.deepPurple, // Added to match the theme
                        ))
                    .toList(),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selectedActivities.length >= 3
                      ? () => _navigateToNextPage(context)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select atleast 3 activities to proceed.',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }, // Condition and message added here
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _selectedActivities.length >= 3
                        ? Colors
                            .deepPurple // Button color when condition is met
                        : Colors.grey, // Button color when condition is not met
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navigates to the SelectActivityLevelPage, passing the necessary parameters.
  void _navigateToNextPage(BuildContext context) {
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
          selectedActivities: _selectedActivities,
        ),
      ),
    );
  }
}
