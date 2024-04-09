import 'dart:convert';

import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_options_page.dart';
import 'package:dietbuddy/user_profile_page.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:dietbuddy/view_history_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:provider/provider.dart';

class MealSummaryPage extends StatefulWidget {
  final String email;

  const MealSummaryPage({Key? key, required this.email}) : super(key: key);

  @override
  MealSummaryPageState createState() => MealSummaryPageState();
}

class MealSummaryPageState extends State<MealSummaryPage> {
  late Map<String, double> _mealData = {};
  int _currentIndex = 0;
  String _userName = ''; // Add a variable to store the user's name

  @override
  void initState() {
    super.initState();
    _fetchMealDataSummary();
    _fetchUserProfile(); // Fetch user profile on init
  }

  Future<void> _fetchUserProfile() async {
    const url =
        'https://dietbuddyresearchproject.onrender.com/user_profile'; // Adjust the URL as needed
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
    const url =
        'https://dietbuddyresearchproject.onrender.com/user_meals_summary_by_email';
    // const url = 'http://127.0.0.1:5000/user_meals_summary_by_email';
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
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Changed to a more academic color
        title: Image.asset(
          'assets/name.png', // Changed asset name for a more academic look
          width: 150, // Adjusted size for a more refined look
          height: 150,
          fit: BoxFit.contain,
        ),
        centerTitle: true, // Centered the title for a more balanced look
      ),
      body: SingleChildScrollView(
        // Enhanced scroll view for adaptability across various screen sizes
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.white, // Lighter shade for the top
                Colors.white, // Slightly darker shade towards the bottom
              ],
            ),
          ), // Utilizing a gradient for a more elegant background
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .start, // Align content to the start for a clean look
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Today: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.blueGrey[900],
                    fontWeight: FontWeight.bold,
                  ), // Enhanced text style for a more professional appearance
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserProfilePage()),
                    );
                  },
                  child: Text(
                    'Welcome, $_userName',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.deepPurple[400],
                      fontWeight: FontWeight.bold,
                    ), // Upgraded text style for welcoming message
                  ),
                ),
              ),
              _buildActivitySection(context,
                  theme), // Modularized sections for improved code readability
              _buildDietTipsSection(theme),
              _buildAwardsSection(theme),
            ],
          ),
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

  Widget _buildActivitySection(BuildContext context, ThemeData theme) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: Icon(Icons.trending_up, color: theme.primaryColor),
      title: Text('Activity', style: theme.textTheme.titleMedium),
      children: <Widget>[
        FutureBuilder<double>(
          future: fetchSuggestedCaloriesLimit(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListTile(
                title: Text(
                  'Total Calories: ${getTotalCalories().toStringAsFixed(2)} / ${snapshot.data?.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            } else if (snapshot.hasError) {
              return ListTile(
                title: Text(
                  'Error fetching suggested calories',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        _mealData.isNotEmpty
            ? _buildBarChart(context)
            : const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildDietTipsSection(ThemeData theme) {
    return ExpansionTile(
      leading: Icon(Icons.local_dining, color: theme.primaryColor),
      title: Text('Diet Tips', style: theme.textTheme.titleMedium),
      children: <Widget>[
        ListTile(
          title: Text(
            'Eat a variety of foods to ensure a balanced diet.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        ListTile(
          title: Text(
            'Ensure your diet is rich in fruits and vegetables for essential vitamins and minerals.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        ListTile(
          title: Text(
            'Limit intake of sugars and saturated fats for better health outcomes.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        ListTile(
          title: Text(
            'Stay hydrated by drinking plenty of water throughout the day.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildAwardsSection(ThemeData theme) {
    return ExpansionTile(
      leading: Icon(Icons.star, color: theme.primaryColor),
      title: Text('Awards', style: theme.textTheme.titleMedium),
      children: <Widget>[
        ListTile(
          title: Text(
            'Consistency Master - For logging meals 30 days in a row.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        ListTile(
          title: Text(
            'Balanced Diet Achiever - For maintaining a balanced diet for a week.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        ListTile(
          title: Text(
            'Hydration Hero - For meeting water intake goals 7 days in a row.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        ListTile(
          title: Text(
            'Fitness Fanatic - For completing all workout goals in a month.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context) {
    // Convert _mealData into a list of Series for the chart
    List<charts.Series<MealCalories, String>> seriesList = _createChartData();

    return Container(
      height: 200, // Set a fixed height for the chart container
      padding: const EdgeInsets.all(10),
      child: charts.BarChart(
        seriesList,
        animate: true, // Adds animation to the chart
        // Configure the axis to use string values
        domainAxis: const charts.OrdinalAxisSpec(),
        // Configure bar renderer with corner radius
        defaultRenderer: charts.BarRendererConfig(
            cornerStrategy: const charts.ConstCornerStrategy(30)),
        behaviors: [
          // Add a chart title
          charts.ChartTitle('Calories by Meal Type',
              behaviorPosition: charts.BehaviorPosition.top,
              titleOutsideJustification: charts.OutsideJustification.start,
              innerPadding: 18),
          // Add legends
          charts.SeriesLegend(
            position: charts.BehaviorPosition.bottom,
            horizontalFirst: false,
            cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
          )
        ],
      ),
    );
  }

  List<charts.Series<MealCalories, String>> _createChartData() {
    List<MealCalories> data = _mealData.entries
        .map((entry) => MealCalories(entry.key, entry.value))
        .toList();

    return [
      charts.Series<MealCalories, String>(
        id: 'Calories',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (MealCalories calories, _) => calories.mealType,
        measureFn: (MealCalories calories, _) => calories.calories,
        data: data,
      )
    ];
  }

  Future<double> fetchSuggestedCaloriesLimit() async {
    // Implement the logic to fetch the suggested calories limit
    // This is a placeholder for actual implementation
    final email = widget.email; // Assuming widget.email holds the user's email
    final url = Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/get_suggested_calories?email_id=$email');
    // final url = Uri.parse(
    //     'http://127.0.0.1:5000/get_suggested_calories?email_id=$email');
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

class MealCalories {
  final String mealType;
  final double calories;

  MealCalories(this.mealType, this.calories);
}
