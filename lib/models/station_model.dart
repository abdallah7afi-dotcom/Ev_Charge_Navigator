import 'package:cloud_firestore/cloud_firestore.dart';

class StationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String connectorType;
  final double power;
  final String fee;
  final double rating;
  final String status; // Available, Occupied, Maintenance, Offline
  final double pricePerKwh; // Price in SAR/kWh
  final String provider;
  final bool isSeed; // true if auto-seeded test station
  final bool isVisibleToCustomer; // false for internal seed stations

  StationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.connectorType,
    required this.power,
    required this.fee,
    required this.rating,
    this.status = 'Available',
    this.pricePerKwh = 1.20,
    this.provider = 'EVIQ',
    this.isSeed = false,
    this.isVisibleToCustomer = true,
  });

  /// Factory constructor to parse directly from a Firestore DocumentSnapshot
  factory StationModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return StationModel.fromMap(map, doc.id);
  }

  factory StationModel.fromMap(Map<String, dynamic> map, String id) {
    double parsedPrice = 1.20;
    final rawFee = map['fee'] ?? '';
    if (map['pricePerKwh'] != null) {
      parsedPrice = (map['pricePerKwh'] as num).toDouble();
    } else if (rawFee.toString().contains('SAR')) {
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(rawFee.toString());
      if (match != null) {
        parsedPrice = double.tryParse(match.group(1)!) ?? 1.20;
      }
    }

    final isSeedVal = map['isSeed'] ?? false;
    final isVisibleVal = map['isVisibleToCustomer'] ?? (!isSeedVal);

    return StationModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      connectorType: map['connectorType'] ?? '',
      power: (map['power'] ?? 0).toDouble(),
      fee: map['fee'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      status: map['status'] ?? 'Available',
      pricePerKwh: parsedPrice,
      provider: map['provider'] ?? 'EVIQ',
      isSeed: isSeedVal,
      isVisibleToCustomer: isVisibleVal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'connectorType': connectorType,
      'power': power,
      'fee': fee,
      'rating': rating,
      'status': status,
      'pricePerKwh': pricePerKwh,
      'provider': provider,
      'isSeed': isSeed,
      'isVisibleToCustomer': isVisibleToCustomer,
    };
  }

  StationModel copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? connectorType,
    double? power,
    String? fee,
    double? rating,
    String? status,
    double? pricePerKwh,
    String? provider,
    bool? isSeed,
    bool? isVisibleToCustomer,
  }) {
    return StationModel(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      connectorType: connectorType ?? this.connectorType,
      power: power ?? this.power,
      fee: fee ?? this.fee,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      provider: provider ?? this.provider,
      isSeed: isSeed ?? this.isSeed,
      isVisibleToCustomer: isVisibleToCustomer ?? this.isVisibleToCustomer,
    );
  }

  @override
  String toString() {
    return 'StationModel(id: $id, name: $name, isSeed: $isSeed, visible: $isVisibleToCustomer)';
  }
}
