import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:beacon_scanner/beacon_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:telematic/models/trip.dart';
// import 'package:location/location.dart' as LOC;

import 'databaseService.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.defaultImportance,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_launcher'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  print('STARTING BG SERVICE');

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStartOnBoot: true,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'YAMAHA TELEMETRIC SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      // onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  onStart(service);
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print('in ONStart');

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onScanedPeripheral':
        print('MOWWWWWWW\n.\n.\n.\n.n\\n.\n.\n.\n.\n.\n. ${call.arguments}');
        break;
      default:
        print('Unknown method ${call.method}');
    }
  }

  bool _isLoc = false;
  bool _isBlu = false;
  bool _isNot = false;
  bool _isAct = false;
  bool _isBat = false;
  bool _isPermNotifSent = false;

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  MethodChannel channel = MethodChannel('com.example.telematic/minewsdk');
  channel.setMethodCallHandler(_handleMethodCall);

  bool isBeaconNear = false;
  bool isStartedManual = false;

  DateTime? lastValidGps;
  DateTime? lastInvalidGps;

  bool isTripStarted = false;
  DateTime? badRssiStart;
  DateTime? badRssiEnd;
  DateTime? noRssiStart;
  DateTime? noRssiEnd;
  int beaconCurrBattery = 100;
  int? beaconStartBattery = 100;
  int? deviceStartBattery;
  int tripStopReason = 0;

  bool? isBluetoothOn = null;

  List<Position> positions = [];
  List<Position> positions_raw = [];
  List<Position> positionsBeforeStarting = [];
  List<Map<DateTime, DateTime>> badRssiList = [];
  List<Map<DateTime, DateTime>> noRssiList = [];
  List<dynamic> allBeaconDataRssi = [];
  List<dynamic> badRssiData = [];

  // LOC.Location location = new LOC.Location();
  // location.enableBackgroundMode(enable: true);
  // location.changeSettings(accuracy: LOC.LocationAccuracy.high, interval: 100);

  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? macAddress = await prefs.getString('macAddress');

  int elapsedTime = 0;
  int? tripEndTime;
  int seconds = prefs.getInt("seconds") ?? 0;
  int detectedOn = prefs.getInt("detectedOn") ?? 0;
  bool isLocationStreamCanceled = true;

  StreamSubscription<Position>? positionStreamSubscription;
  StreamSubscription<Position>? positionStreamSubscription_raw;
  StreamSubscription<BluetoothAdapterState>? bluetoothStreamSubscription;

  double rssiThreshold = prefs.getDouble("rssiThreshold") ?? -90;
  double gpsSpeedThreshold = prefs.getDouble("gpsSpeedThreshold") ?? 15;
  double gpsTimeThreshold = prefs.getDouble("gpsContinuousTimeThreshold") ?? 5;
  double stopGpsThreshold = prefs.getDouble("stopGpsThreshold") ?? 5;
  double stopBeaconThreshold = prefs.getDouble("stopBeaconThreshold") ?? 360;
  double rssiCoverageThreshold = prefs.getDouble("rssiCoverageThreshold") ?? 70;
  double tripDistanceThreshold = prefs.getDouble("tripDistanceThreshold") ?? 0.1;
  double sampleFrequency = prefs.getDouble("sampleFrequency") ?? 1000;
  double stopGpsSpeedThreshold = prefs.getDouble("stopGpsSpeedThreshold") ?? 15;
  double beaconSampleFrequencyThreshold = prefs.getDouble("beaconSampleFrequencyThreshold") ?? 4;
  double beaconOutOfRangeThreshhold = prefs.getDouble("beaconOutOfRangeThreshhold") ?? 15;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  } else {}

  service.on('stopService').listen((event) async {
    if (positions.isNotEmpty) {
      saveTrips(
        macAddress: macAddress,
        positions: positions.toList(),
        positions_raw: positions_raw,
        badRssiList: badRssiList.toList(),
        noRssiList: noRssiList.toList(),
        allBeaconDataRssi: allBeaconDataRssi.toList(),
        badRssiData: badRssiData.toList(),
        beaconStartBattery: beaconStartBattery ?? 0,
        beaconEndBattery: beaconCurrBattery,
        deviceStartBattery: deviceStartBattery ?? 0,
        deviceEndBattery: await Battery().batteryLevel,
        rssiCoverageThreshold: rssiCoverageThreshold,
        tripDistanceThreshold: tripDistanceThreshold,
        service: service,
        tripStopReason: 6,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      );
    }
    isTripStarted = false;
    positions.clear();
    positions_raw.clear();
    positionsBeforeStarting.clear();
    badRssiList.clear();
    noRssiList.clear();
    allBeaconDataRssi.clear();
    badRssiData.clear();
    deviceStartBattery = null;
    badRssiStart = null;
    badRssiEnd = null;
    noRssiStart = null;
    noRssiEnd = null;
    lastInvalidGps = null;
    tripEndTime = null;
    tripStopReason = 0;
    service.invoke('updateTripList');
    service.stopSelf();
  });

  service.on('startTracking').listen((event) async {
    isStartedManual = true;
    service.invoke('setTimer', {
      "time": elapsedTime,
    });
    // prefs.setString('timeStarted', DateTime.now().toString());
  });

  service.on('stopTracking').listen((event) {
    isStartedManual = false;
    // prefs.remove('timeStarted');
    if (tripEndTime == null) {
      tripEndTime = seconds;
      print('FOUND TRIP END TIME: ${tripEndTime}');
    }
    service.invoke('stopTimer');
  });

  service.on('SearchMacAddress').listen((event) {
    event?.forEach((key, value) {
      print("searching mac address");
      if (key == 'macAddressKey') {
        macAddress = value;
      }
    });
  });

  service.on('UpdateThreshold').listen((event) {
    print("indside setting ${prefs.getDouble("rssiThreshold")}");
    event?.forEach((key, value) {
      if (key == 'rssiThreshold') {
        rssiThreshold = double.parse(value.toString());
      }
      if (key == 'gpsSpeedThreshold') {
        gpsSpeedThreshold = double.parse(value.toString());
      }
      if (key == 'gpsTimeThreshold') {
        gpsTimeThreshold = double.parse(value.toString());
      }
      if (key == 'stopGpsThreshold') {
        stopGpsThreshold = double.parse(value.toString());
      }
      if (key == 'rssiCoverageThreshold') {
        rssiCoverageThreshold = double.parse(value.toString());
      }
      if (key == 'tripDistanceThreshold') {
        tripDistanceThreshold = double.parse(value.toString());
      }
      if (key == 'sampleFrequency') {
        sampleFrequency = double.parse(value.toString());
      }
      if (key == 'stopGpsSpeedThreshold') {
        stopGpsSpeedThreshold = double.parse(value.toString());
      }
      if (key == 'stopBeaconThreshold') {
        stopBeaconThreshold = double.parse(value.toString());
      }
      if (key == 'beaconSampleFrequencyThreshold') {
        beaconSampleFrequencyThreshold = double.parse(value.toString());
      }
      if (key == 'beaconOutOfRangeThreshhold') {
        beaconOutOfRangeThreshhold = double.parse(value.toString());
      }

      print("key::::::::::: $key          value::::::::::::::: $value");
    });
  });

  String unformatString(String input) {
    String unformattedString = input.replaceAll(':', '');
    return unformattedString;
  }

  Future<void> readFile() async {
    try {
      print("reading file");
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      print("äpp dir path ${appDocPath}");
      File file = File('${appDocPath}/beacons.json');

      print('Seconds: $seconds and Last Detected on $detectedOn');
      if (seconds - detectedOn > beaconOutOfRangeThreshhold) {
        print("not detected for ${beaconOutOfRangeThreshhold} secs");
        service.invoke('foundBeacon', {"isBeaconNear": false, "rssi": 10000});
        if (noRssiStart == null && isTripStarted) {
          noRssiStart = DateTime.now();
        }
        if (badRssiStart == null && isTripStarted) {
          badRssiStart = DateTime.now();
        }

        if (!isStartedManual) {
          isBeaconNear = false;
          // continue the trip to store all lat long
          //isTripStarted = false;
          // prefs.remove('timeStarted');
          service.invoke('stopTimer');
          if (tripEndTime == null) {
            tripEndTime = seconds;
            print('FOUND TRIP END TIME: ${tripEndTime}');
          }
        }
      }

      if (await file.exists()) {
        String contents = await file.readAsString();
        print("content in flutter");
        print(contents);
        List<dynamic> beacons = jsonDecode(contents);
        for (var beacon in beacons) {
          print("HUHUHUHUHU detected MAC ::: ${beacon['mac']}");
          DateTime timeDetected = Platform.isAndroid ? DateTime.fromMillisecondsSinceEpoch(beacon['lastUpdate'].toInt()).toLocal() : DateTime.parse(beacon['lastUpdate']).toLocal();
          print("HUHUHUHUHU detected on ::: ${timeDetected}");
          print("HUHUHUHUHU rssi is ::: ${beacon['rssi']}");
          if (macAddress != null && beacon['mac'] == (Platform.isAndroid ? macAddress : unformatString(macAddress ?? "").toLowerCase())) {

            if (DateTime.now().difference(timeDetected) > Duration(seconds: beaconOutOfRangeThreshhold.toInt())) {
              print('detected but too long ago so deleting file...');

              if (badRssiStart == null && isTripStarted)
                badRssiStart = DateTime.now();
              if (noRssiStart == null && isTripStarted) {
                noRssiStart = DateTime.now();
              }

              // TBD clear file
              // await file.writeAsString('');
            } else {
              print('beacon detected YAY');
              detectedOn = seconds;
              print('beacon detected YAY 001');
              beaconCurrBattery = beacon['battery'];
              print('beacon detected YAY 002');
              await prefs.setInt('detectedOn', detectedOn);
              print('beacon detected YAY 003');

              if (isTripStarted) {
                print('beacon detected YAY 004');
                var tempModifiedBeacon = beacon;
                beacon['lastUpdate'] = DateTime.fromMillisecondsSinceEpoch(beacon['lastUpdate'].toInt()).toLocal().toIso8601String();
                tempModifiedBeacon['lastUpdate'] = DateTime.now().toIso8601String().replaceFirst('T', ' ');
                allBeaconDataRssi.add(tempModifiedBeacon);
                print('BEACON 005 RSSI :: ${beacon['rssi']}');
                if(beacon['rssi'] <= rssiThreshold){
                  print('beacon detected YAY 006');
                  // var temp = beacon;
                  // beacon['lastUpdate'] = DateTime.fromMillisecondsSinceEpoch(beacon['lastUpdate'].toInt()).toLocal().toIso8601String();
                  // temp['lastUpdate'] = DateTime.now().toIso8601String().replaceFirst('T', ' ');
                  badRssiData.add(tempModifiedBeacon);
                }
                // allBeaconDataRssi.add(beacon);
              }

              if (beacon['rssi'] <= rssiThreshold) {
                print("stopped becus rssi was too high");
                print('beacon detected YAY 007');

                if (badRssiStart == null && isTripStarted) {
                  badRssiStart = DateTime.now();
                  print("badrssistart -> $badRssiStart");
                }
                if (noRssiStart != null) {
                  noRssiEnd = DateTime.now();
                  noRssiList.add({noRssiStart!: noRssiEnd!});
                  print('norssiend -> $noRssiEnd :::: norssilist -> $noRssiList');
                  noRssiStart = null;
                  noRssiEnd = null;
                }

                service.invoke('foundBeacon', {
                  "isBeaconNear": false,
                  "rssi": beacon['rssi'],
                });

                if (!isStartedManual) {
                  isBeaconNear = false;
                  // continue the trip to store all lat long
                  //isTripStarted = false;
                  // prefs.remove('timeStarted');
                  service.invoke('stopTimer');
                  if (tripEndTime == null) {
                    tripEndTime = seconds;
                    print('FOUND TRIP END TIME: ${tripEndTime}');
                  }
                }
                //TBD Stop TRip
              }
              else {
                service.invoke('foundBeacon', {
                  "isBeaconNear": true,
                  "rssi": beacon['rssi'],
                });

                if (badRssiStart != null) {
                  badRssiEnd = DateTime.now();
                  badRssiList.add({badRssiStart!: badRssiEnd!});
                  print('badrssiend -> $badRssiEnd :::: badrssilist -> $badRssiList');
                  badRssiStart = null;
                  badRssiEnd = null;
                }

                if (noRssiStart != null) {
                  noRssiEnd = DateTime.now();
                  noRssiList.add({noRssiStart!: noRssiEnd!});
                  print('norssiend -> $noRssiEnd :::: norssilist -> $noRssiList');
                  noRssiStart = null;
                  noRssiEnd = null;
                }

                if (!isStartedManual) {
                  isBeaconNear = true;
                  // prefs.setString('timeStarted', DateTime.now().toString());
                }
                //TBD Start Trip
              }
            }
          }
        }
      } else {
        print("doesnt exists");
      }
    } catch (e) {
      print('Error reading file: $e');
    }
  }

  // Future<void> recordTrip() async {
  //
  //   print('IN RECORD TRIPPPP');
  //   Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
  //
  //   print('POISITION SPID -> ${position.speed*3.6}');
  //   if((position.speed * 3.6) > 300){
  //     lastValidGps = null;
  //   }
  //
  //   if((position.speed * 3.6) >= gpsSpeedThreshold){
  //     lastValidGps = lastValidGps !=null ? lastValidGps : DateTime.now();
  //     print('HEllO_Hello ${DateTime.now().difference(lastValidGps!)}  Duration -> ${Duration(seconds: gpsTimeThreshold.toInt())}');
  //     if(DateTime.now().difference(lastValidGps!) >= Duration(seconds: gpsTimeThreshold.toInt())){
  //       isTripStarted = true;
  //
  //      prefs.setBool("isTripStarted", true);
  //      service.invoke('startTrip');
  //
  //       beaconStartBattery = beaconStartBattery==null?beaconCurrBattery:beaconStartBattery;
  //       deviceStartBattery = deviceStartBattery==null?await Battery().batteryLevel:deviceStartBattery;
  //       print('jujujujujujujujujujuujuju ${beaconStartBattery} --- ${deviceStartBattery}');
  //       await flutterLocalNotificationsPlugin.show(
  //         0, // notification id
  //         'Trip Started', // title
  //         'We have detected that you are driving.', // body
  //         NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             'my_foreground', // id
  //             'MY FOREGROUND SERVICE', // title
  //             importance: Importance.max,
  //           ),
  //         ),
  //         payload: 'item id 2', // optional payload
  //       );
  //     }
  //   }else{
  //     lastValidGps = null;
  //   }
  //
  //   print('lastValidGps -> $lastValidGps');
  //
  // }

  // Future<void> recordTripStream(Position position) async {
  //
  //   print('IN RECORD TRIPPPP');
  //
  //   print('POSITION SPEED -> ${position.speed * 3.6}');
  //
  //   // Add current position to the list if speed is valid
  //   if ((position.speed * 3.6) <= 300) {
  //     positionsBeforeStarting.add(position);
  //   }else{
  //     lastValidGps = null;
  //   }
  //
  //   // Calculate the average speed of positions in the last gpsTimeThreshold seconds
  //   // double averageSpeed = positionsBeforeStarting.isNotEmpty
  //   //     ? positionsBeforeStarting.map((pos) => pos.speed * 3.6).reduce((a, b) => a + b) / positionsBeforeStarting.length
  //   //     : 0.0;
  //   // print('Average Speed -> $averageSpeed');
  //
  //   // Start trip based on the average speed
  //   if ((position.speed * 3.6) >= gpsSpeedThreshold) {
  //     lastValidGps = lastValidGps != null ? lastValidGps : DateTime.now();
  //
  //     // print('HEllO_Hello ${DateTime.now().difference(lastValidGps!)}  Duration -> ${Duration(seconds: gpsTimeThreshold.toInt())}');
  //
  //     // if (DateTime.now().difference(positionsBeforeStarting[0].timestamp) >= Duration(seconds: (gpsTimeThreshold.toInt()-1)<0?(gpsTimeThreshold.toInt()):(gpsTimeThreshold.toInt()-1))) {
  //     if (DateTime.now().difference(lastValidGps!) >= Duration(seconds: gpsTimeThreshold.toInt())) {
  //       isTripStarted = true;
  //       positions = positionsBeforeStarting;
  //
  //       prefs.setBool("isTripStarted", true);
  //       service.invoke('startTrip');
  //
  //       beaconStartBattery = beaconStartBattery == null ? beaconCurrBattery : beaconStartBattery;
  //       deviceStartBattery = deviceStartBattery == null ? await Battery().batteryLevel : deviceStartBattery;
  //
  //       print('jujujujujujujujujujuujuju ${beaconStartBattery} --- ${deviceStartBattery}');
  //
  //       await flutterLocalNotificationsPlugin.show(
  //         0, // notification id
  //         'Trip Started', // title
  //         'We have detected that you are driving.', // body
  //         NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             'my_foreground', // id
  //             'MY FOREGROUND SERVICE', // title
  //             importance: Importance.max,
  //           ),
  //         ),
  //         payload: 'item id 2', // optional payload
  //       );
  //     }
  //   } else {
  //     lastValidGps = null;
  //   }
  //
  //   print('lastValidGps -> $lastValidGps');
  //   print('Current PositionsBeforeStarting List Size -> ${positionsBeforeStarting.length}');
  // }

  Future<void> recordTripStream(Position position) async {
    print('IN RECORD TRIPPPP');

    print('POISITION SPID -> ${position.speed * 3.6}');
    if ((position.speed * 3.6) > 300) {
      lastValidGps = null;
    }

    double avgSpeed = (CalcDist(positionsBeforeStarting) / (positionsBeforeStarting.last.timestamp.difference(positionsBeforeStarting.first.timestamp).inSeconds)) * 3.6;

    if ((position.speed * 3.6) >= gpsSpeedThreshold) {
      // if(avgSpeed >= gpsSpeedThreshold){
      lastValidGps = lastValidGps != null ? lastValidGps : DateTime.now();
      print('HEllO_Hello ${DateTime.now().difference(lastValidGps!)}  Duration -> ${Duration(seconds: gpsTimeThreshold.toInt())}');
      if (DateTime.now().difference(lastValidGps!) >= Duration(seconds: gpsTimeThreshold.toInt())) {
        // if((positionsBeforeStarting.last.timestamp.difference(
        //     positionsBeforeStarting.first.timestamp) >=
        //     Duration(seconds: (
        //         (gpsTimeThreshold-1)<=0
        //             ?(gpsTimeThreshold)
        //             :(gpsTimeThreshold-1)).toInt()
        //     ))
        //     &&(
        //     DateTime.now().difference(positionsBeforeStarting.last.timestamp)<=
        //         Duration(seconds: 4)
        //     )
        // ){
        isTripStarted = true;
        positions.clear();
        positions_raw.clear();
        for (var pos in positionsBeforeStarting) {
          positions.add(pos);
        }
        prefs.setBool("isTripStarted", true);
        service.invoke('startTrip');

        beaconStartBattery = beaconStartBattery == null ? beaconCurrBattery : beaconStartBattery;
        deviceStartBattery = deviceStartBattery == null ? await Battery().batteryLevel : deviceStartBattery;
        print('jujujujujujujujujujuujuju ${beaconStartBattery} --- ${deviceStartBattery}');
        await flutterLocalNotificationsPlugin.show(
          0, // notification id
          'Trip Started', // title
          'We have detected that you are driving.', // body
          NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground', // id
              'MY FOREGROUND SERVICE', // title
              importance: Importance.max,
            ),
          ),
          payload: 'item id 2', // optional payload
        );
      }
    } else {
      lastValidGps = null;
    }

    print('lastValidGps -> $lastValidGps');
  }

  final LocationSettings locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
    intervalDuration: Duration(milliseconds: 1000),
  );

  final LocationSettings locationSettings_raw = AndroidSettings(
    forceLocationManager: true,
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
    intervalDuration: Duration(milliseconds: 1000),
  );

  startTrackingTrip() async {
    positionStreamSubscription?.cancel();
    positionStreamSubscription_raw?.cancel();

    positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position currposition) async {
      print('from the position stream ->> $currposition');

      if (isBeaconNear && !isTripStarted) {
        if (currposition != null) {
          // Remove positions older than gpsTimeThreshold from the list
          positionsBeforeStarting.removeWhere((pos) => DateTime.now().difference(pos.timestamp) > Duration(seconds: gpsTimeThreshold.toInt() + 1));
          positionsBeforeStarting.add(currposition);
          recordTripStream(currposition);
        }
      }

      if (isTripStarted) {
        service.invoke('tripStarted', {
          "isTripStarted": true,
        });
        ++elapsedTime;
        if (isBeaconNear) tripEndTime = null;
        Position position = currposition ?? Position(longitude: 0, latitude: 0, timestamp: DateTime(1970), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0);
        if ((position.accuracy ?? 101) > 100) {
          service.invoke('gpsStrengthUpdate', {
            "strength": "Weak",
          });
        }
        else {
          service.invoke('gpsStrengthUpdate', {
            "strength": "Strong",
          });
        }

        if ((positions.isEmpty) || (positions.elementAt(positions.length - 1).longitude != position.longitude || positions.elementAt(positions.length - 1).latitude != position.latitude) || true) {
          // if((positions.isEmpty) || (Geolocator.distanceBetween(lastSecondPosition.latitude, lastSecondPosition.longitude, position.latitude, position.longitude) >= 5))
          {
            if (currposition != null) {
              positions.add(position);
            }
            print('IS VALID!!');
            if ((position.speed * 3.6) < stopGpsSpeedThreshold) {
              lastInvalidGps = lastInvalidGps != null ? lastInvalidGps : DateTime.now();
              print('Stop_Stop ${DateTime.now().difference(lastInvalidGps!)}  Duration -> ${Duration(seconds: stopGpsThreshold.toInt() * 60)}');
              if (DateTime.now().difference(lastInvalidGps!) >= Duration(seconds: stopGpsThreshold.toInt() * 60)) {
                isTripStarted = false;
                // if (tripEndTime == null) {
                  tripStopReason = 1;
                  tripEndTime = seconds - (stopBeaconThreshold.toInt() * 60) - 10;
                  print('FOUND TRIP END TIME: ${tripEndTime}');
                // }
              }
            } else {
              lastInvalidGps = null;
              tripStopReason = 0;
            }
          }
          // lastSecondPosition = position;
        }
        print('lat -> ${position.latitude} , lng -> ${position.longitude}, speed -> ${position.speed}, time -> ${position.timestamp}');
        // service.invoke('setTimer', {
        //   "time": elapsedTime,
        // });
      } else {
        print("Device movement is being recorded but tracking isn't started");
      }
    });

    positionStreamSubscription_raw = Geolocator.getPositionStream(locationSettings: locationSettings_raw).listen((Position currposition) async {
      print('from the position_raw stream ->> $currposition');
      if (isTripStarted) {
        positions_raw.add(currposition);
      } else {
        print("Device movement is being recorded but tracking isn't started");
      }
    });
  }

  service.on('permissionsGranted').listen((event) async {
    print('OPENED PERMISSIONS GRANTD SERVICE');
    startTrackingTrip();
  });

  late Position lastSecondPosition;

  final bluetoothInstance = FlutterBluePlus.adapterState;
  checkIfBluetoothisOn() async {
    bluetoothStreamSubscription?.cancel();
    if (await Permission.bluetoothScan.isGranted) {
      bluetoothStreamSubscription = bluetoothInstance.listen((state) async {
        if (state == BluetoothAdapterState.on) {
          // Bluetooth is on
          isBluetoothOn = true;
          print("bluetooth is onnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn");
          // await flutterLocalNotificationsPlugin.cancel(123);
        } else if (state == BluetoothAdapterState.off) {
          print("bluetooth is ooooooooooooooffffffffffffffffffffffff");

          if (positions.isNotEmpty) {
            print("calling save trips because of bluetoothhhhh.");
            saveTrips(
              macAddress: macAddress,
              positions: positions.toList(),
              positions_raw: positions_raw,
              badRssiList: badRssiList.toList(),
              noRssiList: noRssiList.toList(),
              allBeaconDataRssi: allBeaconDataRssi.toList(),
              badRssiData: badRssiData.toList(),
              beaconStartBattery: beaconStartBattery ?? 0,
              beaconEndBattery: beaconCurrBattery,
              deviceStartBattery: deviceStartBattery ?? 0,
              deviceEndBattery: await Battery().batteryLevel,
              rssiCoverageThreshold: rssiCoverageThreshold,
              tripDistanceThreshold: tripDistanceThreshold,
              service: service,
              tripStopReason: 3,
              flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
            );
          }
          isTripStarted = false;
          positions.clear();
          positions_raw.clear();
          positionsBeforeStarting.clear();
          badRssiList.clear();
          noRssiList.clear();
          allBeaconDataRssi.clear();
          badRssiData.clear();
          deviceStartBattery = null;
          badRssiStart = null;
          badRssiEnd = null;
          noRssiStart = null;
          noRssiEnd = null;
          lastInvalidGps = null;
          tripEndTime = null;
          tripStopReason = 0;
          service.invoke('updateTripList');

          isBluetoothOn = false;
          await flutterLocalNotificationsPlugin.show(
            123, // notification id
            'App has been terminated', // title
            'Tap here to Restart the Tracking.', // body
            NotificationDetails(
              android: AndroidNotificationDetails(
                  'my_foreground', // id
                  'MY FOREGROUND SERVICE', // title
                  importance: Importance.max,
                  styleInformation: BigTextStyleInformation('')),
            ),
            payload: 'item id 2', // optional payload
          );

          // exit(0);
        }
      });
    }
  }

  if (await Permission.location.isGranted) {
    _isLoc = true;
  }
  if (Platform.isIOS) {
    if (await Permission.bluetooth.isGranted) {
      _isBlu = true;
      print('BluetoothisGranted');
      checkIfBluetoothisOn();
    }
  } else if (Platform.isAndroid) {
    if (await Permission.bluetoothScan.isGranted) {
      _isBlu = true;
      print('BluetoothisGranted2');
      checkIfBluetoothisOn();
    }
  }
  if (await Permission.notification.isGranted) {
    _isNot = true;
  }
  if (await prefs.getBool("isHibernationDisabled") ?? false) {
    _isAct = true;
  }
  if (await prefs.getBool("isBatteryDisabled") ?? false) {
    _isBat = true;
  }
  if (!(_isLoc && _isBlu && _isNot && _isAct && _isBat)) {
  } else {
    // startTrackingTrip();
  }

  Timer.periodic(Duration(milliseconds: sampleFrequency.toInt()), (timer) async {
    if (await Permission.location.isGranted) {
      _isLoc = true;
    } else {
      if (_isLoc) {
        positionStreamSubscription?.cancel();
        positionStreamSubscription_raw?.cancel();
        isLocationStreamCanceled = true;
        if (positions.isNotEmpty) {
          saveTrips(
            macAddress: macAddress,
            positions: positions.toList(),
            positions_raw: positions_raw,
            badRssiList: badRssiList.toList(),
            noRssiList: noRssiList.toList(),
            allBeaconDataRssi: allBeaconDataRssi.toList(),
            badRssiData: badRssiData.toList(),
            beaconStartBattery: beaconStartBattery ?? 0,
            beaconEndBattery: beaconCurrBattery,
            deviceStartBattery: deviceStartBattery ?? 0,
            deviceEndBattery: await Battery().batteryLevel,
            rssiCoverageThreshold: rssiCoverageThreshold,
            tripDistanceThreshold: tripDistanceThreshold,
            service: service,
            tripStopReason: 4,
            flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
          );
        }
        isTripStarted = false;
        positions.clear();
        positions_raw.clear();
        positionsBeforeStarting.clear();
        badRssiList.clear();
        noRssiList.clear();
        allBeaconDataRssi.clear();
        badRssiData.clear();
        deviceStartBattery = null;
        badRssiStart = null;
        badRssiEnd = null;
        noRssiStart = null;
        noRssiEnd = null;
        lastInvalidGps = null;
        tripEndTime = null;
        tripStopReason = 0;
        service.invoke('updateTripList');
      }
      _isLoc = false;
    }
    if (Platform.isIOS) {
      if (await Permission.bluetooth.isGranted) {
        if (!_isBlu) checkIfBluetoothisOn();
        _isBlu = true;
      } else {
        if (_isBlu) bluetoothStreamSubscription?.cancel();
        _isBlu = false;
      }
    } else if (Platform.isAndroid) {
      if (await Permission.bluetoothScan.isGranted) {
        if (!_isBlu) checkIfBluetoothisOn();
        _isBlu = true;
      } else {
        // if(_isBlu)
        bluetoothStreamSubscription?.cancel();
        _isBlu = false;
      }
    }
    if (await Permission.notification.isGranted) {
      _isNot = true;
    } else {
      _isNot = false;
    }
    if (await prefs.getBool("isHibernationDisabled") ?? false) {
      _isAct = true;
    } else {
      _isAct = false;
    }
    if (await prefs.getBool("isBatteryDisabled") ?? false) {
      _isBat = true;
    } else {
      _isBat = false;
    }
    if (!(_isLoc && _isBlu && _isNot && _isAct && _isBat)) {
      if (!_isPermNotifSent) {
        _isPermNotifSent = true;
        await flutterLocalNotificationsPlugin.show(
          404,
          'Beacon Test App Stopped',
          'Due to lack of essential Permissions, the app has been teriminated',
          NotificationDetails(
            android: AndroidNotificationDetails('my_foreground', 'MY FOREGROUND SERVICE', importance: Importance.max, styleInformation: BigTextStyleInformation('')),
          ),
        );

        if (positions.isNotEmpty) {
          saveTrips(
            macAddress: macAddress,
            positions: positions.toList(),
            positions_raw: positions_raw,
            badRssiList: badRssiList.toList(),
            noRssiList: noRssiList.toList(),
            allBeaconDataRssi: allBeaconDataRssi.toList(),
            badRssiData: badRssiData.toList(),
            beaconStartBattery: beaconStartBattery ?? 0,
            beaconEndBattery: beaconCurrBattery,
            deviceStartBattery: deviceStartBattery ?? 0,
            deviceEndBattery: await Battery().batteryLevel,
            rssiCoverageThreshold: rssiCoverageThreshold,
            tripDistanceThreshold: tripDistanceThreshold,
            service: service,
            tripStopReason: 5,
            flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
          );
        }
        isTripStarted = false;
        positions.clear();
        positions_raw.clear();
        positionsBeforeStarting.clear();
        badRssiList.clear();
        noRssiList.clear();
        allBeaconDataRssi.clear();
        badRssiData.clear();
        deviceStartBattery = null;
        badRssiStart = null;
        badRssiEnd = null;
        noRssiStart = null;
        noRssiEnd = null;
        lastInvalidGps = null;
        tripEndTime = null;
        tripStopReason = 0;
        service.invoke('updateTripList');

        print('hereintheloop');
        prefs.setBool("autoTripRecord", false);
        service.stopSelf();
        // exit(0);
        // SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
      }
    } else {
      _isPermNotifSent = false;
      flutterLocalNotificationsPlugin.cancel(404);
      // startTrackingTrip();
    }

    if ((seconds % beaconSampleFrequencyThreshold.toInt() == 0) && _isBlu) {
      readFile();
    }

    if (!isBeaconNear && !isTripStarted) {
      isLocationStreamCanceled = true;
      positionStreamSubscription?.cancel();
      positionStreamSubscription_raw?.cancel();
      // await flutterLocalNotificationsPlugin.show(
      //   145,
      //   'Location Tracking Paused', // title
      //   "Beacon isn't in range", // body
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       'my_foreground', // id
      //       'MY FOREGROUND SERVICE', // title
      //       importance: Importance.max,
      //     ),
      //   ),
      //   payload: 'item id 2', // optional payload
      // );
    }

    if (isBeaconNear && isLocationStreamCanceled) {
      isLocationStreamCanceled = false;
      // flutterLocalNotificationsPlugin.cancel(145);
      startTrackingTrip();
    }

    if (isTripStarted) {
      // service.invoke('tripStarted', {
      //   "isTripStarted": true,
      // });
      // ++elapsedTime;
      // if(isBeaconNear)
      //   tripEndTime = null;
      // Position position = await Geolocator.getCurrentPosition(
      //         desiredAccuracy: LocationAccuracy.bestForNavigation);
      // if (position.accuracy > 100) {
      //   service.invoke('gpsStrengthUpdate', {
      //     "strength": "Weak",
      //   });
      // }
      // else {
      //   service.invoke('gpsStrengthUpdate', {
      //     "strength": "Strong",
      //   });
      // }
      //
      // if ((positions.isEmpty) ||
      //     (positions.elementAt(positions.length - 1).longitude !=
      //             position.longitude ||
      //         positions.elementAt(positions.length - 1).latitude !=
      //             position.latitude) || true) {
      //   // if((positions.isEmpty) || (Geolocator.distanceBetween(lastSecondPosition.latitude, lastSecondPosition.longitude, position.latitude, position.longitude) >= 5))
      //   {
      //     positions.add(
      //       // Position(
      //       //     longitude: position.longitude,
      //       //     latitude: position.latitude,
      //       //     timestamp: DateTime.timestamp(),
      //       //     accuracy: position.accuracy,
      //       //     altitude: position.altitude,
      //       //     altitudeAccuracy: position.altitudeAccuracy,
      //       //     heading: position.heading,
      //       //     headingAccuracy: position.headingAccuracy,
      //       //     speed: position.speed,
      //       //     speedAccuracy: position.speedAccuracy)
      //           position
      //     );
      //     print('IS VALID!!');
      //     if((position.speed * 3.6) < stopGpsSpeedThreshold){
      //       lastInvalidGps = lastInvalidGps !=null ? lastInvalidGps : DateTime.now();
      //       print('Stop_Stop ${DateTime.now().difference(lastInvalidGps!)}  Duration -> ${Duration(seconds: stopGpsThreshold.toInt()*60)}');
      //       if(DateTime.now().difference(lastInvalidGps!) >= Duration(seconds: stopGpsThreshold.toInt()*60)){
      //         isTripStarted = false;
      //         if (tripEndTime == null) {
      //           tripEndTime = seconds - (stopBeaconThreshold.toInt()*60);
      //           print('FOUND TRIP END TIME: ${tripEndTime}');
      //         }
      //       }
      //     }else{
      //       lastInvalidGps = null;
      //     }
      //   }
      //   lastSecondPosition = position;
      // }
      // print(
      //     'lat -> ${position.latitude} , lng -> ${position.longitude}, speed -> ${position.speed}');
      // // service.invoke('setTimer', {
      // //   "time": elapsedTime,
      // // });
    } else {
      print('tracking hasnt started');
    }

    seconds++;
    await prefs.setInt('seconds', seconds);
    print('running for ${seconds} seconds');

    print(tripEndTime != null);
    print(positions.isNotEmpty);
    print(tripEndTime != null && ((seconds - tripEndTime!) > (stopBeaconThreshold.toInt() * 60)));


    if (tripEndTime != null && positions.isNotEmpty && (seconds - tripEndTime!) > (stopBeaconThreshold.toInt() * 60)) {
      elapsedTime = 0;
      isTripStarted = false;
      if (badRssiStart != null) {
        badRssiEnd = DateTime.now();
        badRssiList.add({badRssiStart!: badRssiEnd!});
        print('badrssiend -> $badRssiEnd :::: badrssilist -> $badRssiList');
        badRssiStart = null;
        badRssiEnd = null;
      }
      if (noRssiStart != null) {
        noRssiEnd = DateTime.now();
        noRssiList.add({noRssiStart!: noRssiEnd!});
        print('norssiend -> $noRssiEnd :::: norssilist -> $noRssiList');
        noRssiStart = null;
        noRssiEnd = null;
      }
      print("${beaconStartBattery}--|--|--|--|---${beaconCurrBattery}---|--|--|--|--|--${deviceStartBattery}---|--|--|--|--|--${deviceStartBattery}");
      print("${badRssiList}--|--|--|--|---");
      print("--|--|--|--|---${noRssiList}--|--|--|--|---");
      saveTrips(
        macAddress: macAddress,
        positions: positions.toList(),
        positions_raw: positions_raw,
        badRssiList: badRssiList.toList(),
        noRssiList: noRssiList.toList(),
        allBeaconDataRssi: allBeaconDataRssi.toList(),
        badRssiData: badRssiData.toList(),
        beaconStartBattery: beaconStartBattery ?? 0,
        beaconEndBattery: beaconCurrBattery,
        deviceStartBattery: deviceStartBattery ?? 0,
        deviceEndBattery: await Battery().batteryLevel,
        rssiCoverageThreshold: rssiCoverageThreshold,
        tripDistanceThreshold: tripDistanceThreshold,
        service: service,
        tripStopReason: tripStopReason,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      );
      // await flutterLocalNotificationsPlugin.show(
      //   2, // notification id
      //   'Trip Saved', // title
      //   'We recorded and Saved a new Trip.', // body
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       'my_foreground', // id
      //       'MY FOREGROUND SERVICE', // title
      //       importance: Importance.max,
      //     ),
      //   ),
      //   payload: 'item id 2', // optional payload
      // );
      positions.clear();
      positions_raw.clear();
      positionsBeforeStarting.clear();
      badRssiList.clear();
      noRssiList.clear();
      allBeaconDataRssi.clear();
      badRssiData.clear();
      deviceStartBattery = null;
      badRssiStart = null;
      badRssiEnd = null;
      noRssiStart = null;
      noRssiEnd = null;
      lastInvalidGps = null;
      tripEndTime = null;
      tripStopReason = 0;
    }
    // beaconScanner.
  });
}

Future<void> saveTrips({
  required macAddress,
  required List<Position> positions,
  required List<Position> positions_raw,
  required List<Map<DateTime, DateTime>> badRssiList,
  required List<Map<DateTime, DateTime>> noRssiList,
  required List<dynamic> allBeaconDataRssi,
  required List<dynamic> badRssiData,
  required int beaconStartBattery,
  required int beaconEndBattery,
  required int deviceStartBattery,
  required int deviceEndBattery,
  required int tripStopReason,
  required double rssiCoverageThreshold,
  required double tripDistanceThreshold,
  required final service,
  required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
}) async {
  double distance = CalcDist(positions);
  print("in save tripp----$distance");

  if (distance >= tripDistanceThreshold * 1000) {
    List<Map<String, dynamic>> jsonPositionList = positions.map((position) => position.toJson()).toList();

    List<Map<String, dynamic>> jsonPositionList_raw = positions_raw.map((position) => position.toJson()).toList();

    print("TRIP RAW LENGTH ::: ${jsonPositionList_raw.length}");
    // List jsonBeaconList = allBeaconDataRssi.map((allBeaconDataRssi) =>
    //     allBeaconDataRssi.toJson()).toList();

    Map<String, dynamic> jsonList = {'trip': jsonPositionList, 'trip_raw': jsonPositionList_raw, 'rssi': allBeaconDataRssi, 'badRssiData': badRssiData};

    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/trip_${DateTime.now().toString()}.json';
    final file = File(filePath);
    await file.writeAsString(json.encode(jsonList));
    print("filepath----$filePath----------${file.path}");

    String iso1806 = positions[0].timestamp.toString();
    double speed = CalcSpeed(positions);
    Duration Tottime = Duration(milliseconds: (positions[positions.length - 1].timestamp.difference(positions[0].timestamp)).inMilliseconds);
    // Duration Tottime = Duration(minutes: CalcTime(positions) ~/ 60);
    Duration Badtime = calculateTotalRssiDuration(badRssiList);
    double BadDistance = calculateTotalRssiDistance(badRssiList, positions);
    // double rssiCoverage = Tottime.inSeconds==0?100:((1.0 - (Badtime.inSeconds / Tottime.inSeconds)) * 100);
    double rssiCoverage = ((distance - BadDistance) / distance) * 100;
    print('tottime-> $Tottime badtime-> $Badtime rssicoverage-> $rssiCoverage');
    print('totdistance-> $distance baddistance-> $BadDistance rssicoverage-> $rssiCoverage');

    Trip trip = Trip(
      macAddress: macAddress,
      date: DateTime.parse(iso1806).toLocal(),
      distance: distance,
      points: 9,
      time: Tottime,
      speed: speed.isNaN ? 0 : speed,
      trip: positions,
      trip_raw: positions_raw,
      tripPath: file.path,
      badRssi: badRssiList,
      noRssi: noRssiList,
      beaconBatteryStart: beaconStartBattery,
      beaconBatteryEnd: beaconEndBattery,
      deviceBatteryStart: deviceStartBattery,
      deviceBatteryEnd: deviceEndBattery,
      tripStatus: rssiCoverage >= rssiCoverageThreshold,
      tripStopReason: tripStopReason,
      rssiCoverage: rssiCoverage,
    );
    print("trip time in background::::::::::::::${trip.time.inMinutes}");
    DatabaseService databaseServices = DatabaseService.instance;
    await databaseServices.insertTrip(trip);
    service.invoke('updateTripList');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isTripStarted', false);
    print("trip saved successfully!!!");

    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      'Trip Saved', // title
      'We recorded and Saved a new Trip of Dist. ${(distance / 1000).toStringAsFixed(2)} km and Duration. ${(Tottime.inMinutes ~/ 60) < 10 ? '0' : ''}${(Tottime.inMinutes ~/ 60)}:${(Tottime.inMinutes % 60) < 10 ? '0' : ''}${(Tottime.inMinutes % 60)} hours', // body
      NotificationDetails(
        android: AndroidNotificationDetails(
            'my_foreground', // id
            'MY FOREGROUND SERVICE', // title
            importance: Importance.max,
            styleInformation: BigTextStyleInformation('')),
      ),
      payload: 'item id 2', // optional payload
    );
  } else {
    service.invoke('updateTripList');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isTripStarted', false);
    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      'Trip is not Saved', // title
      'The recorded distance, ${(distance / 1000).toStringAsFixed(2)} km, is less than threshold', // body
      NotificationDetails(
        android: AndroidNotificationDetails(
            'my_foreground', // id
            'MY FOREGROUND SERVICE', // title
            importance: Importance.max,
            styleInformation: BigTextStyleInformation('')),
      ),
      payload: 'item id 2', // optional payload
    );
  }
}

double CalcTime(List<Position> arr) {
  if (arr.length == 0) return 1;
  double? time = (arr[arr.length - 1].timestamp.difference(arr[0].timestamp ?? DateTime.now()).inSeconds).toDouble();
  print('JOJO -> $time');
  return time ?? 1;
}

double CalcSpeed(List<Position> arr) {
  double totDist = CalcDist(arr);
  double time = CalcTime(arr);
  double avgsp = totDist / (time);

  avgsp = avgsp * (3.6);

  return avgsp;
}

double CalcDist(List<Position> arr) {
  double totdist = 0.0;
  for (int i = 0; i < arr.length - 1; ++i) {
    totdist += Geolocator.distanceBetween(arr[i].latitude, arr[i].longitude, arr[i + 1].latitude, arr[i + 1].longitude);
  }
  totdist = totdist;
  return totdist;
}

Duration calculateTotalRssiDuration(List<Map<DateTime, DateTime>> dateTimeList) {
  Duration totalDuration = Duration();
  print('dateTimeList -> $dateTimeList');

  for (Map<DateTime, DateTime> dateTimeMap in dateTimeList) {
    dateTimeMap.forEach((startTime, endTime) {
      totalDuration += endTime.difference(startTime);
    });
  }

  return totalDuration;
}

double calculateTotalRssiDistance(List<Map<DateTime, DateTime>> dateTimeList, List<Position> positions) {
  double totalDistance = 0.0;

  // Loop through each start and end time pair in dateTimeList
  for (var dateTimeMap in dateTimeList) {
    dateTimeMap.forEach((startTime, endTime) {
      // Filter positions based on the current start and end time
      List<Position> filteredPositions = positions.where((position) {
        // DateTime positionTime = DateTime.fromMillisecondsSinceEpoch(position.timestamp);
        print('in here calculatinnnnng');
        DateTime positionTime = position.timestamp;
        return positionTime.isAfter(startTime) && positionTime.isBefore(endTime);
      }).toList();

      // Calculate the distance between consecutive filtered positions
      for (int i = 0; i < filteredPositions.length - 1; i++) {
        Position p1 = filteredPositions[i];
        Position p2 = filteredPositions[i + 1];

        double distance = Geolocator.distanceBetween(
          p1.latitude,
          p1.longitude,
          p2.latitude,
          p2.longitude,
        );

        totalDistance += distance;
      }
    });
  }

  return totalDistance;
}
