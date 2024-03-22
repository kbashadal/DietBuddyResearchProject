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
        title: const Text(
          'DietBuddy',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.green, // Adjust the color to match your branding
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: const Text('Select Date'),
            ),
            const SizedBox(height: 20),
            if (_selectedDate != null)
              Text(
                  'Selected Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
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
