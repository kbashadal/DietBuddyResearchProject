import 'dart:convert';

import 'package:dietbuddy/add_entry_page.dart';
import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/user_profile_page.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:dietbuddy/view_history_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MealOptionsPage extends StatefulWidget {
  const MealOptionsPage({Key? key}) : super(key: key);

  @override
  MealOptionsPageState createState() => MealOptionsPageState();
}

class MealOptionsPageState extends State<MealOptionsPage> {
  int _currentIndex = 0;

  Future<Map<String, dynamic>> _fetchTotalCaloriesByEmailAndType(
      String mealType) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final response = await http.get(
      Uri.parse(
          'http://localhost:5000/total_calories_by_email_and_type?meal_type=$mealType&email_id=$userEmail'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      if (kDebugMode) {
        print(
            'Failed to fetch total calories for $mealType and email $userEmail');
      }
      return {
        'email_id': userEmail,
        'meal_type': mealType,
        'total_calories': 0
      };
    }
  }

  Future<Map<String, List<MealData>>> _userMealsByEmailAndMealtype(
      String mealTypeFilter) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final response = await http.get(
      Uri.parse(
          'http://localhost:5000/user_meals_by_email_and_type?meal_type=$mealTypeFilter&email_id=$userEmail'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> mealsData = jsonDecode(response.body);
      final Map<String, List<MealData>> userMeals = {};
      mealsData.forEach((mealType, mealList) {
        List<MealData> meals = [];
        for (var meal in mealList) {
          // Filter the meals based on the mealTypeFilter
          if (mealType == mealTypeFilter) {
            meals.add(MealData(meal[0], meal[1], meal[2], meal[3], meal[4]));
          }
        }
        if (meals.isNotEmpty) {
          userMeals[mealType] = meals;
        }
      });
      return userMeals;
    } else {
      if (kDebugMode) {
        print('Failed to fetch user meals for email $userEmail');
      }
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enhanced UI for a more professional and user-friendly experience
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
      body: Container(
        color: Colors.blue[50], // Added background color
        child: ListView(
          padding:
              const EdgeInsets.all(8.0), // Added padding for better spacing
          children: <Widget>[
            _buildMealTypeExpansionTile('Breakfast'),
            _buildMealTypeExpansionTile('Lunch'),
            _buildMealTypeExpansionTile('Dinner'),
            _buildMealTypeExpansionTile('Others'),
          ],
        ),
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

  Widget _buildMealTypeExpansionTile(String mealType) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchTotalCaloriesByEmailAndType(mealType),
      builder: (context, snapshot) {
        String titleText = mealType;
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          titleText +=
              ': ${snapshot.data!['total_calories'].toString()} Calories';
        }

        return ExpansionTile(
          leading: const Icon(Icons.restaurant),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(titleText)), // Use Expanded to avoid overflow
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddEntryPage(rowItemName: mealType)),
                  );
                },
                // To ensure the button does not interfere with the expansion action:
                padding: EdgeInsets.zero, // Minimize padding
                constraints: const BoxConstraints(), // Remove constraints
              ),
            ],
          ),
          children: <Widget>[
            FutureBuilder<Map<String, List<MealData>>>(
              future: _userMealsByEmailAndMealtype(mealType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      children: [
                        _buildMealDataList(snapshot.data![mealType]!),
                        // The ListTile for total calories is now moved to the title
                      ],
                    );
                  } else {
                    return ListTile(
                      title: Text('No $mealType data available'),
                    );
                  }
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMealDataList(List<MealData> meals) {
    return Column(
      children: meals
          .map((meal) => ListTile(
                title: Text(meal.name),
                subtitle: Text('Calories: ${meal.calories.toString()}'),
              ))
          .toList(),
    );
  }
}
