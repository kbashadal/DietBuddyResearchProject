import 'dart:convert';
import 'dart:ffi';

import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_options_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/user_profile_page.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:dietbuddy/view_history_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class AddEntryPage extends StatefulWidget {
  final String rowItemName; // Add this line

  const AddEntryPage({Key? key, required this.rowItemName})
      : super(key: key); // Modify this line

  @override
  AddEntryPageState createState() => AddEntryPageState();
}

class AddEntryPageState extends State<AddEntryPage> {
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
          if (kDebugMode) {
            print(predictedImageCaloriesWithFoodItem);
          }
          setState(() {});
        } else {
          // Handle error
          if (kDebugMode) {
            print('Failed to upload image and get response');
          }
        }
      }
    }
  }

  Future<double> fetchSuggestedCaloriesLimit() async {
    final profileUrl = Uri.parse(
        'http://localhost:5000/user_profile?email_id=${Provider.of<UserProvider>(context, listen: false).email}');
    final profileResponse = await http.get(profileUrl);
    if (profileResponse.statusCode == 200) {
      final profileData = json.decode(profileResponse.body);
      return profileData['suggested_calories'];
    } else {
      throw Exception('Failed to load suggested calories limit');
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
    // check for total calories intake per day if exceeds limit show a option to choose from exercise, alternate food, open api chatbot
    final currentDate =
        DateTime.now().toString().split(' ')[0]; // Format: YYYY-MM-DD
    final totalCaloriesUrl = Uri.parse(
        'http://localhost:5000/total_calories_by_email_per_day?email_id=$userEmail&date=$currentDate');
    final totalCaloriesResponse = await http.get(totalCaloriesUrl);

    if (totalCaloriesResponse.statusCode == 200) {
      final totalCaloriesData = json.decode(totalCaloriesResponse.body);
      final totalCalories = totalCaloriesData['total_calories'];
      // Assuming there's a daily calorie limit set, for example, 2000 calories

      final double dailyCalorieLimit = await fetchSuggestedCaloriesLimit();

      if (totalCalories > dailyCalorieLimit) {
        await showInterventionDialog();
        if (kDebugMode) {
          print(
              'Total daily calorie intake of $totalCalories exceeds the limit of $dailyCalorieLimit. Consider exercising or choosing alternate foods.');
        }
        return null;
      }
    } else {
      // Handle error in fetching total calories
      if (kDebugMode) {
        print('Failed to fetch total daily calorie intake for $currentDate');
      }
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

  Future<void> showExerciseSuggestionsWithTime(int dailyCalorieLimit) async {
    final userEmailNonNull =
        Provider.of<UserProvider>(context, listen: false).email!;
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/suggestExerciseWithTime'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'dailyCalorieLimit': dailyCalorieLimit}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> suggestionsWithTime =
          data['top_3_exercises_with_time'];

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Exercise Suggestions with Time"),
            content: SingleChildScrollView(
              child: ListBody(
                children: suggestionsWithTime.map((suggestion) {
                  return Text(
                      "${suggestion['exercise']}: for ${suggestion['time'].toStringAsFixed(2)} minutes");
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InterventionsSummaryPage()),
                  ); // Close the suggestions dialog
                  // Here, save each exercise suggestion for the non-null userEmail
                  // ignore: avoid_function_literals_in_foreach_calls
                  suggestionsWithTime.forEach((suggestion) async {
                    await saveExerciseSuggestion(userEmailNonNull,
                        suggestion['exercise'], suggestion['time']);
                  });
                  // Optionally, navigate to InterventionPage with the suggestions data
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } else {
      if (kDebugMode) {
        print('Failed to fetch exercise suggestions with time');
      }
    }
  }

  Future<void> saveExerciseSuggestion(String emailId, String exerciseName,
      [double? suggestedTime]) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/save_user_exercise_suggestion'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'emailId': emailId,
        'exerciseName': exerciseName,
        'suggestedTime': suggestedTime, // This is optional, can be null
      }),
    );

    if (response.statusCode != 201) {
      if (kDebugMode) {
        print('Failed to save exercise suggestion for $exerciseName');
      }
    }
  }

  Future<void> saveUserAlternateFood(String email, String foodItemName) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/save_user_alternate_food'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'foodItemName': foodItemName,
      }),
    );

    if (response.statusCode != 201) {
      if (kDebugMode) {
        print('Failed to save alternate food suggestion for $foodItemName');
      }
    }
  }

  Future<void> showExerciseSuggestions(int dailyCalorieLimit) async {
    final userEmail = Provider.of<UserProvider>(context, listen: false).email;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/suggestExercise'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'dailyCalorieLimit': dailyCalorieLimit}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<String> suggestions =
          List<String>.from(data['top_3_suggestions']);
      final userEmailNonNull = userEmail!; // Ensure userEmail is not null

      for (String exerciseName in suggestions) {
        await saveExerciseSuggestion(userEmailNonNull, exerciseName);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Exercise Suggestions"),
            content: SingleChildScrollView(
              child: ListBody(
                children:
                    suggestions.map((suggestion) => Text(suggestion)).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the suggestions dialog
                  // Navigate to InterventionPage with the suggestions data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InterventionsSummaryPage()),
                  );
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } else {
      if (kDebugMode) {
        print('Failed to fetch exercise suggestions');
      }
    }
  }

  Future<void> showAlternateFoodSuggestions(int dailyCalorieLimit) async {
    final userEmail = Provider.of<UserProvider>(context, listen: false).email;
    final userEmailNonNull = userEmail!; // Ensure userEmail is not null

    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:5000/get_alternate_food?dailyCalorieLimit=$dailyCalorieLimit'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Map<String, dynamic>> suggestions =
          List<Map<String, dynamic>>.from(data['alternate_food_suggestions']);
      for (Map<String, dynamic> suggestion in suggestions) {
        String foodItemName = suggestion.keys.first;
        await saveUserAlternateFood(userEmailNonNull, foodItemName);
      }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Alternate Food Suggestions"),
            content: SingleChildScrollView(
              child: ListBody(
                children: suggestions.map((suggestion) {
                  return Text(
                      "${suggestion.keys.first}: ${suggestion.values.first} calories ");
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InterventionsSummaryPage()),
                  );
                  // Removed the incorrect Navigator.push to InterventionPage with exerciseSuggestions
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } else {
      if (kDebugMode) {
        print('Failed to fetch alternate food suggestions');
      }
    }
  }

  Future<void> showInterventionDialog() async {
    final userEmail = Provider.of<UserProvider>(context, listen: false).email;
    final currentDate =
        DateTime.now().toString().split(' ')[0]; // Format: YYYY-MM-DD
    final totalCaloriesUrl = Uri.parse(
        'http://localhost:5000/total_calories_by_email_per_day?email_id=$userEmail&date=$currentDate');
    final totalCaloriesResponse = await http.get(totalCaloriesUrl);

    if (totalCaloriesResponse.statusCode == 200) {
      final totalCaloriesData = json.decode(totalCaloriesResponse.body);
      final totalCalories = totalCaloriesData['total_calories'];
      const dailyCalorieLimit = 20; // Example daily calorie limit
      if (totalCalories > dailyCalorieLimit) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Daily Calorie Limit Exceeded"),
              content: const Text("Choose an option to proceed:"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showExerciseSuggestionsWithTime(
                        dailyCalorieLimit); // Show exercise suggestions

                    // Implement navigation to Suggest Exercise Page
                  },
                  child: const Text("Suggest Exercise"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showAlternateFoodSuggestions(dailyCalorieLimit);
                    // Implement navigation to Suggest Food Alternatives Page
                  },
                  child: const Text("Suggest Food Alternatives"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Implement opening Chat Bot
                  },
                  child: const Text("Chat with DietBot"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Go back to the previous screen
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
        return; // Stop further execution after showing the dialog
      }
    } else {
      if (kDebugMode) {
        print('Failed to fetch total daily calorie intake for $currentDate');
      }
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MealOptionsPage()),
                      );
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
        title: const Text(
          'DietBuddy',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.green, // Adjust the color to match your branding
          ),
        ),
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
            // FutureBuilder<Map<String, List<MealData>>>(
            //   future:
            //       _sendDataToAPIFuture, // Ensure this future returns Map<String, List<MealData>>
            //   builder: (BuildContext context,
            //       AsyncSnapshot<Map<String, List<MealData>>> snapshot) {
            //     if (snapshot.connectionState == ConnectionState.done) {
            //       if (snapshot.hasData) {
            //         // Define the columns for the DataTable
            //         List<DataColumn> columns = const [
            //           DataColumn(label: Text('Name')),
            //           DataColumn(label: Text('Calories')),
            //         ];

            //         // Create rows for the DataTable
            //         List<DataRow> rows = [];

            //         snapshot.data!.forEach((mealType, meals) {
            //           for (MealData meal in meals) {
            //             List<DataCell> cells = [
            //               DataCell(Text(meal.name)),
            //               DataCell(Text('${meal.calories}')),
            //             ];
            //             rows.add(DataRow(cells: cells));
            //           }
            //         });
            //         if (predictedImageCaloriesWithFoodItem != null) {
            //           predictedImageCaloriesWithFoodItem!.forEach((key, value) {
            //             List<DataCell> cells = [
            //               DataCell(Text(key)), // Name of the food item
            //               DataCell(Text('$value')), // Calories
            //             ];
            //             rows.add(DataRow(cells: cells));
            //           });
            //         }

            //         return SingleChildScrollView(
            //           scrollDirection: Axis.horizontal,
            //           child: DataTable(
            //             columns: columns,
            //             rows: rows,
            //           ),
            //         );
            //       } else if (snapshot.hasError) {
            //         return Text('Error: ${snapshot.error}');
            //       }
            //     }
            //     // By default, show a loading spinner
            //     return const CircularProgressIndicator();
            //   },
            // ),
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
}
