import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_options_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/udpate_select_activity.dart';
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
  int _currentIndex = 2;
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
        'https://dietbuddyresearchproject.onrender.com/total_calories_by_email_and_date?email_id=$userEmail&date=$formattedDate'));

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
        backgroundColor: Colors.indigo, // Updated color for a professional look
        title: Image.asset(
          'assets/name.png',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16.0), // Enhanced padding for better spacing
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Maintain natural flow
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align items to the start
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.greenAccent[400], // Text color
                elevation: 4, // Shadow depth
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12), // Smooth rounded corners
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 15), // Padding inside the button
              ),
              child: const Text(
                'Select Date',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold), // Bolder and larger text
              ),
            ),
            const SizedBox(
                height: 24), // Increased spacing for visual separation
            if (_selectedDate != null)
              Text(
                'Selected Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(
                  fontSize: 20, // Larger font size for better readability
                  fontWeight: FontWeight.bold, // Bold font for emphasis
                  color: Colors.deepPurple, // Color for visual appeal
                ),
              ),
            const SizedBox(height: 24), // Additional spacing before the chart
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
        // Already on the ViewHistoryPage, no need to navigate
        break;
    }
  }

  Future<double> fetchSuggestedCaloriesLimit() async {
    final profileUrl = Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/user_profile?email_id=${Provider.of<UserProvider>(context, listen: false).email}');
    final profileResponse = await http.get(profileUrl);
    if (profileResponse.statusCode == 200) {
      final profileData = json.decode(profileResponse.body);
      return profileData['suggested_calories'];
    } else {
      throw Exception('Failed to load suggested calories limit');
    }
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
        FutureBuilder<double>(
          future: fetchSuggestedCaloriesLimit(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text(
                  'Total Calories: $totalCalories / ${snapshot.data}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text(
                  'Total Calories: $totalCalories / Suggested Limit: Error fetching limit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              );
            }
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Text(
                'Total Calories: $totalCalories / Suggested Limit: Loading...',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            );
          },
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: charts.BarChart(
              series,
              animate: true,
              vertical: false, // Use a horizontal bar chart
              barRendererDecorator: charts.BarLabelDecorator<String>(
                labelPosition: charts.BarLabelPosition.auto,
              ),
              // Adjust the domain axis to be the "vertical" axis visually
              domainAxis: const charts.OrdinalAxisSpec(
                renderSpec: charts.SmallTickRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                    fontSize: 14,
                    color: charts.MaterialPalette.black,
                  ),
                ),
              ),
              // Optionally adjust the measure axis to improve the layout
              primaryMeasureAxis: const charts.NumericAxisSpec(
                renderSpec: charts.GridlineRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                    fontSize: 14,
                    color: charts.MaterialPalette.black,
                  ),
                ),
              ),
              behaviors: [
                charts.ChartTitle(
                  'Calories by Meal Type',
                  behaviorPosition: charts.BehaviorPosition.top,
                  titleOutsideJustification: charts.OutsideJustification.start,
                  innerPadding: 18,
                  titleStyleSpec: const charts.TextStyleSpec(fontSize: 18),
                ),
              ],
            ),
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
