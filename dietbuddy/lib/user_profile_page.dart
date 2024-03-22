import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/view_history_page.dart';
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

  @override
  void initState() {
    super.initState();
    _profileData = _fetchUserProfile();
  }

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final response = await http.get(
      Uri.parse('http://localhost:5000/user_profile?email_id=$userEmail'),
    );

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
        title: const Text(
          'DietBuddy',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.green, // Adjust the color to match your branding
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Profile picture section removed
                      TextFormField(
                        initialValue: snapshot.data!['full_name'],
                        decoration:
                            const InputDecoration(labelText: 'Full Name'),
                      ),
                      TextFormField(
                        initialValue: snapshot.data!['email_id'],
                        decoration: const InputDecoration(labelText: 'Email'),
                        enabled: false, // Makes the field uneditable
                      ),
                      TextFormField(
                        initialValue: snapshot.data!['date_of_birth'],
                        decoration:
                            const InputDecoration(labelText: 'Date of Birth'),
                      ),
                      TextFormField(
                        initialValue: snapshot.data!['height'].toString(),
                        decoration:
                            const InputDecoration(labelText: 'Height (m)'),
                      ),
                      TextFormField(
                        initialValue: snapshot.data!['weight'].toString(),
                        decoration:
                            const InputDecoration(labelText: 'Weight (kg)'),
                      ),
                      TextFormField(
                        initialValue: snapshot.data!['bmi'].toStringAsFixed(2),
                        decoration: const InputDecoration(labelText: 'BMI'),
                      ),
                      TextFormField(
                        initialValue: snapshot.data!['bmi_category'],
                        decoration:
                            const InputDecoration(labelText: 'BMI Category'),
                        enabled: false, // Makes the field uneditable
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Set Calories Goal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Slider(
                        value: (snapshot.data!['calories_goal'] ?? 2000)
                            .toDouble(),
                        min: 1000,
                        max: 5000,
                        divisions: 80,
                        label: '${snapshot.data!['calories_goal']}',
                        onChanged: (double value) {
                          setState(() {
                            snapshot.data!['calories_goal'] = value.round();
                          });
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                          SystemNavigator.pop();

                          // Log off logic
                        },
                        child: const Text('Log-Off'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
          }
          // By default, show a loading spinner.
          return const Center(child: CircularProgressIndicator());
        },
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
}
