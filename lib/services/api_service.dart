import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "http://localhost/your_php_folder/flood_submit.php";

  static Future<String> submitFloodData(String location, int waterLevel) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"location": location, "water_level": waterLevel}),
      );

      final data = jsonDecode(response.body);
      return data["message"] ?? "Unknown response";
    } catch (e) {
      return "Error submitting data: $e";
    }
  }
}
