class CarModel {
  final String id;
  final String name;
  final String connectorType;
  final double batteryCapacity;

  CarModel({
    required this.id,
    required this.name,
    required this.connectorType,
    required this.batteryCapacity,
  });

  /// Generates a consistent document id from a car's display name.
  /// Use this everywhere an id needs to be derived from [name], so the
  /// logic lives in one place instead of being duplicated per call site.
  static String generateId(String name) {
    return name.replaceAll(' ', '_').toLowerCase();
  }

  factory CarModel.fromMap(Map<String, dynamic> map, String id) {
    return CarModel(
      id: id,
      name: map['name'] ?? '',
      connectorType: map['connectorType'] ?? '',
      batteryCapacity: (map['batteryCapacity'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'connectorType': connectorType,
      'batteryCapacity': batteryCapacity,
    };
  }

  @override
  String toString() {
    return 'CarModel(id: $id, name: $name, connector: $connectorType, battery: ${batteryCapacity}kWh)';
  }
}
