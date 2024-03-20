import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class UserProvider extends ChangeNotifier {
  String? _email;

  String? get email => _email;

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DietBuddy',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() =>
      HomePageState(); // Renamed _HomePageState to HomePageState to make it public
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DietBuddy'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Image.asset(
            //     'assets/welcome_image.png'), // Replace with your asset image path
            const Text(
              'Eat Healthy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Maintaining good health should be the primary focus of everyone.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegistrationPage()),
                );
              },
              child: const Text('Get Started'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Already Have An Account? Log In'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _selectedGender = 'Male'; // Defa
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  File? _image;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImageProfile() async {
    final ImagePicker picker = ImagePicker(); // Renamed _picker to picker
    // Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // If an image is selected, update the state to display the image
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> registerUser(BuildContext context) async {
    // Remove the localContext variable

    const url = 'http://127.0.0.1:5000/register';
    final Map<String, dynamic> registrationData = {
      'fullName': _fullNameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'gender': _selectedGender,
      'height': _heightController.text,
      'weight': _weightController.text,
      'dateOfBirth': "${_selectedDate.toLocal()}".split(' ')[0],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registrationData),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return; // Check if the widget is still in the widget tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'])),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        if (!mounted) return; // Check if the widget is still in the widget tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'])),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred while sending registration data: $e');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // from your existing code
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'DietBuddy',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email ID',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.check_circle_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Re-enter Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              items: <String>['Male', 'Female', 'Other']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Date of Birth'),
              subtitle: Text(
                "${_selectedDate.toLocal()}".split(' ')[0],
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImageProfile, // Update this line
              child: const Text('Upload Profile Pic'),
            ),
            if (_image != null) Image.file(_image!),
            ElevatedButton(
              onPressed: () {
                // Handle registration logic
                registerUser(context);
              },
              child: const Text('Next'),
            ),
            // Add additional fields for profile picture, gender, height, weight, and date of birth
            // ...
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    const url = 'http://127.0.0.1:5000/login';
    final Map<String, dynamic> loginData = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return; // Check if the widget is still in the widget tree
        // Navigate to MealSummaryPage upon successful login
        Provider.of<UserProvider>(context, listen: false)
            .setEmail(_emailController.text);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MealSummaryPage(email: _emailController.text)),
        );
      } else {
        // Handle login error
        if (kDebugMode) {
          print('Login failed: ${responseBody['message']}');
        }
        // Show error message
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred while sending login data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginUser,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

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

class AddEntryPage extends StatefulWidget {
  final String rowItemName; // Add this line

  const AddEntryPage({Key? key, required this.rowItemName})
      : super(key: key); // Modify this line

  @override
  AddEntryPageState createState() => AddEntryPageState();
}

class AddEntryPageState extends State<AddEntryPage> {
  final ImagePicker _picker = ImagePicker();
  String? selectedCategory;
  String? selectedItem;
  List<dynamic> categories = [];
  List<dynamic> items = [];
  String? mealType;
  String? volumeInput; // Variable to store the volume input by the user
  String? caffeineInput; // Variable to store the caffeine input by the user
  String?
      per100gramsInput; // Variable to store the per 100 grams input by the user
  int quantity = 1; // Initialize quantity with a default value of 1
  late Future<Map<String, List<MealData>>> _sendDataToAPIFuture;
  Map<String, dynamic>? predictedImageCaloriesWithFoodItem;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    mealType = widget.rowItemName;
    _sendDataToAPIFuture = _userMealsByEmail(widget.rowItemName);
  }

  Future<Map<String, List<MealData>>> _userMealsByEmail(
      String mealTypeFilter) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final response = await http.get(
      Uri.parse(
          'http://localhost:5000/user_meals_by_email?email_id=$userEmail'),
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

  Future<void> _pickImagePredict() async {
    final ImagePicker picker = ImagePicker();
    // Show dialog to choose between Gallery or Camera
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select the image source'),
        actions: <Widget>[
          TextButton(
            child: const Text('Camera'),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
          TextButton(
            child: const Text('Gallery'),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      // Handle the picked image
      if (image != null) {
        // Prepare for file upload
        var request = http.MultipartRequest(
            'POST', Uri.parse('http://127.0.0.1:5000/predictFromImage'));
        request.files
            .add(await http.MultipartFile.fromPath('image', image.path));

        // Send the request
        var response = await request.send();

        // Handle the response from the API
        if (response.statusCode == 200) {
          // Get the response body
          var responseData = await response.stream.toBytes();
          var responseString = String.fromCharCodes(responseData);
          predictedImageCaloriesWithFoodItem = jsonDecode(responseString);

          // Use the jsonResponse
          print(predictedImageCaloriesWithFoodItem);
          setState(() {});
        } else {
          // Handle error
          print('Failed to upload image and get response');
        }
      }
    }
  }

  Future<void> fetchItems(String category) async {
    final response = await http.get(
        Uri.parse('http://localhost:5000/food_items_by_category/$category'));
    if (response.statusCode == 200) {
      final List<dynamic> fetchedItems = jsonDecode(response.body);
      setState(() {
        items = fetchedItems;
      });
    } else {
      // Handle server error
      if (kDebugMode) {
        print('Failed to load items for category $category');
      }
    }
  }

  Future<Map<String, dynamic>?> sendDataToAPI() async {
    final userEmail = Provider.of<UserProvider>(context, listen: false).email;

    // Define the list of categories that require volume and caffeine input
    const List<String> volumeAndCaffeineCategories = [
      "Coffee",
      "Energy Drinks",
      "Soft Drinks",
      "Tea",
      "Water"
    ];

    // Check if the selectedCategory is in the list
    final bool isVolumeAndCaffeineCategory =
        volumeAndCaffeineCategories.contains(selectedCategory);

    // Prepare the data to be sent to the Flask API based on the category
    final Map<String, dynamic> dataToSend;
    String endpoint;

    if (isVolumeAndCaffeineCategory) {
      // Use volume and caffeine fields
      dataToSend = {
        'drink': selectedItem,
        'selectedCategory': selectedCategory,
        'Volume (ml)': volumeInput,
        'Caffeine (mg)': caffeineInput,
      };
      endpoint = 'http://127.0.0.1:5000/predictdrink';
    } else {
      // Use weight field instead
      dataToSend = {
        'FoodItem': selectedItem,
        'selectedCategory': selectedCategory,
        'per100grams': per100gramsInput,
      };
      endpoint = 'http://127.0.0.1:5000/predictNonDrink';
    }

    // Call the Flask API for prediction
    final url = Uri.parse(endpoint);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(dataToSend),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final Map<String, dynamic> userMealData;

      // After getting the prediction, add the user meal to the database
      final addMealUrl = Uri.parse('http://127.0.0.1:5000/add_user_meals');
      if (isVolumeAndCaffeineCategory) {
        userMealData = {
          'user_email': userEmail,
          'food_item_name': selectedItem,
          'meal_type_name': mealType,
          'Caffeine': caffeineInput,
          'Volume (ml)': volumeInput,
          "date": DateTime.now().toString(),
          "time": DateFormat('HH:mm:ss').format(DateTime.now())
        };
      } else {
        userMealData = {
          'user_email': userEmail,
          'food_item_name': selectedItem,
          'meal_type_name': mealType,
          'weight(gms)': per100gramsInput,
          "date": DateTime.now().toString(),
          "time": DateFormat('HH:mm:ss').format(DateTime.now())
        };
      }
      List<Map<String, dynamic>> mealsList = [];
      mealsList.add(userMealData);

      final addMealResponse = await http.post(
        addMealUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(mealsList),
      );

      if (addMealResponse.statusCode == 201) {
        // Handle successful addition of user meal
        final Map<String, dynamic> addMealResponseData =
            json.decode(addMealResponse.body);
        return responseData; // Return the decoded response data from adding the meal
      } else {
        // Handle error or invalid response from adding the meal
        if (kDebugMode) {
          print('Error adding meal: ${addMealResponse.body}');
        }
        return null;
      }
    } else {
      // Handle error or invalid response from prediction
      if (kDebugMode) {
        print('Error: ${response.body}');
      }
      return null;
    }
  }

  Future<void> fetchCategories() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:5000/food_categories'));
    if (response.statusCode == 200) {
      final List<dynamic> fetchedCategories = jsonDecode(response.body);
      setState(() {
        categories = fetchedCategories;
      });
    } else {
      // Handle server error
      if (kDebugMode) {
        print('Failed to load categories');
      }
    }
  }

  Future<void> _addManualEntry() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close the dialog
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Define the categories that require volume and caffeine input
            const List<String> volumeAndCaffeineCategories = [
              "Coffee",
              "Energy Drinks",
              "Soft Drinks",
              "Tea",
              "Water"
            ];

            return AlertDialog(
              title: const Text('Add Entry'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('You can add a new entry manually.'),
                    Text('Meal Type: $mealType',
                        style: const TextStyle(
                            fontSize: 20)), // Display the meal type

                    DropdownButton<String>(
                      hint: const Text('Select Category'),
                      value: selectedCategory,
                      onChanged: (String? newValue) async {
                        selectedItem = null; // Reset item selection
                        await fetchItems(
                            newValue!); // Fetch items for the selected category
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                      items: categories
                          .map<DropdownMenuItem<String>>((dynamic category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Text(category['name']),
                        );
                      }).toList(),
                    ),
                    if (items.isNotEmpty) ...[
                      DropdownButton<String>(
                        hint: const Text('Select Item'),
                        value: selectedItem,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedItem = newValue;
                          });
                        },
                        items:
                            items.map<DropdownMenuItem<String>>((dynamic item) {
                          return DropdownMenuItem<String>(
                            value: item['name'],
                            child: Text(item['name']),
                          );
                        }).toList(),
                      ),
                    ],
                    if (selectedItem != null &&
                        volumeAndCaffeineCategories
                            .contains(selectedCategory)) ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Volume (ml)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          volumeInput = value;
                          setState(() {
                            volumeInput =
                                value; // Ensure this updates volumeInput
                          });
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Caffeine (mg)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          caffeineInput = value;
                          setState(() {
                            caffeineInput =
                                value; // Ensure this updates caffeineInput
                          });
                        },
                      ),
                    ] else if (selectedItem != null) ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Weight (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          per100gramsInput = value;
                          setState(() {
                            per100gramsInput =
                                value; // Ensure this updates caffeineInput
                          });
                        },
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                        ),
                        Text('$quantity'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Dismiss the dialog
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    final response = await sendDataToAPI();
                    if (!mounted) {
                      return; // Check if the widget is still mounted
                    }
                    if (response != null) {
                      Navigator.of(context)
                          .pop(); // Use context instead of dialogContext
                      setState(() {
                        _sendDataToAPIFuture = _userMealsByEmail(mealType!);
                      });
                    } else {
                      // Optionally, handle the case where response is null, e.g., show an error message
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Type: $mealType',
            style: const TextStyle(fontSize: 20)), // Display the meal type
        // Other AppBar properties as needed
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add an Entry Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _addManualEntry,
                    child: const Column(
                      children: [
                        Icon(Icons.add),
                        Text('Manually Add'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickImagePredict,
                    child: const Column(
                      children: [
                        Icon(Icons.camera_alt),
                        Text('Scan Image'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Trends Section
            // ... Implement Trends section based on the design
            // Trainer Tips Section
            // ... Implement Trainer Tips section based on the design
            // Awards Section
            // ... Implement Awards section based on the design

            // Show the table
            FutureBuilder<Map<String, List<MealData>>>(
              future:
                  _sendDataToAPIFuture, // Ensure this future returns Map<String, List<MealData>>
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, List<MealData>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    // Define the columns for the DataTable
                    List<DataColumn> columns = const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Calories')),
                    ];

                    // Create rows for the DataTable
                    List<DataRow> rows = [];

                    snapshot.data!.forEach((mealType, meals) {
                      for (MealData meal in meals) {
                        List<DataCell> cells = [
                          DataCell(Text(meal.name)),
                          DataCell(Text('${meal.calories}')),
                        ];
                        rows.add(DataRow(cells: cells));
                      }
                    });
                    if (predictedImageCaloriesWithFoodItem != null) {
                      predictedImageCaloriesWithFoodItem!.forEach((key, value) {
                        List<DataCell> cells = [
                          DataCell(Text(key)), // Name of the food item
                          DataCell(Text('$value')), // Calories
                        ];
                        rows.add(DataRow(cells: cells));
                      });
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: columns,
                        rows: rows,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                }
                // By default, show a loading spinner
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MealOptionsPage extends StatefulWidget {
  const MealOptionsPage({Key? key}) : super(key: key);

  @override
  MealOptionsPageState createState() => MealOptionsPageState();
}

class MealOptionsPageState extends State<MealOptionsPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Meal Type'),
      ),
      body: ListView(
        children: <Widget>[
          _buildMealTypeExpansionTile('Breakfast'),
          _buildMealTypeExpansionTile('Lunch'),
          _buildMealTypeExpansionTile('Dinner'),
          _buildMealTypeExpansionTile('Others'),
        ],
      ),
    );
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
        title: const Text('View History'),
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
