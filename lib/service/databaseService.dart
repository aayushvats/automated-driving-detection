import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/trip.dart';


class DatabaseService{
  DatabaseService._privateConstructor();
  static final DatabaseService instance =
  DatabaseService._privateConstructor();

  Database? _db;

  Future<Database?> get database async {
    if (_db != null) return _db;
    _db = await initializeDatabase();
    return _db;
  }

  Future<Database?> initializeDatabase() async {
    //colors = UIResources.statusColors;
    print("initialize db");
    try {
      final exists = await databaseExists("telematics.db");
      if (!exists) {
        final databasesPath = await getDatabasesPath();
        final path = join(databasesPath, "telematics.db");

        _db = await openDatabase(path, version: 1,
            onCreate: (Database db, int version) async {
              print("CREATE DATABASE: SUCCESS");
              await _createTables(db);
              await _setBooleanPreference("databaseExists", true);
            });
        return _db;
      } else {
        print("CREATE DATABASE: ALREADY PRESENT");
        await _callDB();
      }
    } catch (e) {
      print("Error in initializing database: $e");
    }
  }

  Future<void> _callDB() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, "telematics.db");
      _db = await openDatabase(path);
      print("Are we open yet (Callback based)? ${_db != null ? 'Yes' : 'No'}");
      print("oooooooo $_db");
    } catch (e) {
      print("Error calling databse: $e");
    }
  }

  Future<void> _createTables(Database db) async {
    try {

      await db.execute(
          '''CREATE TABLE IF NOT EXISTS Trips (
            tripDate DATETIME PRIMARY KEY NOT NULL,
            duration INTEGER NOT NULL,
            trip TEXT NOT NULL,
            badRssi TEXT,
            noRssi TEXT,
            points INTEGER,
            distance REAL NOT NULL,
            speed REAL NOT NULL,
            MacAddress TEXT NOT NULL,
            BeaconBatteryStart REAL,
            BeaconBatteryEnd REAL,
            DeviceBatteryStart REAL,
            DeviceBatteryEnd REAL,
            TripStatus INTEGER NOT NULL,
            TripStopReason INTEGER NOT NULL,
            RssiCoverage REAL NOT NULL
            )''');

      print("CREATE TABLE SUCCESS: trips");


    } catch (e) {
      print("Error occurred: $e");
    }
  }

  Future<void> insertTripOLD(Trip_OLD trip) async {
    String query =
        "INSERT INTO Trips (tripDate, duration, trip, points, distance, speed) VALUES (?,?,?,?,?,?)";
    try {
      print("trip time in database insert::::::::::::::${trip.time.inMinutes}");

      Database db = await openDatabase('telematics.db');
      int? rowsAffected = await db?.rawInsert(query, [
        trip.date.toIso8601String(),
        trip.time.inMinutes,
        trip.tripPath,
        trip.points,
        trip.distance,
        trip.speed
      ]);
      print("INSERT trip $rowsAffected FOR ${trip.date}");
    } catch (error) {
      print("INSERT trip ERROR $error");
    }
  }

  Future<void> insertTrip(Trip trip) async {
    print('triptobesaved ${trip.toString()}');
    String badRssi = jsonEncode(trip.badRssi?.map((map) {
      return map.map((key, value) => MapEntry(key.toIso8601String(), value.toIso8601String()));
    }).toList());
    String noRssi = jsonEncode(trip.noRssi?.map((map) {
      return map.map((key, value) => MapEntry(key.toIso8601String(), value.toIso8601String()));
    }).toList());
    try {
      String query =
          "INSERT INTO Trips (tripDate, duration, trip, badRssi, noRssi, points, distance, speed, macAddress, beaconBatteryStart, beaconBatteryEnd, deviceBatteryStart, deviceBatteryEnd, RssiCoverage, TripStopReason, tripStatus) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      print("trip time in database insert::::::::::::::${trip.time.inMinutes}");

      Database db = await openDatabase('telematics.db');
      int? rowsAffected = await db?.rawInsert(query, [
        trip.date.toIso8601String(),
        trip.time.inMilliseconds,
        trip.tripPath,
        badRssi,
        noRssi,
        trip.points,
        trip.distance,
        trip.speed,
        trip.macAddress,
        trip.beaconBatteryStart,
        trip.beaconBatteryEnd,
        trip.deviceBatteryStart,
        trip.deviceBatteryEnd,
        trip.rssiCoverage,
        trip.tripStopReason,
        trip.tripStatus
      ]);
      print("INSERT trip $rowsAffected FOR ${trip.date}");
    } catch (error) {
      print("INSERT trip ERROR $error");
    }
  }

  Future<List<Trip_OLD>> getTripsOLD() async{
    String query = "Select * from Trips";
    List<Trip_OLD> trips = [];
    try{
      Database db = await openDatabase('telematics.db');
      List<Map<String, dynamic>> result =
      await db.rawQuery(query);
      for (int i = result.length - 1 ;i >= 0; --i) {
        var element = result[i];
        final file = File(element["trip"]);
        List<Position> positions = [];
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          final jsonList = json.decode(jsonString) as List<dynamic>;
          positions = jsonList.map((json) => Position.fromMap(json)).toList();
        }
        Trip_OLD trip = Trip_OLD(date: DateTime.parse(element["tripDate"]),
            distance: element["distance"],
            points: element["points"],
            time: Duration(minutes: element["duration"]),
            speed: element["speed"],
            trip: positions,
          // beaconID: element['beaconId'],
          // beaconBatteryStart: element['']
        );

        print("trip time in database get trip::::::::::::::${trip.time.inMinutes}");

        trips.add(trip);
      }
      return trips;
    }
    catch (error) {
      print("SELECT trips ERROR $error");
      rethrow;
    }
  }

  Future<List<Trip>> getTrips() async{
    String query = "Select * from Trips";
    List<Trip> trips = [];
    try{
      Database db = await openDatabase('telematics.db');
      List<Map<String, dynamic>> result =
      await db.rawQuery(query);
      for (int i = result.length - 1 ;i >= 0; --i) {
        var element = result[i];
        print('element -> ${element}');
        final file = File(element["trip"]);
        List<Position> positions = [];
        List<Position> positions_raw = [];
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          print('jsonString --> $jsonString');
          // Map<String, String> map = Map<String, String>.from(json.decode(jsonString));
          // final jsonList = json.decode(map['trip']!) as List<dynamic>;
          // positions = jsonList.map((json) => Position.fromMap(json)).toList();
          Map<String, dynamic> map = json.decode(jsonString);

          final jsonList = map['trip'] as List<dynamic>;
          positions = jsonList.map((json) => Position.fromMap(json as Map<String, dynamic>)).toList();

          final jsonList_raw = map['trip_raw'] as List<dynamic>;
          positions_raw = jsonList_raw.map((json) => Position.fromMap(json as Map<String, dynamic>)).toList();

          print('positions --> $positions');
          // print('positions --> ${positions[i]}');

        }

        List<Map<DateTime, DateTime>> badRssiList = (jsonDecode(element['badRssi']) as List)
            .map((map) => (map as Map<String, dynamic>)
            .map((key, value) => MapEntry(DateTime.parse(key), DateTime.parse(value))))
            .toList();
        print('badRSSI -> ${badRssiList.toString()}');
        List<Map<DateTime, DateTime>> noRssiList = (jsonDecode(element['noRssi']) as List)
            .map((map) => (map as Map<String, dynamic>)
            .map((key, value) => MapEntry(DateTime.parse(key), DateTime.parse(value))))
            .toList();
        // print('badRSSI -> ${badRssiList.toString()}');

        Trip trip = Trip(date: DateTime.parse(element["tripDate"]),
            distance: element["distance"],
            points: element["points"],
            time: Duration(milliseconds: element["duration"]),
            speed: element["speed"],
            tripPath: element["trip"],
            trip: positions,
            trip_raw: positions_raw,
          badRssi: badRssiList??[],
          noRssi: noRssiList??[],
          macAddress: element["MacAddress"],
          beaconBatteryStart: element['BeaconBatteryStart'].toInt(),
          beaconBatteryEnd: element['BeaconBatteryEnd'].toInt(),
          deviceBatteryStart: element['DeviceBatteryStart'].toInt(),
          deviceBatteryEnd: element['DeviceBatteryEnd'].toInt(),
          rssiCoverage: element["RssiCoverage"],
          tripStatus: element["TripStatus"]==1,
          tripStopReason: element["TripStopReason"],
        );

        print("trip time in database get trip::::::::::::::${trip.time.inMinutes}");

        trips.add(trip);
      }
      return trips;
    }
    catch (error) {
      print("SELECT trips ERROR $error");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBeaconMileage(String macAddress) async{
    try {
      String query =
          "SELECT SUM(distance) AS LifetimeMileage FROM Trips WHERE MacAddress = ?";
      Database db = await openDatabase('telematics.db');
      List<Map<String, dynamic>> lifeTimeMileage = await db.rawQuery(query,[macAddress]);
      query = "SELECT SUM(distance) AS ValidMileage FROM Trips WHERE MacAddress = ? and tripStatus = 1";
      List<Map<String, dynamic>> validMileage = await db.rawQuery(query,[macAddress]);
      return {
        "beaconLifetimeMileage" : lifeTimeMileage[0]["LifetimeMileage"] ?? 0.0,
        "validMileage" : validMileage[0]["ValidMileage"] ?? 0.0,
        "invalidMileage" : (lifeTimeMileage[0]["LifetimeMileage"] ?? 0.0) - (validMileage[0]["ValidMileage"] ?? 0.0),
      };
    } catch (error) {
      print("GET trip mileage ERROR $error");
      throw {};
    }
  }

  void closeDatabase() async {
    try {
      final db = await openDatabase('telematics.db');
      db.close();
    } catch (e) {
      print("An Error occurred closing database: $e");
    }
  }

  Future<void> _setBooleanPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}