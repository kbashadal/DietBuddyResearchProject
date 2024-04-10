import 'dart:convert';
import 'package:dietbuddy/diet_chat_bot_page.dart';
import 'package:dietbuddy/interventions_summary_page.dart';
import 'package:dietbuddy/meal_options_page.dart';
import 'package:dietbuddy/meal_summary_page.dart';
import 'package:dietbuddy/udpate_select_activity.dart';
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
  int _currentIndex = 0;
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
  // ignore: unused_field
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
          'https://dietbuddyresearchproject.onrender.com/user_meals_by_email?email_id=$userEmail'),
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
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("Processing image..."),
                  ],
                ),
              ),
            );
          },
        );

        // Prepare for file upload
        final userEmail =
            // ignore: use_build_context_synchronously
            Provider.of<UserProvider>(context, listen: false).email;
        var request = http.MultipartRequest(
            'POST',
            Uri.parse(
                'https://dietbuddyresearchproject.onrender.com/predictFromImage?userEmail=$userEmail&mealType=$mealType'));
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
          // ignore: use_build_context_synchronously
          Navigator.pop(context); // Close the processing dialog
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MealOptionsPage(),
            ),
          );
        } else {
          // Handle error
          // ignore: use_build_context_synchronously
          Navigator.pop(context); // Close the processing dialog
          if (kDebugMode) {
            print('Failed to upload image and get response');
          }
        }
      }
    }
  }

  Future<double> fetchSuggestedCaloriesLimit() async {
    final profileUrl = Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/user_profile?email_id=${Provider.of<UserProvider>(context, listen: false).email}');
    // final profileUrl = Uri.parse(
    //     'http://127.0.0.1:5000/user_profile?email_id=${Provider.of<UserProvider>(context, listen: false).email}');
    final profileResponse = await http.get(profileUrl);
    if (profileResponse.statusCode == 200) {
      final profileData = json.decode(profileResponse.body);
      return profileData['suggested_calories'];
    } else {
      throw Exception('Failed to load suggested calories limit');
    }
  }

  Future<void> fetchItems(String category) async {
    final response = await http.get(Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/food_items_by_category/$category'));
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
      endpoint = 'https://dietbuddyresearchproject.onrender.com/predictdrink';
      // endpoint = 'http://127.0.0.1:5000/predictdrink';
    } else {
      // Use weight field instead
      dataToSend = {
        'FoodItem': selectedItem,
        'selectedCategory': selectedCategory,
        'per100grams': per100gramsInput,
      };
      endpoint =
          'https://dietbuddyresearchproject.onrender.com/predictNonDrink';
      // endpoint = 'http://127.0.0.1:5000/predictNonDrink';
    }
    // check for total calories intake per day if exceeds limit show a option to choose from exercise, alternate food, open api chatbot
    final currentDate =
        DateTime.now().toString().split(' ')[0]; // Format: YYYY-MM-DD
    final totalCaloriesUrl = Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/total_calories_by_email_per_day?email_id=$userEmail&date=$currentDate');

    // final totalCaloriesUrl = Uri.parse(
    //     'http://127.0.0.1:5000/total_calories_by_email_per_day?email_id=$userEmail&date=$currentDate');
    final totalCaloriesResponse = await http.get(totalCaloriesUrl);

    if (totalCaloriesResponse.statusCode == 200) {
      final totalCaloriesData = json.decode(totalCaloriesResponse.body);
      final totalCalories = totalCaloriesData['total_calories'];
      // Assuming there's a daily calorie limit set, for example, 2000 calories

      final double dailyCalorieLimit = await fetchSuggestedCaloriesLimit();

      // if (totalCalories > dailyCalorieLimit) {
      if (totalCalories > 200) {
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
      final addMealUrl = Uri.parse(
          'https://dietbuddyresearchproject.onrender.com/add_user_meals');
      // final addMealUrl = Uri.parse('http://127.0.0.1:5000/add_user_meals');
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
      Uri.parse(
          // 'https://dietbuddyresearchproject.onrender.com/suggestExerciseWithTime'),
          'https://dietbuddyresearchproject.onrender.com/suggestExerciseWithDiffModel'),

      // 'http://127.0.0.1:5000/suggestExerciseWithDiffModel'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(
          {'dailyCalorieLimit': dailyCalorieLimit, 'email': userEmailNonNull}),
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
      Uri.parse(
          'https://dietbuddyresearchproject.onrender.com/save_user_exercise_suggestion'),
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
      Uri.parse(
          'https://dietbuddyresearchproject.onrender.com/save_user_alternate_food'),
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
      Uri.parse(
          'https://dietbuddyresearchproject.onrender.com/suggestExercise'),
      // 'http://127.0.0.1:5000/suggestExercise'),
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
          'https://dietbuddyresearchproject.onrender.com/get_alternate_food?dailyCalorieLimit=$dailyCalorieLimit'),
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
        'https://dietbuddyresearchproject.onrender.com/total_calories_by_email_per_day?email_id=$userEmail&date=$currentDate');
    // final totalCaloriesUrl = Uri.parse(
    //     'http://127.0.0.1:5000/total_calories_by_email_per_day?email_id=$userEmail&date=$currentDate');
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChatPage(
                                messageData: null,
                              )),
                    );
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
    final response = await http.get(Uri.parse(
        'https://dietbuddyresearchproject.onrender.com/food_categories'));
    // final response =
    //     await http.get(Uri.parse('http://127.0.0.1:5000/food_categories'));
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
      barrierDismissible:
          true, // Allow dialog to be dismissible for a more user-friendly experience
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    20), // Rounded corners for a softer look
              ),
              title: Text(
                'Add Entry',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800], // Use theme color for consistency
                ),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                      'You can add a new entry manually.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[
                            600], // Soften the text color for a more elegant look
                      ),
                    ),
                    const SizedBox(
                        height: 20), // Add space for better readability
                    Text(
                      'Meal Type: $mealType',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700], // Theme color for emphasis
                      ),
                    ),
                    const SizedBox(height: 10), // Space before dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4), // Added padding to prevent overflow
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Rounded corners for input
                          ),
                        ),
                        value: selectedCategory,
                        isExpanded: true, // Set to true to prevent overflow
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
                    ),
                    const SizedBox(height: 10), // Space between dropdowns
                    if (items.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Item',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Rounded corners for input
                          ),
                        ),
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
                    const SizedBox(height: 10), // Space before input fields
                    if (selectedItem != null &&
                        volumeAndCaffeineCategories
                            .contains(selectedCategory)) ...[
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Volume (ml)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Rounded corners for input
                          ),
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
                      const SizedBox(height: 10), // Space between input fields
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Caffeine (mg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Rounded corners for input
                          ),
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
                        decoration: InputDecoration(
                          labelText: 'Weight (g)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Rounded corners for input
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          per100gramsInput = value;
                          setState(() {
                            per100gramsInput =
                                value; // Ensure this updates per100gramsInput
                          });
                        },
                      ),
                    ],
                    const SizedBox(
                        height: 20), // Space before quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove,
                              color: Colors
                                  .red), // Color for intuitive decrease action
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                              });
                            }
                          },
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors
                                  .green), // Color for intuitive increase action
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors
                          .red, // Use a color that indicates a negative action for clarity
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Dismiss the dialog
                  },
                ),
                TextButton(
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: Colors
                          .green, // Use a color that indicates a positive action for clarity
                    ),
                  ),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Dialog(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              Text("Loading"),
                            ],
                          ),
                        );
                      },
                    );
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
                        // Update the state based on the API response
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
        backgroundColor: Colors.indigo, // Updated color for a professional look
        title: Image.asset(
          'assets/name.png', // Changed asset name for a more academic look
          width: 150, // Adjusted size for a more refined look
          height: 150,
          fit: BoxFit.contain,
        ),
        centerTitle: true, // Centered the title for a more balanced look
      ),
      body: Center(
        // Align to center of the screen
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center content vertically
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.add,
                      label: 'Manually Add',
                      onPressed: _addManualEntry,
                    ),
                    _buildActionButton(
                      icon: Icons.camera_alt,
                      label: 'Scan Image',
                      onPressed: _pickImagePredict,
                    ),
                  ],
                ),
              ),
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

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
