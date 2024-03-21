import 'package:flutter/material.dart';
import 'package:dietbuddy/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  UserProfilePageState createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>> _profileData;

  @override
  void initState() {
    super.initState();
    _profileData = _fetchUserProfile();
  }

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final response = await http.get(
      Uri.parse('http://localhost:5000/user_profile?email_id=$userEmail'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Profile picture section removed
                      Text('Full Name: ${snapshot.data!['full_name']}',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('Email: ${snapshot.data!['email_id']}',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Date of Birth: ${snapshot.data!['date_of_birth']}',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Height: ${snapshot.data!['height']} m',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Weight: ${snapshot.data!['weight']} kg',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('BMI: ${snapshot.data!['bmi'].toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('BMI Category: ${snapshot.data!['bmi_category']}',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
          }
          // By default, show a loading spinner.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
