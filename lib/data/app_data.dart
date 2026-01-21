import '../models/flood_data.dart';

class AppData {
  static List<Map<String, String>> users = [
    {'name': 'Admin', 'email': 'admin@gmail.com', 'password': '123456'},
  ];

  static List<FloodData> floodData = [
    FloodData(location: 'Area A', waterLevel: 20),
    FloodData(location: 'Area B', waterLevel: 35),
    FloodData(location: 'Area C', waterLevel: 15),
    FloodData(location: 'Area D', waterLevel: 50),
  ];
}
