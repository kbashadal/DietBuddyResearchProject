import 'dart:convert';

import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_options_page.dart';
import 'package:dietbuddy/user_profile_page.dart';
import 'package:dietbuddy/view_history_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;

class MealSummaryPage extends StatefulWidget {
  final String email;

  const MealSummaryPage({Key? key, required this.email}) : super(key: key);

  @override
  MealSummaryPageState createState() => MealSummaryPageState();
}

class MealSummaryPageState extends State<MealSummaryPage> {
  late Map<String, double> _mealData = {};
  String _userName = ''; // Add a variable to store the user's name

  @override
  void initState() {
    super.initState();
    _fetchMealDataSummary();
    _fetchUserProfile(); // Fetch user profile on init
  }

  Future<void> _fetchUserProfile() async {
    const url =
        'http://127.0.0.1:5000/user_profile'; // Adjust the URL as needed
    try {
      final response = await http.get(
        Uri.parse('$url?email_id=${widget.email}'),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        setState(() {
          _userName = responseBody[
              'full_name']; // Assuming the key for the user's name is 'name'
        });
      } else {
        if (kDebugMode) {
          print('Failed to fetch user profile');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred while fetching user profile: $e');
      }
    }
  }

  double getTotalCalories() {
    return _mealData.values.fold(0, (sum, element) => sum + element);
  }

  Future<void> _fetchMealDataSummary() async {
    const url = 'http://127.0.0.1:5000/user_meals_summary_by_email';
    try {
      final response = await http.get(
        Uri.parse('$url?email_id=${widget.email}'),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        setState(() {
          // Adjusted to parse the nested dictionary
          _mealData = Map<String, double>.from(
              responseBody['calories_summary_by_meal_type']);
        });
      } else {
        if (kDebugMode) {
          print('Failed to fetch meal data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred while fetching meal data: $e');
      }
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
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Today: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft, // Align text to the left
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserProfilePage()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text:
                            'Welcome $_userName', // Use the _userName variable
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.trending_up, color: Colors.red),
                title: const Text('Activity',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: <Widget>[
                  FutureBuilder<double>(
                    future:
                        fetchSuggestedCaloriesLimit(), // Assuming this function is defined and returns Future<double>
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListTile(
                          title: Text(
                            'Total Calories: ${getTotalCalories().toStringAsFixed(2)} / ${snapshot.data}',
                            textAlign: TextAlign.left,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return const ListTile(
                          title: Text(
                            'Error fetching suggested calories',
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      // By default, show a loading spinner.
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                  _mealData.isNotEmpty
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2,
                          child: charts.BarChart(
                            _createChartData(),
                            animate: true,
                            vertical: false,
                            barGroupingType: charts.BarGroupingType.grouped,
                            behaviors: [
                              // charts.ChartTitle('',
                              //     behaviorPosition:
                              //         charts.BehaviorPosition.start,
                              //     titleOutsideJustification: charts
                              //         .OutsideJustification.middleDrawArea),
                              charts.SeriesLegend(
                                position: charts.BehaviorPosition.top,
                                horizontalFirst: false,
                                cellPadding: const EdgeInsets.only(
                                    right: 4.0, bottom: 4.0),
                                showMeasures: true,
                                legendDefaultMeasure:
                                    charts.LegendDefaultMeasure.lastValue,
                                entryTextStyle: charts.TextStyleSpec(
                                    color: charts
                                        .MaterialPalette.gray.shadeDefault,
                                    fontFamily: 'Georgia',
                                    fontSize: 9),
                              ),
                            ],
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ],
              ),
              const ExpansionTile(
                leading: Icon(Icons.local_dining, color: Colors.green),
                title: Text('Diet Tips',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Eat a variety of foods to ensure a balanced diet.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Ensure your diet is rich in fruits and vegetables for essential vitamins and minerals.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Limit intake of sugars and saturated fats for better health outcomes.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Stay hydrated by drinking plenty of water throughout the day.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const ExpansionTile(
                leading: Icon(Icons.star, color: Colors.amber),
                title: Text('Awards',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Consistency Master - For logging meals 30 days in a row.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Balanced Diet Achiever - For maintaining a balanced diet for a week.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Hydration Hero - For meeting water intake goals 7 days in a row.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Fitness Fanatic - For completing all workout goals in a month.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
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
                                  builder: (context) =>
                                      const MealOptionsPage()),
                            );
                          },
                        ),
                        // ListTile(
                        //   leading: const Icon(Icons.history),
                        //   title: const Text('View History'),
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //           builder: (context) =>
                        //               const ViewHistoryPage()),
                        //     ); // Close the menu
                        //     // Navigate to View History Page
                        //   },
                        // ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('View Profile'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const UserProfilePage()),
                            ); // Close the menu
                            // Navigate to View History Page
                          },
                        ),
                        // ListTile(
                        //   leading: const Icon(Icons.settings_suggest_rounded),
                        //   title: const Text('View Interventions'),
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //           builder: (context) =>
                        //               const InterventionsSummaryPage()),
                        //     ); // Close the menu
                        //     // Navigate to View History Page
                        //   },
                        // ),
                      ],
                    );
                  },
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
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
                        email: widget.email,
                      )),
            );
          }
          // Handle other indices if needed
        },
      ),
    );
  }

  List<charts.Series<MealData, String>> _createChartData() {
    final List<MealData> dataList = _mealData.entries
        .map((entry) => MealData(entry.key, entry.value, 0, 0, entry.key))
        .toList();

    List<charts.Series<MealData, String>> seriesList = [];

    var colors = [
      charts.MaterialPalette.blue.shadeDefault,
      charts.MaterialPalette.red.shadeDefault,
      charts.MaterialPalette.green.shadeDefault,
      charts.MaterialPalette.yellow.shadeDefault,
      charts.MaterialPalette.purple.shadeDefault,
      // Add more colors as needed
    ];

    for (int i = 0; i < dataList.length; i++) {
      var mealData = dataList[i];
      seriesList.add(charts.Series<MealData, String>(
        id: mealData.mealType,
        domainFn: (MealData meals, _) => meals.mealType,
        measureFn: (MealData meals, _) => meals.calories,
        data: [mealData],
        colorFn: (_, __) => colors[i % colors.length],
      ));
    }

    return seriesList;
  }

  Future<double> fetchSuggestedCaloriesLimit() async {
    // Implement the logic to fetch the suggested calories limit
    // This is a placeholder for actual implementation
    final email = widget.email; // Assuming widget.email holds the user's email
    final url = Uri.parse(
        'http://localhost:5000/get_suggested_calories?email_id=$email');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['suggested_calories'];
    } else {
      throw Exception('Failed to load suggested calories limit');
    }
  }
}

class MealData {
  final String name;
  final double calories;
  final double caffeine;
  final double volume;
  final String mealType;

  MealData(this.name, this.calories, this.caffeine, this.volume, this.mealType);
}
