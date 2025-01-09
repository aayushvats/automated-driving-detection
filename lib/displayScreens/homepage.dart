import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telematic/displayScreens/gaugeChart.dart';
import 'package:telematic/displayScreens/testMap.dart';
import 'package:telematic/displayScreens/tripDetails.dart';
import 'package:telematic/displayWidgets/pairBeacon.dart';
import 'package:telematic/widgets/permissionalert.dart';

import 'dart:io' show Directory, File, Platform;

import '../displayWidgets/logicSettings.dart';
import '../models/trip.dart';
import '../service/backgroundservice.dart';
import '../service/databaseService.dart';

MethodChannel channel = MethodChannel('com.example.telematic/minewsdk');

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool autoRecord = true;
  String gpsSignalStrength = "Unknown";
  Map<String, dynamic>? foundBeacon;
  int currentRssi = 0;
  bool isSelected = false;

  final GlobalKey<State> _dialogKey = GlobalKey<State>();

  bool isAboutBeaconExpanded = false;
  int selectedDataSetIndex = -1;
  double angleValue = 0;
  bool relativeAngleMode = true;

  bool _isLoc = false;
  bool _isBlu = false;
  bool _isNot = false;
  bool _isAct = false;
  bool _isBat = false;

  String lat = '';
  String lng = '';
  String acc = '';
  String sp = '';

  TextEditingController macController = TextEditingController();

  int distCheck = 0;
  List<Trip> trips = [];
  double beaconLifeTimeMileage = 0.0;
  double validMileage = 0.0;
  double invalidMileage = 0.0;
  Duration _selectedDuration = Duration(seconds: 1);

  late Timer t;
  // Duration _starterTIme = Duration.zero;
  // Duration _tripTime = Duration.zero;

  String? macAddress;
  bool isPaired = false;

  bool? isBeaconNear;
  bool isVisible = true;
  bool isBluetoothAlertBoxVisible = false;
  bool isSnacbarVisible = false;

  String osPlatform = "";
  String deviceModel = "";
  String deviceManufacture = "";
  String osVersion = "";
  String deviceId = "";
  String appVersion = "v4.4.1";

  FlutterBackgroundService service = FlutterBackgroundService();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getAutoRecordTrip();
      getTrips();
      checkPermissions();
      checkMacAddress();
      checkProximity();
      checkTripStarted();
    });
    super.initState();
  }

  void getAutoRecordTrip() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      autoRecord = prefs.getBool("autoTripRecord") ?? false;
    });
  }

  void getTrips() async {
    // return [
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 1)),
    //     distance: 10.5,
    //     points: 50,
    //     time: Duration(minutes: 30),
    //     speed: 35.0,
    //     trip: [
    //       Position(
    //         longitude: 77.2137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip1",
    //     macAddress: "00:11:22:33:44:55",
    //     beaconBatteryStart: 90,
    //     beaconBatteryEnd: 85,
    //     deviceBatteryStart: 95,
    //     deviceBatteryEnd: 90,
    //     tripStatus: true,
    //     rssiCoverage: 70.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 1)),
    //     distance: 10.5,
    //     points: 50,
    //     time: Duration(minutes: 30),
    //     speed: 35.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip1",
    //     macAddress: "00:11:22:33:44:55",
    //     beaconBatteryStart: 90,
    //     beaconBatteryEnd: 85,
    //     deviceBatteryStart: 95,
    //     deviceBatteryEnd: 90,
    //     tripStatus: true,
    //     rssiCoverage: 70.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 1)),
    //     distance: 10.5,
    //     points: 50,
    //     time: Duration(minutes: 30),
    //     speed: 35.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip1",
    //     macAddress: "00:11:22:33:44:55",
    //     beaconBatteryStart: 90,
    //     beaconBatteryEnd: 85,
    //     deviceBatteryStart: 95,
    //     deviceBatteryEnd: 90,
    //     tripStatus: true,
    //     rssiCoverage: 70.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 1)),
    //     distance: 10.5,
    //     points: 50,
    //     time: Duration(minutes: 30),
    //     speed: 35.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip1",
    //     macAddress: "00:11:22:33:44:55",
    //     beaconBatteryStart: 90,
    //     beaconBatteryEnd: 85,
    //     deviceBatteryStart: 95,
    //     deviceBatteryEnd: 90,
    //     tripStatus: true,
    //     rssiCoverage: 70.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 1)),
    //     distance: 10.5,
    //     points: 50,
    //     time: Duration(minutes: 30),
    //     speed: 35.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip1",
    //     macAddress: "00:11:22:33:44:55",
    //     beaconBatteryStart: 90,
    //     beaconBatteryEnd: 85,
    //     deviceBatteryStart: 95,
    //     deviceBatteryEnd: 90,
    //     tripStatus: true,
    //     rssiCoverage: 70.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 1)),
    //     distance: 10.5,
    //     points: 50,
    //     time: Duration(minutes: 30),
    //     speed: 35.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip1",
    //     macAddress: "00:11:22:33:44:55",
    //     beaconBatteryStart: 90,
    //     beaconBatteryEnd: 85,
    //     deviceBatteryStart: 95,
    //     deviceBatteryEnd: 90,
    //     tripStatus: true,
    //     rssiCoverage: 70.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 2)),
    //     distance: 15.2,
    //     points: 75,
    //     time: Duration(minutes: 45),
    //     speed: 40.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip2",
    //     macAddress: "11:22:33:44:55:66",
    //     beaconBatteryStart: 88,
    //     beaconBatteryEnd: 82,
    //     deviceBatteryStart: 92,
    //     deviceBatteryEnd: 87,
    //     tripStatus: false,
    //     rssiCoverage: 65.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 3)),
    //     distance: 20.7,
    //     points: 100,
    //     time: Duration(hours: 1),
    //     speed: 45.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip3",
    //     macAddress: "22:33:44:55:66:77",
    //     beaconBatteryStart: 85,
    //     beaconBatteryEnd: 80,
    //     deviceBatteryStart: 90,
    //     deviceBatteryEnd: 85,
    //     tripStatus: true,
    //     rssiCoverage: 60.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 4)),
    //     distance: 25.3,
    //     points: 120,
    //     time: Duration(hours: 1, minutes: 15),
    //     speed: 50.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip4",
    //     macAddress: "33:44:55:66:77:88",
    //     beaconBatteryStart: 95,
    //     beaconBatteryEnd: 90,
    //     deviceBatteryStart: 98,
    //     deviceBatteryEnd: 93,
    //     tripStatus: true,
    //     rssiCoverage: 75.0,
    //   ),
    //   Trip(
    //     date: DateTime.now().subtract(Duration(days: 5)),
    //     distance: 30.8,
    //     points: 150,
    //     time: Duration(hours: 1, minutes: 30),
    //     speed: 55.0,
    //     trip: [
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //       Position(
    //         longitude: 77.1137639,
    //         latitude: 28.7344988,
    //         timestamp: DateTime.now().subtract(Duration(minutes: 1)),
    //         accuracy: 9.470999717712402,
    //         altitude: 188.6999969482422,
    //         altitudeAccuracy: 2.0653934478759766,
    //         floor: null,
    //         heading: 195.05654907226562,
    //         headingAccuracy: 45.0,
    //         speed: 0.6571126580238342,
    //         speedAccuracy: 1.5,
    //         isMocked: false,
    //       ),
    //     ],
    //     tripPath: "path/to/trip5",
    //     macAddress: "44:55:66:77:88:99",
    //     beaconBatteryStart: 92,
    //     beaconBatteryEnd: 87,
    //     deviceBatteryStart: 94,
    //     deviceBatteryEnd: 89,
    //     tripStatus: true,
    //     rssiCoverage: 72.0,
    //   ),
    // ];
    DatabaseService databaseService = DatabaseService.instance;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var allTrips = await databaseService.getTrips();
    setState(() {
      trips = allTrips;
    });
    if (macAddress != null) {
      var mileage = await databaseService.getBeaconMileage(macAddress!);
      setState(() {
        beaconLifeTimeMileage = mileage["beaconLifetimeMileage"];
        validMileage = mileage["validMileage"];
        invalidMileage = mileage["invalidMileage"];
      });
    }
    service.on('updateTripList').listen((event) async {
      prefs.setBool('isTripStarted', false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        isSnacbarVisible = false;
      });
      allTrips = await databaseService.getTrips();
      setState(() {
        trips = allTrips;
      });
      var mileage = await databaseService.getBeaconMileage(macAddress!);
      setState(() {
        beaconLifeTimeMileage = mileage["beaconLifetimeMileage"];
        validMileage = mileage["validMileage"];
        invalidMileage = mileage["invalidMileage"];
      });
    });
  }

  getGPSStrength() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    if (position.accuracy > 100) {
      setState(() {
        gpsSignalStrength = "Weak";
      });
    } else {
      setState(() {
        gpsSignalStrength = "Strong";
      });
    }
    service.on('gpsStrengthUpdate').listen((event) {
      event?.forEach((key, value) async {
        if (key == 'strength') {
          setState(() {
            gpsSignalStrength = value;
          });
        }
      });
    });
  }

  getBeaconDetails() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    print("äpp dir path ${appDocPath}");
    File file = File('${appDocPath}/beacons.json');

    if (await file.exists()) {
      String contents = await file.readAsString();
      List<dynamic> beacons = jsonDecode(contents);
      for (var beacon in beacons) {
        String formattedMac = Platform.isIOS
            ? unformatString(macAddress ?? "").toLowerCase()
            : (macAddress ?? "");
        if (macAddress != null && beacon['mac'] == formattedMac) {
          setState(() {
            foundBeacon = beacon;
          });
        }
      }
    }
  }

  // setTripTimer() {
  //   service.on('setTimer').listen((event) {
  //     event?.forEach((key, value) async {
  //       if (key == 'time') {
  //         setState(() {
  //           timer.stop();
  //           isStarted = true;
  //           print('hello vai');
  //           _tripTime = Duration(seconds: value);
  //           timer.reset();
  //           timer.start();
  //         });
  //       }
  //     });
  //   });
  //   service.on('stopTimer').listen((event) {
  //     setState(() {
  //       _tripTime = Duration.zero;
  //       timer.reset();
  //       timer.stop();
  //       isStarted = false;
  //     });
  //   });
  // }
  //
  // checkIsStarted() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   DateTime? durationElapsed =
  //       DateTime.tryParse(prefs.getString('timeStarted') ?? '');
  //   if (durationElapsed != null) {
  //     setState(() {
  //       isStarted = true;
  //       _starterTIme = DateTime.now().difference(durationElapsed);
  //       timer.start();
  //     });
  //   }
  // }

  checkMacAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? temp = await prefs.getString('macAddress');
    if (temp != null) {
      setState(() {
        macAddress = temp;
        isPaired = true;
      });
      getBeaconDetails();
    }
    // call background
    final service = await FlutterBackgroundService();
    service.invoke("SearchMacAddress", {'macAddressKey': macAddress});
  }

  checkProximity() {
    service.on('foundBeacon').listen((event) {
      print('yoloyoloyoloyoloyoloyolo ${event?.keys.toString()}');
      event?.forEach((key, value) async {
        if (key == 'isBeaconNear') {
          setState(() {
            isBeaconNear = value;
            isVisible = !value;
          });
        }
        if (key == 'rssi') {
          print(
              "\n.\n\.n\n.\n.\n.\n.\n.\.\n.yfcgujtctugchyfgvjuyctugyuchggyujvhg ${value}");
          setState(() {
            currentRssi = value;
            print(currentRssi);
          });
        }
      });
    });
  }

  void checkPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // prefs.setBool("autoTripRecord", val);

    if (await Permission.location.isGranted) {
      setState(() {
        _isLoc = true;
      });
    }
    if (Platform.isIOS) {
      if (await Permission.bluetooth.isGranted) {
        setState(() {
          _isBlu = true;
        });
      }
    } else if (Platform.isAndroid) {
      if (await Permission.bluetoothScan.isGranted) {
        setState(() {
          _isBlu = true;
        });
      }else{
        setState(() {
          _isBlu = false;
        });
        print("permission isn't given");
      }
    }
    if (await Permission.notification.isGranted) {
      setState(() {
        _isNot = true;
      });
    }
    if (await prefs.getBool("isHibernationDisabled") ?? false) {
      setState(() {
        _isAct = true;
      });
    }
    if (await prefs.getBool("isBatteryDisabled") ?? false) {
      setState(() {
        _isBat = true;
      });
    }
    // print(_isLoc && _isBlu && _isNot);
    if (!(_isLoc && _isBlu && _isNot && _isAct && _isBat)) {
      await prefs.setBool('isPermissionGranted', false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PermissionAlert(
            isLoc: _isLoc,
            isBlu: _isBlu,
            isNot: _isNot,
            isAct: _isAct,
            isBat: _isBat,
            onPermissionsGiven: (val) async{
              await prefs.setBool('isPermissionGranted', val);
              if (val)  {
                if(await Permission.bluetoothScan.isGranted){
                  checkBluetoothOn();
                }
                // channel.setMethodCallHandler(_handleMethodCall);
              }
            },
          );
        },
      );
    }
    else {
      // service.invoke('permissionsGranted');
      print('despaaacito');
      if(await Permission.bluetoothScan.isGranted){
        checkBluetoothOn();
      }
      // channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  checkBluetoothOn(){
    final bluetoothInstance = FlutterBluePlus.adapterState;
    print('in check bluetooth');
    bluetoothInstance.listen((state) async{
      if (state == BluetoothAdapterState.on ) {
        // Bluetooth is on
        print("bluetooth is onnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn");
        if(isBluetoothAlertBoxVisible){
          Navigator.pop(context);
          setState(() {
            isBluetoothAlertBoxVisible=false;
          });
        }
        service.invoke('permissionsGranted');
        channel.invokeMethod('startMinewSDK');
        getGPSStrength();
        checkMacAddress();
        getBeaconDetails();
        //await flutterLocalNotificationsPlugin.cancel(123);
      } else if(state == BluetoothAdapterState.off){
        print("bluetooth is oooooooooooooooooooofffffffffffffffffffffffffffff");
        setState(() {
          isBluetoothAlertBoxVisible = true;
        });
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                key: _dialogKey,
                title: Text('Alert!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_disabled_rounded, size: 40,),
                    Text(
                      'Bluetooth has been turned off. Turn it on if you want to continue using the app.',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    });
  }

  checkTripStarted() async{

    service.on('startTrip').listen((event) async {
      print("trip started.....................................");
      var snackdemo = SnackBar(
        content: Text('Beacon Test is recording a Trip.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18),),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(200),
        ),
        elevation: 10,
        margin: EdgeInsets.all(8),
        behavior: SnackBarBehavior.floating,
        duration: Duration(days: 365),
      );
      if(!isSnacbarVisible){
        ScaffoldMessenger.of(context).showSnackBar(snackdemo);
        setState(() {
          isSnacbarVisible = true;
        });
      }
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getBool("isTripStarted") ?? false){
      var snackdemo = SnackBar(
        content: Text('Beacon Test is recording a Trip.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18),),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(200),
        ),
        elevation: 10,
        margin: EdgeInsets.all(8),
        behavior: SnackBarBehavior.floating,
        duration: Duration(days: 365),
      );
      if(!isSnacbarVisible){
        ScaffoldMessenger.of(context).showSnackBar(snackdemo);
        setState(() {
          isSnacbarVisible = true;
        });      }
    }
  }

  onTapBeacon(Map<String, dynamic> foundBeacon) {
    return AlertDialog(
      content: Container(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/E8.png',
                height: 200,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    (isBeaconNear ?? false)
                        ? Icons.wifi_tethering
                        : Icons.wifi_tethering_off,
                    size: 28,
                    color: (isBeaconNear ?? false) ? Colors.green : Colors.red,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    foundBeacon['name'] ?? 'Unamed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color:
                          (isBeaconNear ?? false) ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              Text(
                "${macAddress}" ?? '',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade700),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.battery_75_percent,
                        size: 18,
                        color: Colors.grey,
                      ),
                      Text(
                        ' Battery : ',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${foundBeacon['battery'].toString()}%' ?? '',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      // SizedBox(width: 20,),
                    ],
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // SizedBox(width: 20,),
                      Icon(
                        Icons.radar_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      Text(
                        ' RSSI : ',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${currentRssi.toString()} ${foundBeacon['rssi'].toString()}' ??
                            '',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      // SizedBox(width: 20,),
                    ],
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // SizedBox(width: 10,),
                      Icon(
                        Icons.av_timer_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      Text(
                        ' Updated : ',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      '${DateFormat("dd MMM `yy HH:mm").format(Platform.isAndroid ? DateTime.fromMillisecondsSinceEpoch(foundBeacon['lastUpdate'].toInt()).toLocal() : DateTime.parse(foundBeacon['lastUpdate']).toLocal())}' ??
                          '',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              Divider(),
              for (dynamic frame in foundBeacon['frames'])
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${frame['type'].toString().toUpperCase()}' ?? '',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        // SizedBox(width: 20,),
                      ],
                    ),
                    Column(
                      children: frame.entries
                          .map((entry) {
                            if (entry.key == 'type') return SizedBox.shrink();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      ' ${entry.key} : ',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Text(
                                    '${entry.value}' ?? '',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                )
                              ],
                            );
                          })
                          .toList()
                          .cast<Widget>(),
                    ),
                    Divider(),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  String formatTime(int milliseconds) {
    // milliseconds += _starterTIme.inMilliseconds;

    int seconds = (milliseconds / 1000).truncate();
    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();

    String hoursStr = (hours % 60).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secondsStr';
  }

  String formatString(String input) {
    if (input.length == 1) {
      return input;
    }

    if ((input.length) % 2 != 0) {
      return "${formatString(input.substring(0, input.length - 1))}:${input.substring(input.length - 1)}";
    }

    List<String> pairs = [];
    for (int i = 0; i < input.length; i += 2) {
      pairs.add(input.substring(i, i + 2));
    }

    String formattedString = pairs.join(':');

    return formattedString;
  }

  String unformatString(String input) {
    String unformattedString = input.replaceAll(':', '');
    return unformattedString;
  }

  Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Directory? downloadsDirectory = await getExternalStorageDirectory();
      // String downloadsPath = downloadsDirectory!.path.split('Android').first + "Download";
      // return Directory('$downloadsPath');
      return await getExternalStorageDirectory();
      
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  Future<void> requestPermission() async {
    if (!await Permission.storage.request().isGranted) {
      // Permission denied, handle accordingly
      print('Storage permission denied');
    }
  }

  getDeviceInfo() async{
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      setState(() {
        osPlatform = "Android";
        deviceModel = androidInfo.model;
        deviceManufacture = androidInfo.brand;
        osVersion = androidInfo.version.release;
        deviceId = androidInfo.id;
      });

    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      setState(() {
        osPlatform = "iOS";
        deviceModel = iosInfo.model;
        deviceManufacture = iosInfo.name;
        osVersion = iosInfo.systemVersion;
        deviceId = iosInfo.identifierForVendor ?? "";
      });
    }

  }

  Future<void> exportTrips() async {
    print("here-_-_-");
    await getDeviceInfo();
    List<Map<String, dynamic>> allTripsJson = [];
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      print("Could not get the downloads directory");
      return;
    }
    List<XFile> allFiles = [];
    try {
      for (int i = 0; i < trips.length; i++) {
        if (!trips[i].isChecked) {
          continue;
        }
        Map<String, dynamic> tripJson = {
          "BeaconID": trips[i].macAddress,
          "TripStartDateTime": trips[i].date.toIso8601String().replaceFirst('T', ' '),
          "TripEndDateTime": trips[i].date.add(trips[i].time).toIso8601String().replaceFirst('T', ' '),
          "TotalTime": trips[i].time.inMinutes,
          "OSPlatform": osPlatform,
          "OSVersion": osVersion,
          "DeviceManufacturer": deviceManufacture,
          "DeviceModel": deviceModel,
          "DeviceID": deviceId,
          "AppVersion": appVersion,
          "AverageSpeed": trips[i].speed,
          "TotalDistance": trips[i].distance,
          "BeaconBatteryStart": trips[i].beaconBatteryStart,
          "BeaconBatteryEnd": trips[i].beaconBatteryEnd,
          "DeviceBatteryStart": trips[i].deviceBatteryStart,
          "DeviceBatteryEnd": trips[i].deviceBatteryEnd,
          "TripStatus": trips[i].tripStatus ? "Valid" : "Invalid",
          "RssiCoverage": trips[i].rssiCoverage,
          "BadRssi": trips[i].badRssi?.map((map) => map.map((key, value) => MapEntry(key.toIso8601String().replaceFirst('T', ' '), value.toIso8601String().replaceFirst('T', ' ')))).toList(),
          "NoRssi": trips[i].noRssi?.map((map) => map.map((key, value) => MapEntry(key.toIso8601String().replaceFirst('T', ' '), value.toIso8601String().replaceFirst('T', ' ')))).toList(),
        };
        final file = File(trips[i].tripPath ?? "");
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          Map<String, dynamic> map = json.decode(jsonString);
          tripJson["Rssi"] = map["rssi"] ?? [];
          tripJson["Bad_rssi_data"] = map["badRssiData"] ?? [];
          tripJson["Trip"] = map["trip"] ?? [];
          tripJson["Trip_raw"] = map["trip_raw"] ?? [];

          const double thresholdInterval = 1500.0;
          List<dynamic> trip = map["trip"] ?? [];

          if (trip.isNotEmpty) {
            int goodAccuracyCount = 0;
            for (int i = 1; i < trip.length; i++) {
              if ((trip[i]['timestamp'] - trip[i - 1]['timestamp']).abs() < thresholdInterval) {
                goodAccuracyCount++;
              }
            }

            double gpsCoverage = (goodAccuracyCount / trip.length) * 100;
            tripJson["GPSCoverage"] = gpsCoverage.toStringAsFixed(2); // Save as a string with 2 decimal places
          } else {
            tripJson["GPSCoverage"] = "0.00";
          }

        }
        print('trip $i added to alltrips');
        //allTripsJson.add(tripJson);
        final filePath = '${directory.path}/trip_${trips[i].date.toIso8601String().replaceFirst('T', '_')}.json';
        final tripfile = File(filePath);
        final jsonString = jsonEncode(tripJson);
        await tripfile.writeAsString(jsonString);
        allFiles.add(XFile('${tripfile.path}'));
      }

      // if (await Permission.storage.request().isGranted) {


        // final filePath = '${directory.path}/trip_${DateTime.now().toIso8601String()}.json';
        // final file = File(filePath);
        // final jsonString = jsonEncode(allTripsJson);
        // await file.writeAsString(jsonString);
        // print("File written to $filePath");
      if(allFiles.isNotEmpty) {
        final result = await Share.shareXFiles(
            allFiles, text: 'Check out this file!', subject: 'Trip json');
        if (result.status == ShareResultStatus.success) {
          print('Thank you for sharing the picture!');
        }
        print("XFiles");
      } else {
        // Handle permission denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please Select a Trip to Export.')),
        );
      }

    } catch (e) {
      print("Error writing file: $e");
    }
  }

  @override
  void dispose() {
    // Cancel the subscription to the port\
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // backgroundColor: Color(0xFFF1F1F1),
      backgroundColor: Colors.white,
      appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Beacon Test v4.4.1",
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 25,
                color: Colors.black87),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: () async {
                channel.invokeMethod('startMinewSDK');
                getGPSStrength();
                showDialog(
                  context: context,
                  builder: (context) {
                    return PopScope(
                      canPop: false,
                      child: AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.black,),
                            SizedBox(height: 20),
                            Text(
                              'Refreshing...',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                // Wait for 3 seconds
                await Future.delayed(Duration(seconds: 3));

                // Close the loading dialog
                Navigator.of(context).pop();

                // Show the success dialog
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 50),
                          Text(
                            'App has been refreshed',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    );
                  },
                );

              },
              icon: Icon(CupertinoIcons.refresh),
            ),
          ]
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 12.0, bottom: 6.0, left: 12.0, right: 6.0),
                          child: InkWell(
                            onTap: () {
                              print("pressed on Tap to Pair Beacon");
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return autoRecord
                                        ? PairBeacon(
                                            onPair: (mac) {
                                              setState(() {
                                                foundBeacon = null;
                                                macAddress = mac;
                                              });
                                              getBeaconDetails();
                                              setState(() {
                                                isPaired = true;
                                              });
                                              getTrips();
                                            },
                                          )
                                        : AlertDialog(
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.wifi_tethering_error,
                                                  color: Colors.orange,
                                                  size: 50,
                                                ),
                                                Text(
                                                  'Turn on "Auto Trip Record" to start pairing beacon',
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                              ],
                                            ),
                                          );
                                  });
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black, width: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    color: autoRecord
                                        ? Colors.black87
                                        : Colors.grey),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Tap to Pair Beacon",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 12.0, bottom: 6.0, left: 6.0, right: 12.0),
                          child: InkWell(
                            onTap: () {
                              print("pressed on Logic Setting");
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return LogicSetting();
                                  });
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black, width: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.black87),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Logic Setting",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 6.0),
                        child: Text(
                          "Auto Trip Record :",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0, right: 12.0),
                        child: Switch(
                            value: autoRecord,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.green,
                            inactiveTrackColor: Colors.red,
                            inactiveThumbColor: Colors.white,
                            trackOutlineWidth:
                                MaterialStateProperty.resolveWith((Set states) {
                              return 0; // Use the default width.
                            }),
                            onChanged: (val) async {
                              setState(() {
                                autoRecord = val;
                              });
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              prefs.setBool("autoTripRecord", val);
                              if (val){
                                await initializeService();
                                service.startService();
                                checkPermissions();
                                checkMacAddress();
                                checkProximity();
                                getGPSStrength();
                                getTrips();

                              } else {
                                service.invoke("stopService");
                                prefs.setBool('isTripStarted', false);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                setState(() {
                                  isSnacbarVisible = false;
                                });

                              }
                            }),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 6.0),
                        child: Text(
                          "GPS Signal :",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0, right: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "${gpsSignalStrength} ",
                              style: TextStyle(
                                  color: gpsSignalStrength == "Strong"
                                      ? Colors.green
                                      : gpsSignalStrength == "Weak"
                                          ? Colors.red
                                          : Colors.orange,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                            Icon(
                                gpsSignalStrength == "Strong"
                                    ? Icons.gpp_good_sharp
                                    : gpsSignalStrength == "Weak"
                                        ? Icons.gpp_bad_sharp
                                        : Icons.gpp_maybe_sharp,
                                color: gpsSignalStrength == "Strong"
                                    ? Colors.green
                                    : gpsSignalStrength == "Weak"
                                        ? Colors.red
                                        : Colors.orange)
                          ],
                        ),
                      )
                    ],
                  ),
                  Divider(
                    color: Colors.black,
                    thickness: 0.7,
                    endIndent: 15,
                    indent: 15,
                  ),
                  (isPaired && foundBeacon != null)
                      ? Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          onExpansionChanged: (bool expanded) {
                            setState(() {
                              isAboutBeaconExpanded = expanded;
                            });
                          },
                          visualDensity: VisualDensity(vertical: -4),
                          tilePadding: EdgeInsets.only(right: 10),
                          title:Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20.0, right: 6.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "About Beacon ",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    isAboutBeaconExpanded
                                        ?SizedBox.shrink()
                                        :Icon(
                                      CupertinoIcons.circle_fill,
                                      color: (isBeaconNear ?? false)
                                          ? Colors.green
                                          : Colors.red,
                                    )
                                  ],
                                ),

                              ),
                            ],
                          ) ,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 35.0, right: 6.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.wifi_tethering,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            ' Name : ',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 6.0, right: 30.0),
                                          child: Text(
                                              foundBeacon?['name'] ?? 'Unamed',
                                              style: TextStyle(fontSize: 18), softWrap: true,)),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 35.0, right: 6.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.filter_tilt_shift,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            ' Mac Address : ',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 6.0, right: 30.0),
                                          child: Text(macAddress ?? "",
                                              style: TextStyle(fontSize: 18, ), softWrap: true,), ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 35.0, right: 6.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.radar_outlined,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            ' RSSI : ',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            left: 6.0, right: 30.0),
                                        child: Text(
                                            '${currentRssi != 10000 ? currentRssi : '-∞'} dBm' ??
                                                '',
                                            style: TextStyle(fontSize: 18)))
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 35.0, right: 6.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.settings_remote_outlined,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            ' Connection : ',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            left: 6.0, right: 30.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: (isBeaconNear ?? false)
                                                  ? Colors.green
                                                  : Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: Text(
                                              (isBeaconNear ?? false)
                                                  ? '   In Range   '
                                                  : '   Not in Range   ',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white)),
                                        ))
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 35.0, right: 6.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.battery_75_percent,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            ' Battery : ',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            left: 6.0, right: 30.0),
                                        child: Text(
                                            // '${foundBeacon?['frames'].firstWhere((map) => map['type'] == 'tlm', orElse: () => {})['batteryVol']} Vol. (${foundBeacon?['battery'].toString()}%)' ?? '',
                                            '${foundBeacon?['battery'].toString()=='0'?'100':foundBeacon?['battery'].toString()}%',
                                            style: TextStyle(fontSize: 18)))
                                  ],
                                ),
                                (isPaired && foundBeacon != null)
                                    ? Column(
                                  children: [
                                    Divider(
                                      color: Colors.black,
                                      thickness: 0.7,
                                      endIndent: 15,
                                      indent: 15,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 20.0, right: 6.0),
                                          child: Text(
                                            "Beacon Lifetime Mileage :",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 6.0, right: 20.0),
                                          child: Text(
                                            "${(beaconLifeTimeMileage / 1000).toStringAsFixed(2)} KM",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 20.0, right: 6.0),
                                          child: Text(
                                            "VALID Mileage :",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 6.0, right: 20.0),
                                          child: Text(
                                            "${(validMileage / 1000).toStringAsFixed(2)} KM",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 20.0, right: 6.0),
                                          child: Text(
                                            "INVALID Mileage :",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 6.0, right: 20.0),
                                          child: Text(
                                            "${(invalidMileage / 1000).toStringAsFixed(2)} KM",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                )
                                    : SizedBox.shrink(),
                              ],
                            ),
                          ],
                        ),
                      )
                      : Column(
                          children: [
                            Icon(
                              Icons.wifi_tethering_off,
                              size: 40,
                            ),
                            Text(
                              "Pair a Beacon to see Beacon Details",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            )
                          ],
                        ),

                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 6.0, left: 22.0, right: 6.0),
                  child: Text('Trip List',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ),
              ),
              trips.isEmpty
                  ? SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(
                          bottom: 8.0,
                          left: 6.0,
                          right: isSelected ? 6 : 20,
                          top: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isSelected = !isSelected;
                            for (var trip in trips) {
                              trip.isChecked = false;
                            }
                          });
                        },
                        child: Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 0.7),
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black87),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "  ${isSelected ? 'Deselect' : ' Select '}  ",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            )),
                      ),
                    ),
              isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(
                          bottom: 8.0, left: 6.0, right: 20.0, top: 6),
                      child: InkWell(
                        onTap: () async {
                          await exportTrips();
                          print("Pressed on Export JSON");
                          setState(() {
                            isSelected = false;
                            for (var trip in trips) {
                              trip.isChecked = false;
                            }
                          });
                        },
                        child: Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 0.7),
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black87),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "   Export JSON   ",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            )),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
          Expanded(
              child: trips.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 45,
                        ),
                        Text(
                          "No recorded trips to show",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        )
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TripDetails(trip: trips[index])));
                          },
                          onLongPress: () {
                            setState(() {
                              trips[index].isChecked = true;
                              isSelected = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 0.7),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white),
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "${DateFormat("dd MMM yyyy").format(trips[index].trip[0].timestamp.toLocal())}",
                                          style: TextStyle(
                                              // fontWeight: FontWeight.bold,
                                              fontSize: 17),
                                        ),
                                        TextSpan(
                                          text: ", ",
                                        ),
                                        TextSpan(
                                          text:
                                              "${DateFormat('HH:mm').format(trips[index].trip[0].timestamp.toLocal())}",
                                          style: TextStyle(
                                              // fontStyle: FontStyle.italic,
                                              fontSize: 17),
                                        ),
                                        TextSpan(
                                          text: " - ",
                                        ),
                                        TextSpan(
                                          text:
                                              "${DateFormat('HH:mm').format(trips[index].trip[trips[index].trip.length - 1].timestamp.toLocal())}",
                                          style: TextStyle(
                                              // fontStyle: FontStyle.italic,
                                              fontSize: 17),
                                        ),
                                        TextSpan(
                                          text: ", ",
                                        ),
                                        TextSpan(
                                          text:
                                              "${(trips[index].distance / 1000).toStringAsFixed(2)} km",
                                          style: TextStyle(
                                            // fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: trips[index].tripStatus
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  child: Text(
                                    "${trips[index].tripStatus ? "   VALID   " : "   INVALID   "}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Visibility(
                                  visible: isSelected || trips[index].isChecked,
                                  child: Checkbox(
                                    visualDensity: VisualDensity(vertical: -4),
                                    value: trips[index].isChecked,
                                    onChanged: (val) {
                                      setState(() {
                                        trips[index].isChecked = val!;
                                      });
                                    },
                                    activeColor: Colors
                                        .blue, // Change color to blue when checked
                                    checkColor:
                                        Colors.white, // Color of the check mark
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          50), // Circular shape
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }))
        ],
      ),
    );
  }

  List<RadarDataSet> showingDataSets() {
    return rawDataSets().asMap().entries.map((entry) {
      final index = entry.key;
      final rawDataSet = entry.value;

      final isSelected = index == selectedDataSetIndex
          ? true
          : selectedDataSetIndex == -1
              ? true
              : false;

      return RadarDataSet(
        fillColor: isSelected
            ? rawDataSet.color.withOpacity(0.2)
            : rawDataSet.color.withOpacity(0.05),
        borderColor:
            isSelected ? rawDataSet.color : rawDataSet.color.withOpacity(0.25),
        entryRadius: isSelected ? 3 : 2,
        dataEntries:
            rawDataSet.values.map((e) => RadarEntry(value: e)).toList(),
        borderWidth: isSelected ? 2.3 : 2,
      );
    }).toList();
  }

  List<RawDataSet> rawDataSets() {
    return [
      RawDataSet(
        title: 'one',
        color: Colors.grey.shade200,
        values: [
          100,
          100,
          100,
        ],
      ),
      RawDataSet(
        title: 'three',
        color: Colors.blue,
        values: [
          40,
          40,
          95,
        ],
      ),
      RawDataSet(
        title: 'two',
        color: Colors.indigo,
        values: [
          80,
          82,
          72,
        ],
      ),
    ];
  }
}

class RawDataSet {
  RawDataSet({
    required this.title,
    required this.color,
    required this.values,
  });

  final String title;
  final Color color;
  final List<double> values;
}
