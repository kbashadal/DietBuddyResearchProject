import 'package:dietbuddy/chat_history.dart';
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
          ExpansionTile(
            title: const Text('Exercise'),
            leading: const Icon(Icons.fitness_center),
            children: <Widget>[
              FutureBuilder<List<dynamic>>(
                future: _exerciseSuggestions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        shrinkWrap: true, // Add this line
                        physics:
                            const NeverScrollableScrollPhysics(), // And this one
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          var suggestion = snapshot.data![index];
                          return ListTile(
                            title: Text(suggestion['exercise']['workout_type']),
                            subtitle: Text(
                                'Suggested on: ${suggestion['suggested_on']}'),
                            trailing: suggestion['suggested_time'] != null
                                ? Text(
                                    'Time: ${suggestion['suggested_time']} minutes')
                                : null,
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        title: Text('Error: ${snapshot.error}'),
                      );
                    }
                  }
                  return const ListTile(
                    title: CircularProgressIndicator(),
                  );
                },
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Food'),
            leading: const Icon(Icons.fastfood),
            children: <Widget>[
              FutureBuilder<List<dynamic>>(
                future: _alternateFoodSuggestions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          var suggestion = snapshot.data![index];
                          // Accessing the nested map for food item details
                          var foodItemDetails = suggestion['food_item'];
                          // Assuming 'name' is always present in the food item details
                          String foodItemName = foodItemDetails['name'];
                          // Accessing 'suggested_on' and 'suggested_time' directly from the suggestion map
                          String suggestedOn = suggestion['suggested_on'];
                          String suggestedTime = suggestion['suggested_time'];

                          return ListTile(
                            title: Text(foodItemName),
                            subtitle: Text(
                                'Suggested on: $suggestedOn at $suggestedTime'),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        title: Text('Error: ${snapshot.error}'),
                      );
                    } else {
                      return const ListTile(
                        title: Text('No food alternatives available.'),
                      );
                    }
                  }
                  return const ListTile(
                    title: CircularProgressIndicator(),
                  );
                },
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Chat History'),
            leading: const Icon(Icons.history),
            children: <Widget>[
              FutureBuilder<Map<String, dynamic>>(
                future: _userChatHistory,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          String date = snapshot.data!.keys.elementAt(index);
                          var chatDetails = snapshot.data![date];
                          return ListTile(
                            title: Text('Chat on: $date'),
                            subtitle: Text('Messages: ${chatDetails.length}'),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChatPage(messageData: chatDetails),
                                  ));
                            },
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        title: Text('Error: ${snapshot.error}'),
                      );
                    } else {
                      return const ListTile(
                        title: Text('No chat history available.'),
                      );
                    }
                  }
                  return const ListTile(
                    title: CircularProgressIndicator(),
                  );
                },
              ),
            ],
          ),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add Meal'),
                    onTap: () {
                      Navigator.pop(context); // Close the menu
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MealOptionsPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('View Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserProfilePage()),
                      ); // Close the menu
                      // Navigate to View Profile Page
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
