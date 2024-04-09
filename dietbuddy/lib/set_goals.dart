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
        backgroundColor: Colors.blue[50],
        title: Image.asset(
          'assets/name.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            const SizedBox(height: 20),

            // Your existing code here...

            // Add your provided snippet here
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _suggestedCaloriesController,
                      decoration: InputDecoration(
                        labelText: 'Suggested Calories',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isEditable ? null : const Icon(Icons.lock),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      readOnly: !_isEditable,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditable = true;
                      });
                    },
                    child: const Text('Edit'),
                  ),
                ],
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
                      'Set Goal (Optional)',
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
                    // SizedBox(
                    //   width: 160, // Adjusted width for side by side layout
                    //   child: TextFormField(
                    //     controller: _durationController,
                    //     decoration: const InputDecoration(
                    //       labelText: 'Duration (wks)',
                    //       border: OutlineInputBorder(),
                    //       suffixIcon: Icon(Icons.calendar_today),
                    //       fillColor: Colors.white,
                    //       filled: true,
                    //     ),
                    //     keyboardType: TextInputType.number,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text('Register'),
            ),
            ElevatedButton(
              onPressed: _onUpdateSuggestedCalories,
              child: const Text('Update Suggested Calories'),
            ),
            const SizedBox(height: 20),

            // Continue with any additional code...
          ],
        ),
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
