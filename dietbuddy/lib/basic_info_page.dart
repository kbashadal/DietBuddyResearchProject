import 'package:dietbuddy/demographic_page.dart';
import 'package:flutter/material.dart';

class BasicInfoPage extends StatefulWidget {
  const BasicInfoPage({super.key});

  @override
  BasicInfoPageState createState() => BasicInfoPageState();
}

class BasicInfoPageState extends State<BasicInfoPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: Icon(icon),
        fillColor: Colors.white,
        filled: true,
      ),
      obscureText: isPassword,
      keyboardType:
          isPassword ? TextInputType.text : TextInputType.emailAddress,
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildTextInputField(
          controller: _fullNameController,
          label: 'Full Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 10),
        _buildTextInputField(
          controller: _emailController,
          label: 'Email ID',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 10),
        _buildTextInputField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 10),
        _buildTextInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_reset,
          isPassword: true,
        ),
      ],
    );
  }

  void _onNextButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DemographicPage(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: Image.asset(
          'assets/name.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.blue[50],
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Basic Info',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(
                  thickness: 2, indent: 20, endIndent: 20, color: Colors.grey),
              Card(
                color: Colors.transparent,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildInfoSection(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onNextButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}