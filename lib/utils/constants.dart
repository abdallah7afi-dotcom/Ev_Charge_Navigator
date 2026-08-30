class AppConstants {
  static const String mapboxToken =
      'pk.eyJ1IjoiYWJkdWxsYWhhbGhhZmkiLCJhIjoiY21xZjhmM3c5MTd4aTJxcjhybDVyMm5pZCJ9.0XvUaLpVwGnbNmbzjEwIzA';
  static const String osrmBaseUrl = 'https://router.project-osrm.org';
  static const double defaultLat = 24.7136;
  static const double defaultLng = 46.6753;
  static const double arrivalThreshold = 0.05; // 50 meters in km
  static const double consumptionKWhPer100km = 15.0; // Average EV consumption
}

class EVCarDatabase {
  static List<Map<String, dynamic>> get cars => [
        // Tesla
        {'name': 'Tesla Model 3', 'connectorType': 'CCS2', 'batteryCapacity': 60.0},
        {'name': 'Tesla Model 3 Long Range', 'connectorType': 'CCS2', 'batteryCapacity': 75.0},
        {'name': 'Tesla Model Y', 'connectorType': 'CCS2', 'batteryCapacity': 75.0},
        {'name': 'Tesla Model Y Long Range', 'connectorType': 'CCS2', 'batteryCapacity': 81.0},
        {'name': 'Tesla Model S', 'connectorType': 'CCS2', 'batteryCapacity': 100.0},
        {'name': 'Tesla Model X', 'connectorType': 'CCS2', 'batteryCapacity': 100.0},
        {'name': 'Tesla Cybertruck', 'connectorType': 'CCS2', 'batteryCapacity': 123.0},

        // BYD
        {'name': 'BYD Seal', 'connectorType': 'CCS2', 'batteryCapacity': 82.5},
        {'name': 'BYD Seal U', 'connectorType': 'CCS2', 'batteryCapacity': 87.0},
        {'name': 'BYD Song Plus EV', 'connectorType': 'CCS2', 'batteryCapacity': 71.8},
        {'name': 'BYD Song Plus DMi', 'connectorType': 'CCS2', 'batteryCapacity': 18.3},
        {'name': 'BYD Song L', 'connectorType': 'CCS2', 'batteryCapacity': 71.8},
        {'name': 'BYD Atto 3', 'connectorType': 'CCS2', 'batteryCapacity': 60.5},
        {'name': 'BYD Han EV', 'connectorType': 'CCS2', 'batteryCapacity': 85.4},
        {'name': 'BYD Dolphin', 'connectorType': 'CCS2', 'batteryCapacity': 60.4},
        {'name': 'BYD Dolphin Mini', 'connectorType': 'CCS2', 'batteryCapacity': 38.0},
        {'name': 'BYD Tang EV', 'connectorType': 'CCS2', 'batteryCapacity': 86.4},
        {'name': 'BYD Yuan Plus', 'connectorType': 'CCS2', 'batteryCapacity': 60.5},
        {'name': 'BYD Denza D9 EV', 'connectorType': 'CCS2', 'batteryCapacity': 103.0},

        // BMW
        {'name': 'BMW iX xDrive40', 'connectorType': 'CCS2', 'batteryCapacity': 76.6},
        {'name': 'BMW iX xDrive50', 'connectorType': 'CCS2', 'batteryCapacity': 111.5},
        {'name': 'BMW i4 eDrive40', 'connectorType': 'CCS2', 'batteryCapacity': 83.9},
        {'name': 'BMW i5 eDrive40', 'connectorType': 'CCS2', 'batteryCapacity': 81.2},
        {'name': 'BMW i7 xDrive60', 'connectorType': 'CCS2', 'batteryCapacity': 101.7},
        {'name': 'BMW iX1', 'connectorType': 'CCS2', 'batteryCapacity': 64.7},
        {'name': 'BMW iX2', 'connectorType': 'CCS2', 'batteryCapacity': 64.7},

        // Mercedes
        {'name': 'Mercedes EQS 450+', 'connectorType': 'CCS2', 'batteryCapacity': 107.8},
        {'name': 'Mercedes EQS SUV', 'connectorType': 'CCS2', 'batteryCapacity': 107.8},
        {'name': 'Mercedes EQE 350+', 'connectorType': 'CCS2', 'batteryCapacity': 90.6},
        {'name': 'Mercedes EQE SUV', 'connectorType': 'CCS2', 'batteryCapacity': 90.6},
        {'name': 'Mercedes EQB 250+', 'connectorType': 'CCS2', 'batteryCapacity': 66.5},
        {'name': 'Mercedes EQA 250+', 'connectorType': 'CCS2', 'batteryCapacity': 66.5},

        // Lucid
        {'name': 'Lucid Air Pure', 'connectorType': 'CCS2', 'batteryCapacity': 88.0},
        {'name': 'Lucid Air Touring', 'connectorType': 'CCS2', 'batteryCapacity': 112.0},
        {'name': 'Lucid Air Grand Touring', 'connectorType': 'CCS2', 'batteryCapacity': 112.0},
        {'name': 'Lucid Gravity', 'connectorType': 'CCS2', 'batteryCapacity': 113.0},

        // Audi
        {'name': 'Audi e-tron GT', 'connectorType': 'CCS2', 'batteryCapacity': 93.4},
        {'name': 'Audi Q8 e-tron', 'connectorType': 'CCS2', 'batteryCapacity': 114.0},
        {'name': 'Audi Q4 e-tron', 'connectorType': 'CCS2', 'batteryCapacity': 82.0},
        {'name': 'Audi Q6 e-tron', 'connectorType': 'CCS2', 'batteryCapacity': 100.0},

        // Porsche
        {'name': 'Porsche Taycan', 'connectorType': 'CCS2', 'batteryCapacity': 93.4},
        {'name': 'Porsche Taycan Cross Turismo', 'connectorType': 'CCS2', 'batteryCapacity': 93.4},
        {'name': 'Porsche Macan Electric', 'connectorType': 'CCS2', 'batteryCapacity': 100.0},

        // Hyundai / Kia / Genesis
        {'name': 'Hyundai Ioniq 5', 'connectorType': 'CCS2', 'batteryCapacity': 77.4},
        {'name': 'Hyundai Ioniq 6', 'connectorType': 'CCS2', 'batteryCapacity': 77.4},
        {'name': 'Hyundai Kona Electric', 'connectorType': 'CCS2', 'batteryCapacity': 64.8},
        {'name': 'Kia EV6', 'connectorType': 'CCS2', 'batteryCapacity': 77.4},
        {'name': 'Kia EV9', 'connectorType': 'CCS2', 'batteryCapacity': 99.8},
        {'name': 'Genesis GV60', 'connectorType': 'CCS2', 'batteryCapacity': 77.4},
        {'name': 'Genesis GV70 Electrified', 'connectorType': 'CCS2', 'batteryCapacity': 77.4},
        {'name': 'Genesis G80 Electrified', 'connectorType': 'CCS2', 'batteryCapacity': 87.2},

        // Zeekr
        {'name': 'Zeekr 001', 'connectorType': 'CCS2', 'batteryCapacity': 100.0},
        {'name': 'Zeekr X', 'connectorType': 'CCS2', 'batteryCapacity': 66.0},
        {'name': 'Zeekr 009', 'connectorType': 'CCS2', 'batteryCapacity': 116.0},
        {'name': 'Zeekr 007', 'connectorType': 'CCS2', 'batteryCapacity': 75.0},

        // Changan
        {'name': 'Changan Deepal S07 EV', 'connectorType': 'CCS2', 'batteryCapacity': 79.9},
        {'name': 'Changan Deepal L07 EV', 'connectorType': 'CCS2', 'batteryCapacity': 79.9},

        // Geely
        {'name': 'Geely Geometry C', 'connectorType': 'CCS2', 'batteryCapacity': 70.0},

        // Polestar
        {'name': 'Polestar 2', 'connectorType': 'CCS2', 'batteryCapacity': 78.0},
        {'name': 'Polestar 3', 'connectorType': 'CCS2', 'batteryCapacity': 111.0},
        {'name': 'Polestar 4', 'connectorType': 'CCS2', 'batteryCapacity': 100.0},

        // CUPRA
        {'name': 'CUPRA Born', 'connectorType': 'CCS2', 'batteryCapacity': 77.0},
        {'name': 'CUPRA Tavascan', 'connectorType': 'CCS2', 'batteryCapacity': 77.0},

        // Volkswagen
        {'name': 'Volkswagen ID.4', 'connectorType': 'CCS2', 'batteryCapacity': 82.0},
        {'name': 'Volkswagen ID.6', 'connectorType': 'CCS2', 'batteryCapacity': 84.8},

        // Xiaomi
        {'name': 'Xiaomi SU7', 'connectorType': 'CCS2', 'batteryCapacity': 73.6},
        {'name': 'Xiaomi SU7 Max', 'connectorType': 'CCS2', 'batteryCapacity': 101.0},

        // Others
        {'name': 'Rivian R1S', 'connectorType': 'CCS2', 'batteryCapacity': 135.0},
        {'name': 'Rivian R1T', 'connectorType': 'CCS2', 'batteryCapacity': 135.0},
        {'name': 'Cadillac Lyriq', 'connectorType': 'CCS2', 'batteryCapacity': 102.0},
        {'name': 'Lexus RZ 450e', 'connectorType': 'CCS2', 'batteryCapacity': 71.4},
        {'name': 'Toyota bZ4X', 'connectorType': 'CCS2', 'batteryCapacity': 71.4},
        {'name': 'Jaguar I-PACE', 'connectorType': 'CCS2', 'batteryCapacity': 90.0},
        {'name': 'Volvo EX30', 'connectorType': 'CCS2', 'batteryCapacity': 69.0},
        {'name': 'Volvo EX90', 'connectorType': 'CCS2', 'batteryCapacity': 111.0},
        {'name': 'Nissan Ariya', 'connectorType': 'CCS2', 'batteryCapacity': 87.0},
        {'name': 'Nissan Leaf', 'connectorType': 'CHAdeMO', 'batteryCapacity': 40.0},
        {'name': 'MG4 Electric', 'connectorType': 'CCS2', 'batteryCapacity': 64.0},
        {'name': 'MG ZS EV', 'connectorType': 'CCS2', 'batteryCapacity': 50.3},
        {'name': 'GMC Hummer EV', 'connectorType': 'CCS2', 'batteryCapacity': 212.7},
      ];
}
