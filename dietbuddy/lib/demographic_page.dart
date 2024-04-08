import 'package:dietbuddy/select_activity.dart';
import 'package:flutter/material.dart';

class DemographicPage extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;
  const DemographicPage({
    Key? key,
    required this.fullName,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  _DemographicPageState createState() => _DemographicPageState();
}

class _DemographicPageState extends State<DemographicPage> {
  final TextEditingController _ageController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedGender = 'Male';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Demographic Information',
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
            const SizedBox(height: 10),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.cake),
                fillColor: Colors.white,
                filled: true,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 10),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                suffixIcon: Icon(Icons.straighten),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                suffixIcon: Icon(Icons.monitor_weight),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Convert age, height, and weight to their respective types if needed
                final int age = int.tryParse(_ageController.text) ??
                    0; // Default to 0 if parsing fails
                final double height = double.tryParse(_heightController.text) ??
                    0.0; // Default to 0.0 if parsing fails
                final double weight = double.tryParse(_weightController.text) ??
                    0.0; // Default to 0.0 if parsing fails

                // Navigate to SelectActivityPage with the values
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectActivityPage(
                      fullName: widget.fullName,
                      email: widget.email,
                      password: widget.password,
                      age: age,
                      gender: _selectedGender,
                      height: height,
                      weight: weight,
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
