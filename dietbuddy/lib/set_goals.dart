import 'dart:convert';

import 'package:dietbuddy/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SetGoalsPage extends StatefulWidget {
  final int age;
  final String gender;
  final double height;
  final double weight;
  final List<String> selectedActivities;
  final String selectedActivityLevel;
  final String fullName;
  final String email;
  final String password;

  const SetGoalsPage(
      {super.key,
      required this.age,
      required this.gender,
      required this.height,
      required this.weight,
      required this.selectedActivities,
      required this.selectedActivityLevel,
      required this.fullName,
      required this.email,
      required this.password});

  @override
  SetGoalsPageState createState() => SetGoalsPageState();
}

class SetGoalsPageState extends State<SetGoalsPage> {
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _suggestedCaloriesController =
      TextEditingController();
  bool _isEditable = false;

  @override
  void initState() {
    super.initState();
    _fetchSuggestedCalories();
  }

  void _fetchSuggestedCalories() async {
    // final response = await http.get(Uri.parse(
    //     'https://dietbuddyresearchproject.onrender.com/fetch_suggested_calories?age=${widget.age}&gender=${widget.gender}&weight_kg=${widget.weight}&height_cm=${widget.height}&activity_level=${widget.selectedActivityLevel}&target_weight=${_targetWeightController.text}'));
    final response = await http.get(Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/fetch_suggested_calories?age=${widget.age}&gender=${widget.gender}&weight_kg=${widget.weight}&height_cm=${widget.height}&activity_level=${widget.selectedActivityLevel}&target_weight=${_targetWeightController.text}'));

    final jsonData = json.decode(response.body);
    setState(() {
      _suggestedCaloriesController.text = jsonData['suggested_calories']
          .toString(); // Assuming 'suggested_calories' is the key in your JSON data
    });
  }

  void _onUpdateSuggestedCalories() async {
    // final response = await http.get(Uri.parse(
    //     'http://127.0.0.1:5000/fetch_suggested_calories?age=${widget.age}&gender=${widget.gender}&weight_kg=${_targetWeightController.text}&height_cm=${widget.height}&activity_level=${widget.selectedActivityLevel}&target_weight=${_targetWeightController.text}'));
    final response = await http.get(Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/fetch_suggested_calories?age=${widget.age}&gender=${widget.gender}&weight_kg=${_targetWeightController.text}&height_cm=${widget.height}&activity_level=${widget.selectedActivityLevel}&target_weight=${_targetWeightController.text}'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        _suggestedCaloriesController.text =
            jsonData['suggested_calories'].toString();
      });
    } else {
      if (kDebugMode) {
        print('Failed to fetch suggested calories');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo, // Updated color for a professional look
        title: Image.asset(
          'assets/name.png', // Assuming a more professional logo asset
          width: 120, // Adjusted size
          height: 120, // Adjusted size
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        elevation: 0, // Remove shadow for a flat design
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white, // Using a clean white background
          padding:
              const EdgeInsets.all(20.0), // Adjusted padding for more space
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              _buildSuggestedCaloriesField(),
              const SizedBox(height: 20),
              _buildDividerWithText('Set Your Goal'),
              const SizedBox(height: 20),
              _buildTargetWeightField(),
              const SizedBox(height: 40),
              _buildRegisterButton(),
              const SizedBox(height: 20),
              _buildUpdateSuggestedCaloriesButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedCaloriesField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextFormField(
            controller: _suggestedCaloriesController,
            decoration: InputDecoration(
              labelText: 'Suggested Calories',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: _isEditable
                  ? const Icon(Icons.edit)
                  : const Icon(Icons.lock_outline),
              fillColor: Colors.grey[200], // Light grey fill for subtle look
              filled: true,
            ),
            readOnly: !_isEditable,
            keyboardType: TextInputType.number,
          ),
        ),
        IconButton(
          icon: Icon(_isEditable ? Icons.lock : Icons.edit,
              color: Colors.indigo), // Matching icon color with app theme
          onPressed: () {
            setState(() {
              _isEditable = !_isEditable;
            });
          },
          tooltip: _isEditable ? 'Lock' : 'Edit',
        ),
      ],
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.indigo, // Using theme color for text
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Expanded(
          child: Divider(),
        ),
      ],
    );
  }

  Widget _buildTargetWeightField() {
    return TextFormField(
      controller: _targetWeightController,
      decoration: InputDecoration(
        labelText: 'Target Weight (kg)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: const Icon(Icons.fitness_center,
            color: Colors.indigo), // Icon color
        fillColor: Colors.grey[200], // Consistent with other fields
        filled: true,
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _registerUser,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigo, // Updated button color to match theme
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      child: const Text(
        'Register',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUpdateSuggestedCaloriesButton() {
    return ElevatedButton(
      onPressed: _onUpdateSuggestedCalories,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigo.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      child: const Text(
        'Update Calories',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Future<void> _registerUser() async {
    // const url = 'http://127.0.0.1:5000/register_new_user';
    const url =
        'https://dietbuddyresearchproject.onrender.com/register_new_user';
    final Uri uri = Uri.parse(url);
    var request = http.MultipartRequest('POST', uri)
      ..fields['fullName'] = widget.fullName
      ..fields['email'] = widget.email
      ..fields['password'] = widget.password
      ..fields['gender'] = widget.gender
      ..fields['height'] = widget.height.toString()
      ..fields['weight'] = widget.weight.toString()
      ..fields['targetWeight'] = _targetWeightController.text
      ..fields['selectedActivities'] = widget.selectedActivities.toString()
      ..fields['selectedActivityLevel'] = widget.selectedActivityLevel
      ..fields['age'] = widget.age.toString();

    try {
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
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Close the loading dialog
      response.stream.transform(utf8.decoder).listen((value) {
        final responseBody = json.decode(value);
        if (response.statusCode == 201) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'])),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'])),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
