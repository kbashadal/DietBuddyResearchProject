import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_options_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/user_profile_page.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;

class ViewHistoryPage extends StatefulWidget {
  const ViewHistoryPage({Key? key}) : super(key: key);

  @override
  ViewHistoryPageState createState() => ViewHistoryPageState();
}

class ViewHistoryPageState extends State<ViewHistoryPage> {
  DateTime? _selectedDate;
  List<MealCaloriesData> _caloriesData = [];
  @override
  void initState() {
    super.initState();
    _fetchCaloriesForDate(
        DateTime.now()); // Fetch calories for today's date by default
  }

  Future<void> _fetchCaloriesForDate(DateTime date) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final String formattedDate = "${date.year}-${date.month}-${date.day}";
    final response = await http.get(Uri.parse(
        'http://localhost:5000/total_calories_by_email_and_date?email_id=$userEmail&date=$formattedDate'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<MealCaloriesData> fetchedData = [];
      data.forEach((mealType, calories) {
        fetchedData.add(MealCaloriesData(mealType, calories.toDouble()));
      });
      setState(() {
        _caloriesData = fetchedData;
      });
    } else {
      // Handle error or no data scenario
      setState(() {
        _caloriesData = [];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now(), // Use the current date if _selectedDate is null
      firstDate: DateTime(2000), // Adjust this to your requirement
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchCaloriesForDate(
          picked); // Fetch calories data for the selected date
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DietBuddy',
          style: TextStyle(
            fontSize: 24, // Adjusted for better proportionality
            fontWeight: FontWeight.bold,
            color: Theme.of(context)
                .primaryColor, // Use theme color for consistency
          ),
        ),
        backgroundColor: Colors.white, // Set a neutral color for the AppBar
        elevation: 0, // Remove shadow for a modern look
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding for better spacing
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.start, // Adjust alignment for natural flow
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                // backgroundColor: Theme.of(context)
                //     .colorScheme
                //     .onSurface, // Use theme color for consistency
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Rounded corners for a modern look
                ),
              ),
              child: const Text('Select Date'),
            ),
            const SizedBox(height: 20),
            if (_selectedDate != null)
              Text(
                'Selected Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(
                    fontSize: 16), // Adjust font size for readability
              ),
            Expanded(
              child: _createBarChart(),
            ),
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
        selectedItemColor:
            Theme.of(context).primaryColor, // Use theme color for consistency
        unselectedItemColor:
            Colors.grey, // Use a neutral color for unselected items
        onTap: (index) {
          // Navigation logic
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MealSummaryPage(
                          email:
                              Provider.of<UserProvider>(context, listen: false)
                                      .email ??
                                  '',
                        )),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InterventionsSummaryPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ViewHistoryPage()),
              );
              break;
          }
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
                    leading:
                        Icon(Icons.add, color: Theme.of(context).primaryColor),
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
                    leading: Icon(Icons.person,
                        color: Theme.of(context).primaryColor),
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
        backgroundColor: Theme.of(context)
            .colorScheme
            .secondary, // Use theme color for consistency
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _createBarChart() {
    // Calculate total calories
    final totalCalories =
        _caloriesData.fold(0.0, (double sum, item) => sum + item.calories);
    List<charts.Series<MealCaloriesData, String>> series = [
      charts.Series<MealCaloriesData, String>(
        id: 'Calories',
        domainFn: (MealCaloriesData data, _) => data.mealType,
        measureFn: (MealCaloriesData data, _) => data.calories,
        data: _caloriesData,
        labelAccessorFn: (MealCaloriesData row, _) => '${row.calories}',
        // Optional: Add color mapping if you want different colors
      )
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Total Calories: $totalCalories',
              style: const TextStyle(fontSize: 18)),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height *
              0.33, // Adjust the height to 33% of the screen height
          child: charts.BarChart(
            series,
            animate: true,
            vertical: false,
            barRendererDecorator: charts.BarLabelDecorator<String>(),
            domainAxis: const charts.OrdinalAxisSpec(),
            // Removed the legend configuration
          ),
        ),
      ],
    );
  }
}

class MealCaloriesData {
  final String mealType;
  final double calories;

  MealCaloriesData(this.mealType, this.calories);
}
