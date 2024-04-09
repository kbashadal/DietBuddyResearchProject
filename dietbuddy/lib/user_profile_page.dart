import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/view_history_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  UserProfilePageState createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>> _profileData;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetCaloriesController;
  late TextEditingController _activityLevelController;
  late TextEditingController _targetWeightController;
  late TextEditingController _durationController;
  late TextEditingController _bmiController;
  late TextEditingController _bmiCategoryController;
  DateTime _selectedDate = DateTime.now();
  String userDateOfBirth = '';
  @override
  void dispose() {
    _dateOfBirthController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetCaloriesController.dispose();
    _activityLevelController.dispose();
    _targetWeightController.dispose();
    _durationController.dispose();
    _bmiController.dispose();
    _bmiCategoryController.dispose();
    // Dispose other controllers and resources
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _profileData = _fetchUserProfile();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetCaloriesController = TextEditingController();
    _activityLevelController = TextEditingController();
    _targetWeightController = TextEditingController();
    _durationController = TextEditingController();
    _bmiController = TextEditingController();
    _bmiCategoryController = TextEditingController();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // from your existing code
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text =
            _selectedDate.toLocal().toString().split(' ')[0];
        userDateOfBirth = _selectedDate.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final response = await http.get(
      Uri.parse(
          'https://dietbuddyresearchproject.onrender.com/user_profile?email_id=$userEmail'),
    );
    // final response = await http.get(
    //   Uri.parse('http://127.0.0.1:5000/user_profile?email_id=$userEmail'),
    // );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo, // Updated color for a professional look
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                _fullNameController.text = snapshot.data!['full_name'];
                _emailController.text = snapshot.data!['email_id'];
                _dateOfBirthController.text = snapshot.data!['age'].toString();
                _heightController.text = snapshot.data!['height'].toString();
                _weightController.text = snapshot.data!['weight'].toString();
                _targetCaloriesController.text =
                    snapshot.data!['suggested_calories'].toString();
                _activityLevelController.text =
                    snapshot.data!['activity_level'].toString();
                _targetWeightController.text =
                    snapshot.data!['target_weight'].toString();
                // _durationController.text =
                //     snapshot.data!['duration'].toString();
                _bmiController.text = snapshot.data!['bmi'].toString();
                _bmiCategoryController.text = snapshot.data!['bmi_category'];
                // _selectedDate = DateTime.parse(snapshot.data!['date_of_birth']);
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Card(
                        color: Colors.transparent,
                        elevation: 0,
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
                                        labelText: 'Email',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.email_outlined),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      enabled: false,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _dateOfBirthController,
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.cake),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _heightController,
                                      decoration: const InputDecoration(
                                        labelText: 'Height (cm)',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.straighten),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _weightController,
                                      decoration: const InputDecoration(
                                        labelText: 'Weight (kg)',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.monitor_weight),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _bmiController,
                                      decoration: const InputDecoration(
                                        labelText: 'BMI',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.fitness_center),
                                        fillColor: Colors.white,
                                        filled: true,
                                        enabled: false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _bmiCategoryController,
                                      decoration: const InputDecoration(
                                        labelText: 'BMI Category',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.category),
                                        fillColor: Colors.white,
                                        filled: true,
                                        enabled: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _activityLevelController.text,
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
                                    _activityLevelController.text = newValue!;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Activity Level',
                                  border: OutlineInputBorder(),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const SizedBox(height: 20),
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
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'Goals',
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
                              TextFormField(
                                controller: _targetCaloriesController,
                                decoration: const InputDecoration(
                                  labelText: 'Recommended Daily Calories',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.local_fire_department),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  // Expanded(
                                  //   child: TextFormField(
                                  //     controller: _durationController,
                                  //     decoration: const InputDecoration(
                                  //       labelText: 'Duration (Weeks)',
                                  //       border: OutlineInputBorder(),
                                  //       suffixIcon: Icon(Icons.calendar_today),
                                  //       fillColor: Colors.white,
                                  //       filled: true,
                                  //     ),
                                  //   ),
                                  // ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _targetWeightController,
                                      decoration: const InputDecoration(
                                        labelText: 'Target Weight',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.fitness_center),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                      SystemNavigator.pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.deepPurple,
                                      elevation: 5, // Shadow depth
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12.0), // Softer roundness
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal:
                                              40.0), // Adjusted padding for better fit
                                      textStyle: const TextStyle(
                                        fontSize: 16, // Slightly smaller text
                                        fontWeight: FontWeight
                                            .bold, // Bold text for emphasis
                                      ),
                                    ),
                                    child: const Text('Log Off'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return const Dialog(
                                            child: Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(width: 15),
                                                  Text("Updating..."),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                      _updateUserProfile();
                                      Navigator.pop(
                                          context); // Close the dialog
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Profile updated successfully'),
                                          backgroundColor: Colors
                                              .green, // Added background color for SnackBar
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.deepPurple,
                                      elevation:
                                          4, // Adjusted elevation for a subtle shadow
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12.0), // Adjusted border radius for consistency
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal:
                                              36.0), // Adjusted padding for aesthetics
                                      textStyle: const TextStyle(
                                        fontSize:
                                            16, // Adjusted font size for readability
                                        fontWeight: FontWeight
                                            .bold, // Maintained bold font weight for emphasis
                                      ),
                                    ),
                                    child: const Text('Update Profile'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tips_and_updates),
            label: 'Interventions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
            tooltip: 'History',
          ),
        ],
        selectedItemColor: Colors.green,
        onTap: (index) {
          // Check the index and navigate accordingly
          if (index == 2) {
            // Assuming the User Profile is the third item
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewHistoryPage()),
            );
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const InterventionsSummaryPage()),
            );
          }
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MealSummaryPage(
                        email: Provider.of<UserProvider>(context, listen: false)
                                .email ??
                            '',
                      )),
            );
          }
          // Handle other indices if needed
        },
      ),
    );
  }

  void _updateUserProfile() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final userFullName = _fullNameController.text;
    userDateOfBirth = _dateOfBirthController.text;
    final userHeight =
        (_heightController.text); // Corrected from String.parse to double.parse
    final userWeight = (_weightController.text);
    final userTargetCalories = (_targetCaloriesController.text);
    final userActivityLevel = (_activityLevelController.text);
    final userDuration = (_durationController.text);
    final userTargetWeight = (_targetWeightController.text);
    final userBMI = (_bmiController.text);
    final userBMIcategory = (_bmiCategoryController.text);
    // const api =
    //     'http://127.0.0.1:5000/update_user_profile'; // Replace with your actual API URL
    const api =
        'https://dietbuddyresearchproject.onrender.com/update_user_profile';
    final body = jsonEncode({
      'emailId': userEmail,
      'fullName': userFullName,
      'dateOfBirth': userDateOfBirth,
      'height': userHeight,
      'weight': userWeight,
      'suggestedCalories': userTargetCalories,
      'activityLevel': userActivityLevel,
      'duration': userDuration,
      'targetWeight': userTargetWeight,
      'bmi': userBMI,
      'bmiCategory': userBMIcategory,
    });

    http
        .post(
      Uri.parse(api),
      headers: {"Content-Type": "application/json"},
      body: body,
    )
        .then((response) {
      if (response.statusCode == 200) {
        setState(() {
          _profileData = _fetchUserProfile();
        });
        if (kDebugMode) {
          print('User profile updated successfully');
        }
      } else {
        if (kDebugMode) {
          print('Failed to update user profile');
        }
      }
    }).catchError((error) {
      if (kDebugMode) {
        print('Error updating user profile: $error');
      }
    });
  }
}
