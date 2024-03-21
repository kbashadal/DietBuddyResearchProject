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

  @override
  void initState() {
    super.initState();
    _fetchMealDataSummary();
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
        title: const Text('Meal Summary'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Today: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total Calories: ${getTotalCalories().toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: _mealData.isNotEmpty
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: charts.BarChart(
                          _createChartData(),
                          animate: true,
                          behaviors: [
                            charts.SeriesLegend(
                              position: charts.BehaviorPosition.top,
                              horizontalFirst: false,
                              cellPadding: const EdgeInsets.only(
                                  right: 2.0, bottom: 2.0),
                              showMeasures: true,
                              legendDefaultMeasure:
                                  charts.LegendDefaultMeasure.lastValue,
                              entryTextStyle: charts.TextStyleSpec(
                                  color:
                                      charts.MaterialPalette.gray.shadeDefault,
                                  fontFamily: 'Georgia',
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(),
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
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: const Text('View History'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ViewHistoryPage()),
                            ); // Close the menu
                            // Navigate to View History Page
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
                                  builder: (context) =>
                                      const UserProfilePage()),
                            ); // Close the menu
                            // Navigate to View History Page
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings_suggest_rounded),
                          title: const Text('View Interventions'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const InterventionsSummaryPage()),
                            ); // Close the menu
                            // Navigate to View History Page
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
          ),
        ],
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
}

class MealData {
  final String name;
  final double calories;
  final double caffeine;
  final double volume;
  final String mealType;

  MealData(this.name, this.calories, this.caffeine, this.volume, this.mealType);
}
