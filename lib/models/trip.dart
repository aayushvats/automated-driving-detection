import 'package:geolocator/geolocator.dart';

class Trip {
  DateTime date;
  double distance;
  int points;
  Duration time;
  double speed;
  List<Position> trip;
  List<Position> trip_raw;
  String? tripPath;
  List<Map<DateTime, DateTime>>? badRssi;
  List<Map<DateTime, DateTime>>? noRssi;
  String macAddress;
  int beaconBatteryStart;
  int beaconBatteryEnd;
  int deviceBatteryStart;
  int deviceBatteryEnd;
  bool tripStatus;
  int tripStopReason;
  double rssiCoverage;
  bool isChecked = false;

  Trip({
    required this.date,
    required this.distance,
    required this.points,
    required this.time,
    required this.speed,
    required this.trip,
    required this.trip_raw,
    this.tripPath,
    this.badRssi,
    this.noRssi,
    required this.macAddress,
    required this.beaconBatteryStart,
    required this.beaconBatteryEnd,
    required this.deviceBatteryStart,
    required this.deviceBatteryEnd,
    this.tripStatus = true,
    this.tripStopReason = 0,
    required this.rssiCoverage,
  });

  factory Trip.fromJSON(Map<String, dynamic> json) {
    return Trip(
      date: DateTime.parse(json['date']),
      distance: json['distance'].toDouble(),
      points: json['points'],
      time: Duration(seconds: json['time']),
      speed: json['speed'],
      trip: json['trip'],
      trip_raw: json['trip_raw'],
      tripPath: json['tripPath'],
      badRssi: json['badRssi'],
      noRssi: json['noRssi'],
      macAddress: json['macAddress'],
      beaconBatteryStart: json['BeaconBatteryStart'],
      beaconBatteryEnd: json['BeaconBatteryEnd'],
      deviceBatteryStart: json['DeviceBatteryStart'],
      deviceBatteryEnd: json['DeviceBatteryEnd'],
      tripStatus: json['TripStatus'],
      tripStopReason: json['TripStopReason'],
      rssiCoverage: json['RssiCoverage'],
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'date': date.toIso8601String(),
      'distance': distance,
      'points': points,
      'time': time.inSeconds,
      'speed': speed,
      'trip': trip,
      'tripPath': tripPath,
      'badRssi': badRssi,
      'noRssi': noRssi,
      'macAddress': macAddress,
      'BeaconBatteryStart': beaconBatteryStart,
      'BeaconBatteryEnd': beaconBatteryEnd,
      'DeviceBatteryStart': deviceBatteryStart,
      'DeviceBatteryEnd': deviceBatteryEnd,
      'TripStatus': tripStatus,
      'TripStopReason': tripStopReason,
      'RssiCoverage': rssiCoverage,
    };
  }
}

class Trip_OLD {
  DateTime date;
  double distance;
  int points;
  Duration time;
  double speed;
  List<Position> trip;
  String? tripPath;
  bool validity;

  Trip_OLD({
    required this.date,
    required this.distance,
    required this.points,
    required this.time,
    required this.speed,
    required this.trip,
    this.tripPath,
    this.validity = true
  });

  factory Trip_OLD.fromJSON(Map<String, dynamic> json) {
    return Trip_OLD(
      date: DateTime.parse(json['date']),
      distance: json['distance'].toDouble(),
      points: json['points'],
      time: Duration(seconds: json['time']),
      speed: json['speed'],
      trip: json['trip'],
      validity: json['validity']
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'date': date.toIso8601String(),
      'distance': distance,
      'points': points,
      'time': time.inSeconds,
      'speed': speed,
      'trip': trip,
      'validity': validity,
    };
  }
}



