import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flood_data.dart';

class SubmitFloodScreen extends StatefulWidget {
  @override
  State<SubmitFloodScreen> createState() => _SubmitFloodScreenState();
}

class _SubmitFloodScreenState extends State<SubmitFloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _waterLevelController = TextEditingController();

  final CollectionReference floodCollection =
      FirebaseFirestore.instance.collection('flood_data');

  void submitData() async {
    if (_formKey.currentState!.validate()) {
      final data = FloodData(
        location: _locationController.text,
        waterLevel: double.parse(_waterLevelController.text),
      );

      await floodCollection.add(data.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Flood data submitted!")),
      );

      _locationController.clear();
      _waterLevelController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Submit Flood Data")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: "Location"),
                validator: (value) =>
                    value!.isEmpty ? "Enter a location" : null,
              ),
              TextFormField(
                controller: _waterLevelController,
                decoration: InputDecoration(labelText: "Water Level (m)"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Enter water level" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitData,
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
