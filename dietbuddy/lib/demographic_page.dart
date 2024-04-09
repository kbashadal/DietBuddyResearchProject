import 'package:dietbuddy/select_activity.dart';
import 'package:flutter/material.dart';

class DemographicPage extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;

  const DemographicPage({
    Key? key,
    required this.fullName,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  DemographicPageState createState() => DemographicPageState();
}

class DemographicPageState extends State<DemographicPage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedGender = 'Male';

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.lightBlue.shade50,
      title: Image.asset(
        'assets/name.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
    );
  }

  Widget _buildDemographicForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Demographic Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
          textAlign: TextAlign.center,
        ),
        const Divider(
            thickness: 2, indent: 20, endIndent: 20, color: Colors.deepPurple),
        const SizedBox(height: 10),
        _buildAgeField(),
        const SizedBox(height: 10),
        _buildGenderDropdown(),
        const SizedBox(height: 10),
        _buildHeightField(),
        const SizedBox(height: 10),
        _buildWeightField(),
        const SizedBox(height: 20),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      decoration: InputDecoration(
        labelText: 'Age',
        hintText: 'Enter your age',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.cake),
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlue.shade200, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlue.shade500, width: 2.0),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your age';
        }
        final n = int.tryParse(value);
        if (n == null || n <= 0) {
          return 'Please enter a valid age';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')), // Added option
      ],
      onChanged: (newValue) {
        setState(() => _selectedGender = newValue!);
      },
      decoration: InputDecoration(
        labelText: 'Gender',
        border: const OutlineInputBorder(),
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlue.shade200, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlue.shade500, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      controller: _heightController,
      decoration: InputDecoration(
        labelText: 'Height (cm)',
        hintText: 'Enter your height in cm',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.straighten),
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlue.shade200, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlue.shade500, width: 2.0),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your height';
        }
        final n = double.tryParse(value);
        if (n == null || n <= 0) {
          return 'Please enter a valid height';
        }
        return null;
      },
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: InputDecoration(
        labelText: 'Weight (kg)',
        hintText: 'Enter your weight in kg',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.monitor_weight),
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlue.shade200, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlue.shade500, width: 2.0),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your weight';
        }
        final n = double.tryParse(value);
        if (n == null || n <= 0) {
          return 'Please enter a valid weight';
        }
        return null;
      },
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _onNextPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple, // Button color
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: const Text(
        'Next',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  void _onNextPressed() {
    final int age = int.tryParse(_ageController.text) ?? 0;
    final double height = double.tryParse(_heightController.text) ?? 0.0;
    final double weight = double.tryParse(_weightController.text) ?? 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectActivityPage(
          fullName: widget.fullName,
          email: widget.email,
          password: widget.password,
          age: age,
          gender: _selectedGender,
          height: height,
          weight: weight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo, // Updated color for a professional look
        title: Image.asset(
          'assets/name.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.lightBlue.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildDemographicForm(),
          ),
        ),
      ),
    );
  }
}
