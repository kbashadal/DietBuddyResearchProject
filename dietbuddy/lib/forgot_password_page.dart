import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetEmail() async {
    const url = 'http://127.0.0.1:5000/request_password_reset';
    final email = _emailController.text;

    if (email.isEmpty) {
      // Optionally, show an alert dialog or a snackbar to inform the user to enter their email
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$url?email_id=$email'),
      );

      if (response.statusCode == 200) {
        // Handle success, maybe show a dialog or snackbar to inform the user
      } else {
        // Handle failure, show an error message
      }
    } catch (e) {
      // Handle error, show an error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendResetEmail,
              child: const Text('Send Reset Email'),
            ),
          ],
        ),
      ),
    );
  }
}
