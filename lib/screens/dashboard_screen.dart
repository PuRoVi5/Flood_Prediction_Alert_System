import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vibration/vibration.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Position? _currentPosition;
  String _selectedWaterLevel = "Ankle High";
  List<FlSpot> _waterLevelData = [];
  List<Marker> _allMarkers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initNotifications();
    _listenToFloodDataRealTime();
    _listenToGlobalReports();
    _getCurrentLocation();
  }

  void _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notificationsPlugin
        .initialize(const InitializationSettings(android: androidSettings));
  }

  void _listenToGlobalReports() {
    _firestore.collection('flood_reports').snapshots().listen((snapshot) {
      List<Marker> markers = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          markers.add(
            Marker(
              point: LatLng(data['latitude'], data['longitude']),
              child: Icon(
                Icons.warning_rounded,
                color: data['waterLevel'] == "Danger Level"
                    ? Colors.red
                    : Colors.orange,
                size: 30,
              ),
            ),
          );
        }
      }
      if (mounted) setState(() => _allMarkers = markers);
    });
  }

  void _listenToFloodDataRealTime() {
    _firestore
        .collection('flood_reports')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      List<FlSpot> spots = [];
      var docs = snapshot.docs.reversed.toList();
      for (int i = 0; i < docs.length; i++) {
        var data = docs[i].data();
        double val = (data['waterLevel'] == "Danger Level")
            ? 4.5
            : (data['waterLevel'] == "Waist High" ? 3.0 : 1.5);
        spots.add(FlSpot(i.toDouble(), val));
      }
      if (mounted) setState(() => _waterLevelData = spots);
    });
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission p = await Geolocator.requestPermission();
    if (p != LocationPermission.denied) {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = pos);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 12.0);
    }
  }

  Widget _buildPredictionAlert() {
    String message = "🟢 Safe: No risk";
    Color bgColor = Colors.green.shade50;
    Color textColor = Colors.green.shade900;

    if (_selectedWaterLevel == "Danger Level") {
      message = "🔴 Danger: Move to safe place";
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
    } else if (_selectedWaterLevel == "Waist High" ||
        _selectedWaterLevel == "Knee High") {
      message = "🟡 Warning: Stay alert";
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(message,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Future<void> _submitReport() async {
    // এখানে পরিবর্তন করা হয়েছে: জিপিএস লোকেশন থাকলেই ডেটা পাঠানো যাবে
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Fetching GPS Location... Please wait.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('flood_reports').add({
        "reporterName": _nameController.text.isEmpty
            ? "Volunteer"
            : _nameController.text.trim(),
        "areaName": _locationController.text.isEmpty
            ? "Current GPS Location"
            : _locationController.text.trim(),
        "waterLevel": _selectedWaterLevel,
        "latitude": _currentPosition!.latitude,
        "longitude": _currentPosition!.longitude,
        "timestamp": FieldValue.serverTimestamp(),
      });
      _locationController.clear();
      _nameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data Submitted Successfully!")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flood Alert Pro"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(text: "Live Map"),
            Tab(text: "Trends"),
            Tab(text: "All Alerts")
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapSection(),
                _buildGraphSection(),
                _buildAlertListSection(),
              ],
            ),
          ),
          _buildActionPanel(),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(23.81, 90.41),
        initialZoom: 12,
      ),
      children: [
        TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
        MarkerLayer(
          markers: [
            ..._allMarkers,
            // আপনার লোকেশনে একটি নীল আইকন দেখাবে
            if (_currentPosition != null)
              Marker(
                point: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                child: const Icon(Icons.location_history,
                    color: Colors.blue, size: 40),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraphSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LineChart(LineChartData(
        minY: 0,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
              spots: _waterLevelData,
              isCurved: true,
              color: Colors.blue,
              barWidth: 4)
        ],
      )),
    );
  }

  Widget _buildAlertListSection() {
    return StreamBuilder(
      stream: _firestore
          .collection('flood_reports')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index].data();
            String area =
                doc.containsKey('areaName') ? doc['areaName'] : "Unknown Area";
            String level =
                doc.containsKey('waterLevel') ? doc['waterLevel'] : "N/A";
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: Icon(Icons.warning,
                    color:
                        level == "Danger Level" ? Colors.red : Colors.orange),
                title: Text("$area - $level"),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))
      ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPredictionAlert(),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: "Your Name (Optional)",
                          isDense: true,
                          border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                          labelText: "Area Name (Optional)",
                          isDense: true,
                          border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedWaterLevel,
            decoration: const InputDecoration(
                isDense: true, border: OutlineInputBorder()),
            items: ["Ankle High", "Knee High", "Waist High", "Danger Level"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _selectedWaterLevel = v!),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SUBMIT FLOOD DATA",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
