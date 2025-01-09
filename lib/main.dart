import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telematic/displayScreens/homepage.dart';
import 'package:telematic/service/backgroundservice.dart';
import 'package:telematic/service/databaseService.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setDouble("rssiThreshold", prefs.getDouble("rssiThreshold") ?? -90);
  await prefs.setDouble("gpsSpeedThreshold", prefs.getDouble("gpsSpeedThreshold") ?? 15); // in km/h
  await prefs.setDouble("gpsContinuousTimeThreshold", prefs.getDouble("gpsContinuousTimeThreshold") ?? 5); // in sec
  await prefs.setDouble("stopGpsThreshold", prefs.getDouble("stopGpsThreshold") ?? 5); //in min
  await prefs.setDouble("stopBeaconThreshold", prefs.getDouble("stopBeaconThreshold") ?? 360); //in min
  await prefs.setDouble("rssiCoverageThreshold", prefs.getDouble("rssiCoverageThreshold") ?? 70); //in %
  await prefs.setDouble("tripDistanceThreshold", prefs.getDouble("tripDistanceThreshold") ?? 0.1); // in km
  await prefs.setDouble("sampleFrequency", prefs.getDouble("sampleFrequency") ?? 1000); // in km
  await prefs.setDouble("stopGpsSpeedThreshold", prefs.getDouble("stopGpsSpeedThreshold") ?? 15); // in km/h
  await prefs.setDouble("beaconSampleFrequencyThreshold", prefs.getDouble("beaconSampleFrequencyThreshold") ?? 4); // in sec
  await prefs.setDouble("beaconOutOfRangeThreshhold", prefs.getDouble("beaconOutOfRangeThreshhold") ?? 15); // in sec
  DatabaseService databaseServices = DatabaseService.instance;
  await databaseServices.initializeDatabase();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  if (prefs.getBool("autoTripRecord")??false){
    await initializeService();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beacon Test',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          surfaceTintColor: Colors.white,
              color: Colors.white,
        )
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}