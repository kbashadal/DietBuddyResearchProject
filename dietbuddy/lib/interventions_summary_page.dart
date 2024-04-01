import 'package:dietbuddy/diet_chat_bot_page.dart';
import 'package:dietbuddy/meal_options_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/user_profile_page.dart';
import 'package:dietbuddy/view_history_page.dart';
import 'package:flutter/material.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InterventionsSummaryPage extends StatefulWidget {
  const InterventionsSummaryPage({Key? key}) : super(key: key);

  @override
  InterventionsSummaryPageState createState() =>
      InterventionsSummaryPageState();
}

class InterventionsSummaryPageState extends State<InterventionsSummaryPage> {
  late Future<List<dynamic>> _exerciseSuggestions;
  late Future<List<dynamic>> _alternateFoodSuggestions;
  late Future<Map<String, dynamic>> _userChatHistory;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _exerciseSuggestions = fetchExerciseSuggestions(context);
    _alternateFoodSuggestions = fetchAlternateFoodSuggestions(context);
    _userChatHistory = Future.value({});

    _userChatHistory = fetchUserChatHistory(context);
  }

  Future<List<dynamic>> fetchAlternateFoodSuggestions(
      BuildContext context) async {
    // Obtain the user's email from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;

    // Ensure userEmail is not null or handle it appropriately
    if (userEmail == null) {
      throw Exception('User email is not available');
    }

    final response = await http.get(
      Uri.parse(
          'http://localhost:5000/get_user_alternate_food?emailId=$userEmail'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load exercise suggestions');
    }
  }

  Future<List<dynamic>> fetchExerciseSuggestions(BuildContext context) async {
    // Obtain the user's email from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;

    // Ensure userEmail is not null or handle it appropriately
    if (userEmail == null) {
      throw Exception('User email is not available');
    }

    final response = await http.get(
      Uri.parse(
          'http://localhost:5000/get_user_exercise_suggestions?emailId=$userEmail'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load exercise suggestions');
    }
  }

  Future<Map<String, dynamic>> fetchUserChatHistory(
      BuildContext context) async {
    // Obtain the user's email from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;

    // Ensure userEmail is not null or handle it appropriately
    if (userEmail == null) {
      throw Exception('User email is not available');
    }

    final response = await http.get(
      Uri.parse(
          'http://localhost:5000/get_user_chat_history?emailId=$userEmail'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user chat history');
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
      body: ListView(
        children: <Widget>[
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              title: Text('Exercise Recommendations',
                  style: Theme.of(context).textTheme.titleLarge),
              leading: Icon(Icons.fitness_center,
                  color: Theme.of(context).primaryColor),
              children: <Widget>[
                FutureBuilder<List<dynamic>>(
                  future: _exerciseSuggestions,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return ListView.separated(
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey[300]),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var suggestion = snapshot.data![index];
                            return ListTile(
                              title: Text(
                                  suggestion['exercise']['workout_type'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Suggested on: ${suggestion['suggested_on']}'),
                              trailing: suggestion['suggested_time'] != null
                                  ? Chip(
                                      label: Text(
                                          '${suggestion['suggested_time']} min',
                                          style: const TextStyle(
                                              color: Colors.white)),
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                    )
                                  : null,
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red)),
                        );
                      }
                    }
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ],
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              title: Text('Food Alternatives',
                  style: Theme.of(context).textTheme.titleLarge),
              leading:
                  Icon(Icons.fastfood, color: Theme.of(context).primaryColor),
              children: <Widget>[
                FutureBuilder<List<dynamic>>(
                  future: _alternateFoodSuggestions,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.separated(
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey[300]),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var suggestion = snapshot.data![index];
                            var foodItemDetails = suggestion['food_item'];
                            String foodItemName = foodItemDetails['name'];
                            String suggestedOn = suggestion['suggested_on'];
                            String suggestedTime = suggestion['suggested_time'];

                            return ListTile(
                              title: Text(foodItemName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Suggested on: $suggestedOn at $suggestedTime'),
                              leading: Icon(Icons.restaurant,
                                  color: Theme.of(context).primaryColor),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red)),
                        );
                      }
                    }
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ],
            ),
          ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              title: Text('Chat History',
                  style: Theme.of(context).textTheme.titleLarge),
              leading:
                  Icon(Icons.history, color: Theme.of(context).primaryColor),
              children: <Widget>[
                FutureBuilder<Map<String, dynamic>>(
                  future: _userChatHistory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.separated(
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey[300]),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            String date = snapshot.data!.keys.elementAt(index);
                            var chatDetails = snapshot.data![date];
                            return ListTile(
                              title: Text('Chat on: $date',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text('Messages: ${chatDetails.length}'),
                              leading: Icon(Icons.chat,
                                  color: Theme.of(context).primaryColor),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChatPage(messageData: chatDetails),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red)),
                        );
                      }
                    }
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
                ],
              );
            },
          );
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
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
}
