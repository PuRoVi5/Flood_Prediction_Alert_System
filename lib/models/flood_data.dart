class FloodData {
  final String location;
  final double waterLevel;

  FloodData({required this.location, required this.waterLevel});

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'water_level': waterLevel,
    };
  }

  factory FloodData.fromMap(Map<String, dynamic> map) {
    return FloodData(
      location: map['location'],
      waterLevel: map['water_level'] + 0.0, // ensure double
    );
  }
}
