import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestMap extends StatefulWidget {
  const TestMap({super.key});

  @override
  State<TestMap> createState() => _TestMapState();
}

class _TestMapState extends State<TestMap> {

  late GoogleMapController _controller;
  List<List<Position>> listTrips = [];

  @override
  void initState() {
    var temp;
    for(int i=0; i<200; ++i){
      temp = generatePositions(6000);
      setState(() {
        listTrips.add(temp);
      });
    }
    print("jojo ->>> ${listTrips.length}");
    super.initState();
  }

  List<Position> generatePositions(int count) {
    List<Position> positions = [];
    Random random = Random();

    double lat = 28.70405920;
    double lon = 77.10249020;

    double bearing = random.nextDouble() * 2 * pi;

    double distance = 1.0;

    double earthRadius = 6378137.0;

    for (int i = 0; i < count; i++) {
      positions.add(Position(
        longitude: lon,
        latitude: lat,
        timestamp: DateTime.now().add(Duration(minutes: i)),
        accuracy: 5.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      ));

      double distanceRadians = distance / earthRadius;

      double lat1 = lat * pi / 180;
      double lon1 = lon * pi / 180;

      double newLat = asin(sin(lat1) * cos(distanceRadians) +
          cos(lat1) * sin(distanceRadians) * cos(bearing));
      double newLon = lon1 +
          atan2(sin(bearing) * sin(distanceRadians) * cos(lat1),
              cos(distanceRadians) - sin(lat1) * sin(newLat));

      lat = newLat * 180 / pi;
      lon = newLon * 180 / pi;
    }

    return positions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (controller) {
          _controller = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(28.70405920,77.10249020),
          zoom: 18,
        ),
        polylines: Set<Polyline>.of([
            for(var trip in listTrips)
              Polyline(
                polylineId: PolylineId('iota-${DateTime.now()}'),
                points: trip
                    .map((position) =>
                    LatLng(position.latitude, position.longitude))
                    .toList(),
                color: Colors.indigo,
                width: 5,
              ),
        ]),
      ),
    );
  }
}
