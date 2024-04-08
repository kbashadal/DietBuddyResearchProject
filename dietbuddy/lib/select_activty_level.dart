import 'package:dietbuddy/set_goals.dart';
import 'package:flutter/material.dart';

class SelectActivityLevelPage extends StatefulWidget {
  final int age;
  final String gender;
  final double height;
  final double weight;
  final List<String> selectedActivities;
  final String fullName;
  final String email;
  final String password;

  const SelectActivityLevelPage(
      {super.key,
      required this.fullName,
      required this.email,
      required this.password,
      required this.age,
      required this.gender,
      required this.height,
      required this.weight,
      required this.selectedActivities});

  @override
  _SelectActivityLevelState createState() => _SelectActivityLevelState();
}

class _SelectActivityLevelState extends State<SelectActivityLevelPage> {
  String? _selectedActivityLevel;

  void _setSelectedActivityLevel(String value) {
    setState(() {
      _selectedActivityLevel = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: Image.asset(
          'assets/name.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please select your level of activity'),
            const SizedBox(height: 20),
            ListTile(
              leading: Radio<String>(
                value: 'Sedentary',
                groupValue: _selectedActivityLevel,
                onChanged: (value) => _setSelectedActivityLevel(value!),
              ),
              title: const Text('Sedentary'),
              trailing: const Icon(Icons.airline_seat_recline_extra),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'Lightly Active',
                groupValue: _selectedActivityLevel,
                onChanged: (value) => _setSelectedActivityLevel(value!),
              ),
              title: const Text('Lightly Active'),
              trailing: const Icon(Icons.directions_walk),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'Moderately Active',
                groupValue: _selectedActivityLevel,
                onChanged: (value) => _setSelectedActivityLevel(value!),
              ),
              title: const Text('Moderately Active'),
              trailing: const Icon(Icons.directions_run),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'Very Active',
                groupValue: _selectedActivityLevel,
                onChanged: (value) => _setSelectedActivityLevel(value!),
              ),
              title: const Text('Very Active'),
              trailing: const Icon(Icons.fitness_center),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetGoalsPage(
                      age: widget.age,
                      gender: widget.gender,
                      height: widget.height,
                      weight: widget.weight,
                      selectedActivities: widget.selectedActivities,
                      selectedActivityLevel: _selectedActivityLevel!,
                      fullName: widget.fullName,
                      email: widget.email,
                      password: widget.password,
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
