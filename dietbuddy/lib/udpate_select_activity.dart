import 'dart:convert';
import 'package:dietbuddy/home_page.dart';
import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_options_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/user_profile_page.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:dietbuddy/view_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class UpdateActivitySelectionPage extends StatefulWidget {
  const UpdateActivitySelectionPage({super.key});

  @override
  UpdateActivitySelectionPageState createState() =>
      UpdateActivitySelectionPageState();
}

class UpdateActivitySelectionPageState
    extends State<UpdateActivitySelectionPage> {
  List<String> activities = [];
  List<String> selectedActivities = [];
  List<String> finalSelectedActivities = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    // final response = await http.get(
    //   Uri.parse('http://127.0.0.1:5000/user_profile?email_id=$userEmail'),
    // );
    final response = await http.get(
      Uri.parse(
          'https://dietbuddyresearchproject.onrender.com/user_profile?email_id=$userEmail'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final activitiesList = data['selected_activities'] as List<dynamic>;
      setState(() {
        selectedActivities = List<String>.from(
            activitiesList.map((activity) => activity.toString()));
      });
    }
    try {
      // final response = await http.get(Uri.parse(
      //     'https://dietbuddyresearchproject.onrender.com/fetch_all_exercises'));
      final response = await http
          .get(Uri.parse('http://127.0.0.1:5000/fetch_all_exercises'));
      if (response.statusCode == 200) {
        final List<dynamic> decodedBody = json.decode(response.body);
        setState(() {
          activities = List<String>.from(
              decodedBody.map((data) => data['workout_type'] as String));
        });
      } else {
        throw Exception('Failed to load activities');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching activities: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade50,
        elevation: 0, // Added for a flatter appearance
        title: Image.asset(
          'assets/name.png',
          width: 120, // Adjusted size for better proportion
          height: 60, // Adjusted size for better proportion
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: activities.map((activity) {
                  return CheckboxListTile(
                    title: Text(activity),
                    value: selectedActivities.contains(activity),
                    onChanged: (bool? newValue) {
                      setState(() {
                        if (newValue == true) {
                          finalSelectedActivities.add(activity);
                          selectedActivities.add(activity);
                        } else {
                          finalSelectedActivities.remove(activity);
                          selectedActivities.remove(activity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _updateActivities(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurple, // Button color
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('Update'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: <Widget>[
                  ListTile(
                    leading:
                        Icon(Icons.add, color: Theme.of(context).primaryColor),
                    title: Text('Add Meal',
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color)),
                    onTap: () {
                      Navigator.pop(context); // Close the modal
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MealOptionsPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person,
                        color: Theme.of(context).primaryColor),
                    title: Text('View Profile',
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color)),
                    onTap: () {
                      Navigator.pop(context); // Close the modal
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserProfilePage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.fitness_center,
                        color: Theme.of(context).primaryColor),
                    title: Text('Update Activity',
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color)),
                    onTap: () {
                      Navigator.pop(context); // Close the modal
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const UpdateActivitySelectionPage()),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tips_and_updates),
            label: 'Interventions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MealSummaryPage(
                    email: Provider.of<UserProvider>(context, listen: false)
                            .email ??
                        '',
                  )),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const InterventionsSummaryPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ViewHistoryPage()),
        );
        // Already on the ViewHistoryPage, no need to navigate
        break;
    }
  }

  void _updateActivities() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final email = userProvider.email;
    // final response = await http.post(
    //   Uri.parse('http://127.0.0.1:5000/update_activities'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json
    //       .encode({'email_id': email, 'activities': finalSelectedActivities}),
    // );
    final response = await http.post(
      Uri.parse(
          'https://dietbuddyresearchproject.onrender.com/update_activities'),
      headers: {'Content-Type': 'application/json'},
      body: json
          .encode({'email_id': email, 'activities': finalSelectedActivities}),
    );
    print(response.body);
    if (response.statusCode == 200) {
      // ignore: use_build_context_synchronously
      if (email != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Activities updated successfully!'),
        ));
      } else {
        throw Exception('Email is null, cannot navigate to MealSummaryPage');
      }
    } else {
      throw Exception('Failed to update activities');
    }
  }
}
