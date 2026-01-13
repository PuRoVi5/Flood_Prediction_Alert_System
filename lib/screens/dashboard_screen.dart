import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _rainfallController = TextEditingController();
  final TextEditingController _waterLevelController = TextEditingController();

  // ১. ডাটা সাবমিট ফাংশন (UC3: Submit Flood Data)
  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('flood_data').add({
          'location': _locationController.text.trim(),
          'rainfall': double.parse(_rainfallController.text),
          'waterLevel': double.parse(_waterLevelController.text),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Pending',
          'userEmail': FirebaseAuth.instance.currentUser?.email,
        });

        _locationController.clear();
        _rainfallController.clear();
        _waterLevelController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Submitted! Wait for Admin Approval."),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error submitting data")));
      }
    }
  }

  // ২. এডমিন এপ্রুভাল (UC7: Validate Data)
  Future<void> _approveData(String docId) async {
    await FirebaseFirestore.instance
        .collection('flood_data')
        .doc(docId)
        .update({
      'status': 'Approved',
    });
  }

  // ৩. লগআউট ফাংশন
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Flood Alert System"),
          backgroundColor: const Color(0xFF001F3F),
          actions: [
            // AppBar এ লগআউট বাটন
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.add_location), text: "Submit"),
              Tab(icon: Icon(Icons.security), text: "Admin"),
              Tab(icon: Icon(Icons.show_chart), text: "Trends"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSubmitTab(),
            _buildAdminTab(),
            _buildGraphTab(),
          ],
        ),
      ),
    );
  }

  // --- ট্যাব ১: ডাটা সাবমিট (DataInputActivity) ---
  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text("User Submission Form",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                    labelText: "Location", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextFormField(
                controller: _rainfallController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Rainfall (mm)", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextFormField(
                controller: _waterLevelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Water Level (m)",
                    border: OutlineInputBorder())),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text("Send for Validation",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- ট্যাব ২: এডমিন প্যানেল (AdminDashboardActivity) ---
  Widget _buildAdminTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('flood_data')
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No Pending Submissions"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index];
            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text("${data['location']} - ${data['waterLevel']}m"),
                subtitle: Text("Rainfall: ${data['rainfall']}mm"),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle,
                      color: Colors.green, size: 30),
                  onPressed: () => _approveData(data.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- ট্যাব ৩: ভিজ্যুয়ালাইজেশন (VisualizationActivity) ---
  Widget _buildGraphTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('flood_data')
          .where('status', isEqualTo: 'Approved')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(
              child: Text("Approve data in Admin tab to see trends"));

        List<FlSpot> spots = [];
        for (int i = 0; i < docs.length; i++) {
          double val = (docs[i]['waterLevel'] as num).toDouble();
          spots.add(FlSpot(i.toDouble(), val));
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text("Water Level Variation Trend",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
