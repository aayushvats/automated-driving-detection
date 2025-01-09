import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:telematic/models/trip.dart';
import 'package:image/image.dart' as IMG;

import '../shared/kalman.dart';

class TripDetails extends StatefulWidget {
  const TripDetails({Key? key, required this.trip}) : super(key: key);
  final Trip trip;

  @override
  State<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> {

  late GoogleMapController _controller;
  List<Position> kalmanedPos = [];
  List<Position> kalmanedPos_raw = [];
  bool isRawTripChecked = false;
  bool isFusedTripChecked = true;
  late LatLngBounds _bounds;
  String startLoc = '';
  String endLoc = '';

  Uint8List? smallimg;
  Uint8List? endSmallimg;
  Uint8List? marker;
  Uint8List? marker_raw;

  List<Marker> allMarkers = [];

  List<Position> useKalman(List<Position> positions) {
    // KalmanFilter kalmanFilter = KalmanFilter();
    // List<Position> smoothedPositions = [];

    final kalmanFilter = KalmanFilter();
    final List<Position> filteredPositions = [];

    for (int i = 0; i < positions.length; i++) {
      final position = positions[i];
      final filteredCoords = kalmanFilter.process(
          position.latitude, position.longitude, position.accuracy);
      final filteredPosition = Position(
        latitude: filteredCoords[1],
        longitude: filteredCoords[0],
        timestamp: position.timestamp,
        accuracy: position.accuracy,
        altitude: position.altitude,
        altitudeAccuracy: position.altitudeAccuracy,
        heading: position.heading,
        headingAccuracy: position.headingAccuracy,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        floor: position.floor,
        isMocked: position.isMocked,
      );
      filteredPositions.add(filteredPosition);
    }

    return filteredPositions;
  }

  void _calculateBounds() {
    double minLat = double.infinity;
    double minLong = double.infinity;
    double maxLat = -double.infinity;
    double maxLong = -double.infinity;

    widget.trip.trip.forEach((latLng) {
      if (latLng.latitude < minLat) minLat = latLng.latitude;
      if (latLng.longitude < minLong) minLong = latLng.longitude;
      if (latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (latLng.longitude > maxLong) maxLong = latLng.longitude;
    });
    print("maxLat $maxLat minLat $minLat maxLon $maxLong minLon $minLong");
    _bounds = LatLngBounds(
      southwest: LatLng(minLat, minLong),
      northeast: LatLng(maxLat, maxLong),
    );
    print("huun00");
    _setMapBounds();
  }

  void _setMapBounds() async {
    print("huun01");
    if (_controller != null) {
      print("huun02");
      final CameraUpdate cameraUpdate =
      CameraUpdate.newLatLngBounds(_bounds, 50);
      await _controller.animateCamera(cameraUpdate);
    }
  }

  void _fetchAddress() async {
    List<Placemark> start = await placemarkFromCoordinates(
        widget.trip.trip[0].latitude, widget.trip.trip[0].longitude);
    List<Placemark> end = await placemarkFromCoordinates(
        widget.trip.trip[widget.trip.trip.length - 1].latitude,
        widget.trip.trip[widget.trip.trip.length - 1].longitude);
    print(start);
    setState(() {
      // startLoc = start.first.toString();
      startLoc =
      "${start.first.street},\n${start.first.subLocality}, ${start.first.locality}";
      endLoc =
      "${end.first.street},\n${end.first.subLocality}, ${end.first.locality}";
    });
  }

  Uint8List? resizeImage(Uint8List data, width, height) {
    Uint8List? resizedData = data;
    IMG.Image? img = IMG.decodeImage(data);
    IMG.Image resized = IMG.copyResize(img!, width: width, height: height);
    resizedData = Uint8List.fromList(IMG.encodePng(resized));
    return resizedData;
  }

  void _customMarkers() async {
    Uint8List bytes = (await rootBundle.load('assets/images/startx.png'))
        .buffer
        .asUint8List();
    setState(() {
      smallimg = resizeImage(bytes, 60, 60);
    });

    Uint8List endBytes =
    (await rootBundle.load('assets/images/endx.png')).buffer.asUint8List();
    setState(() {
      endSmallimg = resizeImage(endBytes, 60, 60);
    });

    Uint8List markerBytes =
    (await rootBundle.load('assets/images/marker.png')).buffer.asUint8List();
    setState(() {
      marker = resizeImage(markerBytes, 25, 25);
    });

    Uint8List marker_rawBytes =
    (await rootBundle.load('assets/images/marker_raw.png')).buffer.asUint8List();
    setState(() {
      marker_raw = resizeImage(marker_rawBytes, 25, 25);
    });

    // if(isRawTripChecked && widget.trip.trip_raw.isNotEmpty){
    //   setState(() {
    //     allMarkers.addAll(returnMarkers_raw());
    //   });
    // }
    if(isFusedTripChecked && kalmanedPos.isNotEmpty){
      setState(() {
        allMarkers.addAll(returnMarkers());
      });
    }
  }

  bool isBadRssi(Position position) {
    for (var range in widget.trip.badRssi ?? []) {
      for (var entry in range.entries) {
        DateTime startTime = entry.key;
        DateTime endTime = entry.value;
        if (position.timestamp.toLocal().isAfter(startTime) && position.timestamp.toLocal().isBefore(endTime)) {
          print("badrsisi orange");
          return true;
        }
      }
    }
    return false;
  }

  List<Polyline> createColoredPolylines(List<Position> kalmanedPos) {
    print("Color polyline");
    List<Polyline> polylines = [];
    List<LatLng> segment = [];

    // Determine the initial segment type
    bool currentSegmentBadRssi = isBadRssi(kalmanedPos[0]);
    bool currentSegmentNoRssi = isNoRssi(kalmanedPos[0]); // Check if it's a noRssi segment

    // Add the first point to the segment
    segment.add(LatLng(kalmanedPos[0].latitude, kalmanedPos[0].longitude));

    for (int i = 1; i < kalmanedPos.length; i++) { // Start from the second position
      print("isBadRssi(kalmanedPos[i])::::::::::: ${isBadRssi(kalmanedPos[i])}");
      bool badRssi = isBadRssi(kalmanedPos[i]);
      bool noRssi = isNoRssi(kalmanedPos[i]); // Check for noRssi
      LatLng latLng = LatLng(kalmanedPos[i].latitude, kalmanedPos[i].longitude);
      print('Bool bad ${badRssi} Current ${currentSegmentBadRssi} ');

      // Determine if the segment type has changed
      bool segmentChanged = (badRssi != currentSegmentBadRssi) || (noRssi != currentSegmentNoRssi);

      if (segmentChanged) {
        print("Current ${currentSegmentBadRssi}");

        // Add the point where the change happens to the current segment
        segment.add(latLng);

        // Determine the color of the polyline based on the segment type
        Color segmentColor;
        if (currentSegmentNoRssi) {
          segmentColor = Colors.red;
        } else if (currentSegmentBadRssi) {
          segmentColor = Colors.orange;
        } else {
          segmentColor = Colors.lightBlue;
        }

        // Add the current segment to the polylines list
        polylines.add(Polyline(
          polylineId: PolylineId('route_segment_$i'),
          points: List.from(segment),
          color: segmentColor,
          width: 5,
        ));
        segment.clear();

        // Start the new segment with the current point
        segment.add(latLng);
        currentSegmentBadRssi = badRssi;
        currentSegmentNoRssi = noRssi;
      } else {
        segment.add(latLng);
      }
    }

    // Add the last segment
    if (segment.isNotEmpty) {
      // Determine the color of the polyline based on the segment type
      Color segmentColor;
      if (currentSegmentNoRssi) {
        segmentColor = Colors.red;
      } else if (currentSegmentBadRssi) {
        segmentColor = Colors.orange;
      } else {
        segmentColor = Colors.lightBlue;
      }

      polylines.add(Polyline(
        polylineId: PolylineId('route_segment_last'),
        points: List.from(segment),
        color: segmentColor,
        width: 5,
      ));
    }

    return polylines;
  }

// Example implementation of isNoRssi, assuming that a noRssi position has a specific condition
  bool isNoRssi(Position position) {
    for (var range in widget.trip.noRssi ?? []) {
      for (var entry in range.entries) {
        DateTime startTime = entry.key;
        DateTime endTime = entry.value;
        if (position.timestamp.toLocal().isAfter(startTime) && position.timestamp.toLocal().isBefore(endTime)) {
          print("badrsisi orange");
          return true;
        }
      }
    }
    return false;
  }


  @override
  void initState() {
    // var temp = useKalman(widget.trip.trip);
    // var temp_raw = useKalman(widget.trip.trip_raw);
    _fetchAddress();
    _customMarkers();
    _calculateBounds();
    setState(() {
      // kalmanedPos = temp;
      kalmanedPos = widget.trip.trip;
      // kalmanedPos_raw = temp_raw;
      print("RAW FETCH ::: ${kalmanedPos_raw.length}");
    });
    print("herein ${widget.trip.toJSON()}");
    super.initState();
  }

  List<Marker> returnMarkers(){
    List<Marker> markers = [];

    kalmanedPos.forEach((position) {
      markers.add(Marker(
        markerId: MarkerId('marker_${position.latitude}_${position.longitude}'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.fromBytes(marker!),
      ));
    });
    markers.add(Marker(
        markerId: MarkerId('startx'),
        position: LatLng(
            kalmanedPos[0].latitude, kalmanedPos[0].longitude),
        icon: BitmapDescriptor.fromBytes(smallimg!),
        infoWindow: InfoWindow(
            title: 'A : Fused Trip Started',
            snippet:
            '${startLoc}\n${DateFormat("HH:mm").format(widget.trip.trip[0].timestamp.toLocal())}'),
        onTap: () {
          final CameraUpdate cameraUpdate =
          CameraUpdate.newLatLngZoom(
              LatLng(kalmanedPos[0].latitude,
                  kalmanedPos[0].longitude),
              20);
          _controller.animateCamera(cameraUpdate);
        }));
    markers.add(Marker(
        markerId: MarkerId('endx'),
        position: LatLng(
            kalmanedPos[kalmanedPos.length - 1].latitude,
            kalmanedPos[kalmanedPos.length - 1].longitude),
        icon: BitmapDescriptor.fromBytes(endSmallimg!),
        infoWindow: InfoWindow(
            title: 'B : Fused Trip Ended',
            snippet:
            '${endLoc}\n${DateFormat("HH:mm").format(widget.trip.trip[widget.trip.trip.length - 1].timestamp.toLocal())}'),
        onTap: () {
          final CameraUpdate cameraUpdate =
          CameraUpdate.newLatLngZoom(
              LatLng(
                  kalmanedPos[kalmanedPos.length - 1].latitude,
                  kalmanedPos[kalmanedPos.length - 1]
                      .longitude),
              20);
          _controller.animateCamera(cameraUpdate);
        }));
    print("FUSED MARKERS :::: ${markers.length}");
    return markers;
  }

  List<Marker> returnMarkers_raw() {
    List<Marker> markers = [];

    // Ensure each position is added to the markers list
    widget.trip.trip_raw.forEach((position) {
      markers.add(Marker(
        markerId: MarkerId('marker_${position.latitude}_${position.longitude}'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.fromBytes(marker_raw!),
      ));
    });

    // Add the start marker
    markers.add(Marker(
        markerId: MarkerId('startx'),
        position: LatLng(
            widget.trip.trip_raw[0].latitude, widget.trip.trip_raw[0].longitude),
        icon: BitmapDescriptor.fromBytes(smallimg!),
        infoWindow: InfoWindow(
            title: 'A : Raw Trip Started',
            snippet:
            '${startLoc}\n${DateFormat("HH:mm").format(widget.trip.trip[0].timestamp.toLocal())}'
        ),
        onTap: () {
          final CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(
              LatLng(widget.trip.trip_raw[0].latitude, widget.trip.trip_raw[0].longitude), 20);
          _controller.animateCamera(cameraUpdate);
        }
    ));

    // Add the end marker
    markers.add(Marker(
        markerId: MarkerId('endx'),
        position: LatLng(
            widget.trip.trip_raw[widget.trip.trip_raw.length - 1].latitude,
            widget.trip.trip_raw[widget.trip.trip_raw.length - 1].longitude),
        icon: BitmapDescriptor.fromBytes(endSmallimg!),
        infoWindow: InfoWindow(
            title: 'B : Raw Trip Ended',
            snippet:
            '${endLoc}\n${DateFormat("HH:mm").format(widget.trip.trip[widget.trip.trip.length - 1].timestamp.toLocal())}'
        ),
        onTap: () {
          final CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(
              LatLng(
                  widget.trip.trip_raw[widget.trip.trip_raw.length - 1].latitude,
                  widget.trip.trip_raw[widget.trip.trip_raw.length - 1].longitude),
              20);
          _controller.animateCamera(cameraUpdate);
        }
    ));

    print("RAW MARKERS :::: ${markers.length}");
    return markers;
  }

  List<Marker> clearMarkers(){
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F1F1),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Beacon Test v4.4.1",
          style: TextStyle(
              fontWeight: FontWeight.w500, fontSize: 25, color: Colors.black87),
        ),
        // automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.7),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white),
          child: Column(
            children: [
             SizedBox(
               height: 10,
             ),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  expansionAnimationStyle: AnimationStyle(curve: Curves.ease,duration: Duration(milliseconds: 450)),
                  visualDensity: VisualDensity(vertical: -4),
                  tilePadding: EdgeInsets.only(right: 10),
                  title:   Padding(
                    padding: const EdgeInsets.only( left: 20),
                    child: Row(
                      children: [
                        Text(
                          "Trip Details",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 22,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  children: [
                    Column(
                    children: [
                      Divider(color: Colors.black, thickness: 0.7, endIndent: 15, indent: 15,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0,top: 8),
                            child: Row(
                              children: [
                                Text(
                                  ' Start : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${DateFormat("dd MMM yyyy HH:mm").format(widget.trip.trip[0].timestamp.toLocal())}",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' End : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${DateFormat("dd MMM yyyy HH:mm").format(widget.trip.trip[widget.trip.trip.length -1].timestamp.toLocal())}",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Distance : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${(widget.trip.distance / 1000).toStringAsFixed(2)} km",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Time : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${(widget.trip.time.inMinutes ~/ 60) < 10 ? '0' : ''}${(widget.trip.time.inMinutes ~/ 60)}:${(widget.trip.time.inMinutes % 60) < 10 ? '0' : ''}${(widget.trip.time.inMinutes % 60)} hours",
                                  style: TextStyle(fontSize: 18)
                              )
                          ),
                        ],
                      ),
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Beacon Mac Address : ',
                                  style: TextStyle(fontSize: 18),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Padding(
                                padding:
                                const EdgeInsets.only(left: 6.0, right: 16.0),
                                child: Text(
                                    "${widget.trip.macAddress}",
                                    style: TextStyle(fontSize: 18)
                                )
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Beacon Start Battery : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.beaconBatteryStart} %",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Beacon End Battery : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.beaconBatteryEnd} %",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Beacon Battery Consumption : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.beaconBatteryStart - widget.trip.beaconBatteryEnd} %",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Phone Start Battery : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.deviceBatteryStart} %",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Phone End Battery : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.deviceBatteryEnd} %",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Phone Battery Consumption : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.deviceBatteryStart - widget.trip.deviceBatteryEnd} %",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Divider(color: Colors.black, thickness: 0.7, endIndent: 15, indent: 15,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' RSSI Coverage : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.rssiCoverage.toStringAsFixed(2)} %",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Trip Status : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.tripStatus? "Valid" : "Invalid"}",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 10.0, right: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  ' Trip Stop Reason : ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding:
                              const EdgeInsets.only(left: 6.0, right: 16.0),
                              child: Text(
                                  "${widget.trip.tripStopReason == 1? "Vehicle stopped" : "Away from Beacon"}",
                                  // "${widget.trip.tripStopReason}",
                                  style: TextStyle(fontSize: 18)
                              )
                          )
                        ],
                      ),

                      /// DIFF

                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Padding(
                      //       padding:
                      //       const EdgeInsets.only(left: 10.0, right: 6.0),
                      //       child: Row(
                      //         children: [
                      //           Text(
                      //             '1-vehicleStop 0-beaconAway 3-bluetoothOff 4-locationOf 5-otherpermssion 6-turnedOff',
                      //             style: TextStyle(fontSize: 18),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ],
                      // ),

                    ],
                  ),
                  ],
                ),
              ),
              Divider(color: Colors.black, thickness: 0.8, endIndent: 15, indent: 15,),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceAround,
              //   children: [
              //     Row(
              //       children: [
              //         Checkbox(
              //           value: isRawTripChecked,
              //           onChanged: (bool? newValue) {
              //             setState(() {
              //               isRawTripChecked = newValue ?? false;
              //             });
              //             setState(() {
              //               allMarkers = clearMarkers();
              //             });
              //             if(isRawTripChecked && widget.trip.trip_raw.isNotEmpty){
              //               setState(() {
              //                 allMarkers.addAll(returnMarkers_raw());
              //               });
              //             }
              //             if(isFusedTripChecked && kalmanedPos.isNotEmpty){
              //               setState(() {
              //                 allMarkers.addAll(returnMarkers());
              //               });
              //             }
              //           },
              //         ),
              //         Text('Raw Trip'),
              //       ],
              //     ),
              //     Row(
              //       children: [
              //         Checkbox(
              //           value: isFusedTripChecked,
              //           onChanged: (bool? newValue) {
              //             setState(() {
              //               isFusedTripChecked = newValue ?? false;
              //             });
              //             setState(() {
              //               allMarkers = clearMarkers();
              //             });
              //             if(isRawTripChecked && widget.trip.trip_raw.isNotEmpty){
              //               setState(() {
              //                 allMarkers.addAll(returnMarkers_raw());
              //               });
              //             }
              //             if(isFusedTripChecked && kalmanedPos.isNotEmpty){
              //               setState(() {
              //                 allMarkers.addAll(returnMarkers());
              //               });
              //             }
              //           },
              //         ),
              //         Text('Fused Trip'),
              //       ],
              //     ),
              //   ],
              // ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0, top: 4.0),
                  child: GoogleMap(
                    mapType: MapType.satellite,
                    onMapCreated: (controller) {
                      _controller = controller;
                      _setMapBounds();
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.trip.trip.first.latitude,
                          widget.trip.trip.first.longitude),
                      zoom: 18,
                    ),
                    // polylines: Set<Polyline>.of([
                    //   // if (showRawRoute)
                    //   // Polyline(
                    //   //   polylineId: PolylineId('route_raw'),
                    //   //   points: widget.trip.trip
                    //   //       .map((position) =>
                    //   //       LatLng(position.latitude, position.longitude))
                    //   //       .toList(),
                    //   //   color: Colors.blue,
                    //   //   width: 10,
                    //   // ),
                    //   // if (showAccuracyCheckRoute)
                    //   // Polyline(
                    //   //   polylineId: PolylineId('route_acjc'),
                    //   //   points: widget.trip.trip
                    //   //       .where((position) => position.accuracy < 10)
                    //   //       .map((position) =>
                    //   //       LatLng(position.latitude, position.longitude))
                    //   //       .toList(),
                    //   //   color: Colors.deepOrange,
                    //   //   width: 5,
                    //   // ),
                    //   if (showKalmanRoute)
                    //     Polyline(
                    //       polylineId: PolylineId('route_kal'),
                    //       points: kalmanedPos
                    //           .map((position) =>
                    //           LatLng(position.latitude, position.longitude))
                    //           .toList(),
                    //       // color: kalmanedPos.any((position) => isBadRssi(position)) ? Colors.orange: Colors.indigo,
                    //       color: kalmanedPos.any((position) => isBadRssi(position)) ? Colors.orange: Colors.indigo,
                    //       width: 5,
                    //     ),
                    // ]),
                    polylines: Set<Polyline>.of([
                        // if(isRawTripChecked && widget.trip.trip_raw.isNotEmpty)
                        //   Polyline(
                        //     polylineId: PolylineId('route_raw'),
                        //     points: widget.trip.trip_raw
                        //         .map((position) =>
                        //         LatLng(position.latitude, position.longitude))
                        //         .toList(),
                        //     color: Colors.yellow,
                        //     width: 5,
                        //   ),
                        if(isFusedTripChecked && kalmanedPos.isNotEmpty)
                          ...createColoredPolylines(kalmanedPos),
                    ]),
                    markers: Set<Marker>.of(
                      allMarkers
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
