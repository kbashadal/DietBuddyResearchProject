import 'package:dietbuddy/basic_info_page.dart';
import 'package:dietbuddy/login_page.dart';
import 'package:flutter/material.dart';

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
        backgroundColor: Colors.indigo, // Updated color for a professional look
        title: Image.asset(
          'assets/name.png',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
      body: Center(
        child: Container(
          // Added Container widget for background color
          color: Colors.blue[50], // Set light green background color
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                  'assets/logo.png'), // Added to display the logo from assets
              const SizedBox(
                  height: 0), // Added for spacing between logo and text
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
                        builder: (context) => const BasicInfoPage()),
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
      ),
    );
  }
}
