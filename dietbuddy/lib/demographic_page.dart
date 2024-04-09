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
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Demographic Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const Divider(
            thickness: 2, indent: 20, endIndent: 20, color: Colors.grey),
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
      decoration: const InputDecoration(
        labelText: 'Age',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.cake),
        fillColor: Colors.white,
        filled: true,
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
      ],
      onChanged: (newValue) {
        setState(() => _selectedGender = newValue!);
      },
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      controller: _heightController,
      decoration: const InputDecoration(
        labelText: 'Height (cm)',
        suffixIcon: Icon(Icons.straighten),
        border: OutlineInputBorder(),
        fillColor: Colors.white,
        filled: true,
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: const InputDecoration(
        labelText: 'Weight (kg)',
        suffixIcon: Icon(Icons.monitor_weight),
        border: OutlineInputBorder(),
        fillColor: Colors.white,
        filled: true,
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _onNextPressed,
      child: const Text('Next'),
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
        title: _buildAppBar(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: _buildDemographicForm(),
      ),
    );
  }
}
