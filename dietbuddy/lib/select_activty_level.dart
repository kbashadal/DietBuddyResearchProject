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
  SelectActivityLevelState createState() => SelectActivityLevelState();
}

class SelectActivityLevelState extends State<SelectActivityLevelPage> {
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
        backgroundColor: Colors.lightBlue.shade50,
        title: Image.asset(
          'assets/name.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.lightBlue.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Please select your level of activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(
                  thickness: 2,
                  indent: 20,
                  endIndent: 20,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 30),
                _activityLevelOption(
                  title: 'Sedentary',
                  icon: Icons.airline_seat_recline_extra,
                  value: 'Sedentary',
                ),
                _activityLevelOption(
                  title: 'Lightly Active',
                  icon: Icons.directions_walk,
                  value: 'Lightly Active',
                ),
                _activityLevelOption(
                  title: 'Moderately Active',
                  icon: Icons.directions_run,
                  value: 'Moderately Active',
                ),
                _activityLevelOption(
                  title: 'Very Active',
                  icon: Icons.fitness_center,
                  value: 'Very Active',
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple, // Button color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    textStyle: const TextStyle(fontSize: 18),
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

  Widget _activityLevelOption(
      {required String title, required IconData icon, required String value}) {
    return ListTile(
      leading: Radio<String>(
        value: value,
        groupValue: _selectedActivityLevel,
        onChanged: (value) => _setSelectedActivityLevel(value!),
        activeColor: Colors.blue[800],
      ),
      title: Text(title),
      trailing: Icon(icon, color: Colors.blue[800]),
    );
  }

  void _onNextPressed() {
    if (_selectedActivityLevel != null) {
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
    } else {
      // Handle the case where no activity level is selected
      // For example, show a dialog or a snackbar
    }
  }
}
