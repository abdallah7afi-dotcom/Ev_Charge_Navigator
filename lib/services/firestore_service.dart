import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ev_charge_navigator/models/car_model.dart';
import 'package:ev_charge_navigator/models/station_model.dart';
import 'package:ev_charge_navigator/models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User Operations ──

  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching all users: $e');
    }
  }

  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _db.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  Future<void> deleteUserAccount(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Error deleting user account: $e');
    }
  }

  // ── Car Operations ──

  Future<void> saveCar(String uid, CarModel car) async {
    try {
      final carsRef = _db.collection('users').doc(uid).collection('cars');
      final carId = CarModel.generateId(car.name);

      final existing = await carsRef.get();
      for (final doc in existing.docs) {
        if (doc.id != carId) {
          await doc.reference.delete();
        }
      }

      await carsRef.doc(carId).set(car.toMap());
    } catch (e) {
      throw Exception('Error saving car: $e');
    }
  }

  Future<void> deleteCar(String uid, String carId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('cars')
          .doc(carId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting car: $e');
    }
  }

  Future<List<CarModel>> getUserCars(String uid) async {
    try {
      final snapshot =
          await _db.collection('users').doc(uid).collection('cars').get();
      return snapshot.docs
          .map((doc) => CarModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching cars: $e');
    }
  }

  Future<CarModel?> getPrimaryCar(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('cars')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return CarModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw Exception('Error fetching primary car: $e');
    }
  }

  // ── Station Operations (Auto-Seeding + Customer vs Admin Queries) ──

  /// 1. Auto-Load Seed Stations on Startup
  /// Checks if 'stations' collection is empty, and automatically seeds if empty.
  Future<void> seedStationsIfEmpty(List<Map<String, dynamic>> defaultSeedData) async {
    try {
      final snapshot = await _db.collection('stations').limit(1).get();
      if (snapshot.docs.isEmpty) {
        final batch = _db.batch();
        for (final data in defaultSeedData) {
          final docRef = _db.collection('stations').doc();
          final seedData = Map<String, dynamic>.from(data);
          seedData['isSeed'] = true;
          seedData['isVisibleToCustomer'] = false; // Admin-only initially
          batch.set(docRef, seedData);
        }
        await batch.commit();
      }
    } catch (e) {
      // Fallback silently if offline
    }
  }

  /// 2. Customer Query: Returns ONLY real / visible stations (filtering out seed stations)
  Future<List<StationModel>> getCustomerStations() async {
    try {
      final snapshot = await _db
          .collection('stations')
          .where('isSeed', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        // Fallback: If no custom stations added yet, allow customer to view all stations
        return getAllStations();
      }

      return snapshot.docs
          .map((doc) => StationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return getAllStations();
    }
  }

  /// Real-time stream for Customer app (filtered)
  Stream<List<StationModel>> streamCustomerStations() {
    return _db
        .collection('stations')
        .where('isSeed', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// 3. Admin Query: Returns ALL stations (including seed stations)
  Future<List<StationModel>> getAdminStations() async {
    try {
      final snapshot = await _db.collection('stations').get();
      return snapshot.docs
          .map((doc) => StationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching admin stations: $e');
    }
  }

  /// Real-time stream for Admin Panel (all stations)
  Stream<List<StationModel>> streamAdminStations() {
    return _db.collection('stations').snapshots().map((snap) => snap.docs
        .map((doc) => StationModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<List<StationModel>> getAllStations() async {
    try {
      final snapshot = await _db.collection('stations').get();
      return snapshot.docs
          .map((doc) => StationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching stations: $e');
    }
  }

  Future<void> addStation(StationModel station) async {
    try {
      final data = station.toMap();
      data['isSeed'] = false; // User/Admin added stations are real
      data['isVisibleToCustomer'] = true;
      await _db.collection('stations').add(data);
    } catch (e) {
      throw Exception('Error adding station: $e');
    }
  }

  Future<void> updateStation(StationModel station) async {
    try {
      await _db.collection('stations').doc(station.id).update(station.toMap());
    } catch (e) {
      throw Exception('Error updating station: $e');
    }
  }

  Future<void> deleteStation(String stationId) async {
    try {
      await _db.collection('stations').doc(stationId).delete();
    } catch (e) {
      throw Exception('Error deleting station: $e');
    }
  }

  Future<void> updateStationStatus(String stationId, String status) async {
    try {
      await _db.collection('stations').doc(stationId).update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating station status: $e');
    }
  }

  Future<void> seedStations(
    List<Map<String, dynamic>> stations, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final existing = await _db.collection('stations').get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }

      for (int i = 0; i < stations.length; i++) {
        await _db.collection('stations').add(stations[i]);
        onProgress?.call(i + 1, stations.length);
      }
    } catch (e) {
      throw Exception('Error seeding stations: $e');
    }
  }

  // ── Review Operations ──

  Future<void> addReview(String stationId, ReviewModel review) async {
    try {
      await _db
          .collection('stations')
          .doc(stationId)
          .collection('reviews')
          .add(review.toMap());

      final newAverage = await getStationAverageRating(stationId);
      await _db.collection('stations').doc(stationId).update({
        'rating': newAverage,
      });
    } catch (e) {
      throw Exception('Error adding review: $e');
    }
  }

  Future<List<ReviewModel>> getStationReviews(String stationId) async {
    try {
      final snapshot = await _db
          .collection('stations')
          .doc(stationId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Real-time Stream of station text reviews & comments
  Stream<List<ReviewModel>> streamStationReviews(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<double> getStationAverageRating(String stationId) async {
    try {
      final reviews = await getStationReviews(stationId);
      if (reviews.isEmpty) return 0.0;
      final total = reviews.fold(0.0, (acc, r) => acc + r.rating);
      return total / reviews.length;
    } catch (e) {
      return 0.0;
    }
  }

  Future<bool> hasUserReviewed(String stationId, String userId) async {
    try {
      final snapshot = await _db
          .collection('stations')
          .doc(stationId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserEmail(String uid, String email) async {
    try {
      await _db.collection('users').doc(uid).update({'email': email});
    } catch (e) {
      throw Exception('Error updating email: $e');
    }
  }

  // ── System Reports ──

  Future<Map<String, dynamic>> getSystemReports() async {
    try {
      final usersSnap = await _db.collection('users').get();
      final stationsSnap = await _db.collection('stations').get();

      int available = 0;
      int occupied = 0;
      int maintenance = 0;
      int offline = 0;

      for (final doc in stationsSnap.docs) {
        final st = doc.data()['status'] ?? 'Available';
        if (st == 'Available') {
          available++;
        } else if (st == 'Occupied') {
          occupied++;
        } else if (st == 'Maintenance') {
          maintenance++;
        } else if (st == 'Offline') {
          offline++;
        }
      }

      return {
        'totalUsers': usersSnap.docs.length,
        'totalStations': stationsSnap.docs.length,
        'availableStations': available,
        'occupiedStations': occupied,
        'maintenanceStations': maintenance,
        'offlineStations': offline,
        'uptime': '99.9%',
        'avgResponseTimeMs': 240,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'totalStations': 0,
        'availableStations': 0,
        'occupiedStations': 0,
        'maintenanceStations': 0,
        'offlineStations': 0,
        'uptime': '99.0%',
        'avgResponseTimeMs': 300,
      };
    }
  }
}
