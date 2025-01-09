import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogicSetting extends StatefulWidget {
  const LogicSetting({super.key});

  @override
  State<LogicSetting> createState() => _LogicSettingState();
}

class _LogicSettingState extends State<LogicSetting>
{
  bool isAuthenticated = false;
  TextEditingController uidController = TextEditingController();
  TextEditingController pwdController = TextEditingController();
  double rssiThreshold = 0.0;
  double gpsSpeedThreshold = 0.0;
  double gpsTimeThreshold = 0.0;
  double stopGpsThreshold = 0.0;
  double tripDistanceThreshold = 0.0;
  double rssiCoverageThreshold = 0.0;
  double sampleFrequency = 0;
  double stopGpsSpeedThreshold = 0;
  double stopBeaconThreshold = 0;
  double beaconSampleFrequencyThreshold = 0;
  double beaconOutOfRangeThreshhold = 0;
  final _formKey = GlobalKey<FormState>();
  final _thresholdFormKey = GlobalKey<FormState>();


  checkAdmin() {
    print("\n.\n.\n.\n.\n.\n.\n.\n.\n. heree123123");
    if(_formKey.currentState!.validate()) {
      if (uidController.text == 'Admin' && pwdController.text == 'Pass@123') {
        print("heree");
        setState(() {
          isAuthenticated = true;
        });
      }
    }
  }

  getThreshold() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("prefs: ${prefs.getDouble("rssiThreshold")}");
    setState(() {
      rssiThreshold = prefs.getDouble("rssiThreshold") ?? 0.0;
      gpsSpeedThreshold = prefs.getDouble("gpsSpeedThreshold") ?? 0.0;
      gpsTimeThreshold = prefs.getDouble("gpsContinuousTimeThreshold") ?? 0.0;
      stopGpsThreshold = prefs.getDouble("stopGpsThreshold") ?? 0.0;
      tripDistanceThreshold = prefs.getDouble("tripDistanceThreshold") ?? 0.0;
      rssiCoverageThreshold = prefs.getDouble("rssiCoverageThreshold") ?? 0.0;
      sampleFrequency = prefs.getDouble("sampleFrequency") ?? 0;
      stopGpsSpeedThreshold = prefs.getDouble("stopGpsSpeedThreshold") ?? 0;
      stopBeaconThreshold = prefs.getDouble("stopBeaconThreshold") ?? 0;
      beaconSampleFrequencyThreshold = prefs.getDouble("beaconSampleFrequencyThreshold") ?? 0;
      beaconOutOfRangeThreshhold = prefs.getDouble("beaconOutOfRangeThreshhold") ?? 0;
    });
  }

  Future<double> setValueModal(double currentValue, String title) async {
    double nextValue = currentValue;
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: Form(
                key: _thresholdFormKey,
                child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                Text(
                  "Set $title :",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextFormField(
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}$')),

                  ],
                  autofocus: true,
                  initialValue: currentValue.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      nextValue = double.parse(val);
                    });
                  },
                  decoration: InputDecoration(
                    errorMaxLines: 3
                  ),

                  validator: (value){
                    if(value!.isEmpty){
                      return 'Please enter $title';
                    }

                    if(title.trim() == "RSSI Value" && !(((double.tryParse(value) ?? 0) <= -1) && ((double.tryParse(value) ?? 0) >= -150))){
                      return "RSSI value should be in range of -1 to -150";
                    }
                    if(title.trim() != "RSSI Value" && (double.tryParse(value) ?? 0) < 0){
                      return "${title.trim()} can't be negative";
                    }
                    if(title.trim() == "RSSI Coverage (%)" && !(((double.tryParse(value) ?? 0) >= 1) && ((double.tryParse(value) ?? 0) <= 100))){
                      return "${title.trim()} should be in range of 1 to 100";
                    }
                    if(title.trim() == "GPS (km/h)" && !(((double.tryParse(value) ?? 0) >= 0) && ((double.tryParse(value) ?? 0) <= 150))){
                      return "${title.trim()} should be in range of 0 to 150";
                    }
                    if(title.trim() == "Continuous Time (sec)" && !(((double.tryParse(value) ?? 0) >= 0) && ((double.tryParse(value) ?? 0) <= 999))){
                      return "${title.trim()} should be in range of 0 to 999";
                    }
                    if(title.trim() == "Stop GPS Duration (min)" && !(((double.tryParse(value) ?? 0) >= 0) && ((double.tryParse(value) ?? 0) <= 20))){
                      return "${title.trim()} should be in range of 0 to 20";
                    }
                    if(title.trim() == "Stop Beacon Duration (min)" && !(((double.tryParse(value) ?? 0) >= 0) && ((double.tryParse(value) ?? 0) <= 360))){
                      return "${title.trim()} should be in range of 0 to 360";
                    }
                    if(title.trim() == "Stop GPS Speed (km/h)" && !(((double.tryParse(value) ?? 0) >= 0) && ((double.tryParse(value) ?? 0) <= 150))){
                      return "${title.trim()} should be in range of 0 to 150";
                    }
                    if(title.trim() == "Total Distance (km)" && !(((double.tryParse(value) ?? 0) >= 0) && ((double.tryParse(value) ?? 0) <= 150))){
                      return "${title.trim()} should be in range of 0 to 150";
                    }
                    if(title.trim() == "Beacon Sample Frequency (sec)" && !(((double.tryParse(value) ?? 0) >= 2) && ((double.tryParse(value) ?? 0) <= 60))){
                      return "${title.trim()} should be in range of 2 to 60";
                    }



                    return null;
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 15.0, right: 15.0, top: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        textStyle: TextStyle(color: Colors.white)),
                    onPressed: () {
                      if(_thresholdFormKey.currentState!.validate())
                      {
                        setState(() {
                          currentValue = nextValue;
                        });
                        Navigator.pop(context);
                      }

                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                            ],
                          ),
              ));
        });
    print("\n\n\n]\ncurent value: ${currentValue}");
    return currentValue;
  }

  void submit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble("rssiThreshold", rssiThreshold);
    prefs.setDouble("gpsSpeedThreshold", gpsSpeedThreshold); // in km/h
    prefs.setDouble("gpsContinuousTimeThreshold", gpsTimeThreshold); // in sec
    prefs.setDouble("stopGpsThreshold", stopGpsThreshold); //in min
    prefs.setDouble("rssiCoverageThreshold", rssiCoverageThreshold); //in %
    prefs.setDouble("tripDistanceThreshold", tripDistanceThreshold); // in km
    prefs.setDouble("sampleFrequency", sampleFrequency); // in km
    prefs.setDouble("stopGpsSpeedThreshold", stopGpsSpeedThreshold); // in km
    prefs.setDouble("stopBeaconThreshold", stopBeaconThreshold); // in km
    prefs.setDouble("beaconSampleFrequencyThreshold", beaconSampleFrequencyThreshold); // in km
    prefs.setDouble("beaconOutOfRangeThreshhold", beaconOutOfRangeThreshhold); // in km

    final service = await FlutterBackgroundService();
    service.invoke("UpdateThreshold", {
      'rssiThreshold': rssiThreshold,
      'gpsSpeedThreshold': gpsSpeedThreshold,
      'gpsTimeThreshold': gpsTimeThreshold,
      'stopGpsThreshold': stopGpsThreshold,
      'rssiCoverageThreshold': rssiCoverageThreshold,
      'tripDistanceThreshold': tripDistanceThreshold,
      'sampleFrequency': sampleFrequency,
      'stopGpsSpeedThreshold': stopGpsSpeedThreshold,
      'stopBeaconThreshold': stopBeaconThreshold,
      'beaconSampleFrequencyThreshold': beaconSampleFrequencyThreshold,
      'beaconOutOfRangeThreshhold': beaconOutOfRangeThreshhold,
    });

    Navigator.pop(context);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getThreshold();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        content: Stack(
      children: [
        isAuthenticated
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Logic Settings',
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: 25,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    // Divider(
                    //   indent: 15,
                    //   endIndent: 15,
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0, bottom: 5.0, right: 10, left: 10),
                      child: Text(
                        'Modify the following values to change the Logic Settings:',
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Divider(
                      indent: 15,
                      endIndent: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0, bottom: 5.0, right: 10, left: 10),
                      child: Text(
                        'Beacon Range in Threshold:',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 5.0, right: 10, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'RSSI Value (dBm):',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var val =
                                  await setValueModal(rssiThreshold, "RSSI Value ");
                              setState(() {
                                rssiThreshold = val;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                "    ${rssiThreshold}    ",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(
                    //       bottom: 5.0, right: 10, left: 10),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Flexible(
                    //         child: Text(
                    //           'Beacon Out Of Range',
                    //           style: TextStyle(
                    //               color: Colors.black87,
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.w500),
                    //         ),
                    //       ),
                    //       InkWell(
                    //         onTap: () async {
                    //           var val =
                    //               await setValueModal(beaconOutOfRangeThreshhold, "Beacon Out Of Range Threshold (sec): ");
                    //           setState(() {
                    //             beaconOutOfRangeThreshhold = val;
                    //           });
                    //         },
                    //         child: Container(
                    //           decoration: BoxDecoration(
                    //               color: Colors.black87,
                    //               borderRadius: BorderRadius.circular(20)),
                    //           child: Text(
                    //             "    ${beaconOutOfRangeThreshhold}    ",
                    //             style: TextStyle(
                    //                 fontSize: 14, color: Colors.white),
                    //           ),
                    //         ),
                    //       )
                    //     ],
                    //   ),
                    // ),

                    // Padding(
                    //   padding: const EdgeInsets.only(
                    //       bottom: 5.0, right: 10, left: 10),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Flexible(
                    //         child: Text(
                    //           'Beacon Sample Frequency (sec):',
                    //           style: TextStyle(
                    //               color: Colors.black87,
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.w500),
                    //         ),
                    //       ),
                    //       InkWell(
                    //         onTap: () async {
                    //           var val =
                    //               await setValueModal(beaconSampleFrequencyThreshold, "Beacon Sample Frequency (sec) ");
                    //           setState(() {
                    //             beaconSampleFrequencyThreshold = val;
                    //           });
                    //         },
                    //         child: Container(
                    //           decoration: BoxDecoration(
                    //               color: Colors.black87,
                    //               borderRadius: BorderRadius.circular(20)),
                    //           child: Text(
                    //             "    ${beaconSampleFrequencyThreshold}    ",
                    //             style: TextStyle(
                    //                 fontSize: 14, color: Colors.white),
                    //           ),
                    //         ),
                    //       )
                    //     ],
                    //   ),
                    // ),
                    // Divider(
                    //   indent: 15,
                    //   endIndent: 15,
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0, bottom: 5.0, right: 10, left: 10),
                      child: Text(
                        'Vehicle Moving Threshold:',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 5.0, right: 10, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'GPS (km/h):',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                              softWrap: true,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var val = await setValueModal(
                                  gpsSpeedThreshold, "GPS (km/h)");
                              setState(() {
                                gpsSpeedThreshold = val;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                "    ${gpsSpeedThreshold}    ",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 5.0, right: 10, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Continuous Time (sec):',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                              softWrap: true,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var val = await setValueModal(
                                  gpsTimeThreshold, "Continuous Time (sec)");
                              setState(() {
                                gpsTimeThreshold = val;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                "    ${gpsTimeThreshold}    ",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      indent: 15,
                      endIndent: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0, bottom: 5.0, right: 10, left: 10),
                      child: Text(
                        'Vehicle Stop Threshold:',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 5.0, right: 10, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Stop GPS Duration (min):',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                              softWrap: true,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var val = await setValueModal(
                                  stopGpsThreshold, "Stop GPS Duration (min)");
                              setState(() {
                                stopGpsThreshold = val;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                "    ${stopGpsThreshold}    ",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 5.0, right: 10, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Stop Beacon Duration (min):',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                              softWrap: true,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var val = await setValueModal(
                                  stopBeaconThreshold, "Stop Beacon Duration (min)");
                              setState(() {
                                stopBeaconThreshold = val;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                "    ${stopBeaconThreshold}    ",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 5.0, right: 10, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Stop GPS Speed (km/h):',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                              softWrap: true,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var val = await setValueModal(stopGpsSpeedThreshold,
                                  "Stop GPS Speed (km/h)");
                              setState(() {
                                stopGpsSpeedThreshold = val;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                "    ${stopGpsSpeedThreshold}    ",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      indent: 15,
                      endIndent: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0, bottom: 5.0, right: 10, left: 10),
                      child: Text(
                        'Trip Threshold:',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 5.0, right: 10, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Total Distance (km):',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                              softWrap: true,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var val = await setValueModal(tripDistanceThreshold,
                                  "Total Distance (km):");
                              setState(() {
                                tripDistanceThreshold = val;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                "    ${tripDistanceThreshold}    ",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 5.0, right: 10, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'RSSI Coverage (%):',
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                              softWrap: true,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              var val = await setValueModal(
                                  rssiCoverageThreshold, "RSSI Coverage (%)");
                              setState(() {
                                rssiCoverageThreshold = val;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                "    ${rssiCoverageThreshold}    ",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Divider(
                    //   indent: 15,
                    //   endIndent: 15,
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.only(
                    //       top: 8.0, bottom: 5.0, right: 10, left: 10),
                    //   child: Text(
                    //     'Trip Frequency:',
                    //     style: TextStyle(
                    //         color: Colors.black,
                    //         fontSize: 18,
                    //         fontWeight: FontWeight.w700),
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.only(
                    //       bottom: 5.0, right: 10, left: 10),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Flexible(
                    //         child: Text(
                    //           'GPS Sample Frequency',
                    //           style: TextStyle(
                    //               color: Colors.black87,
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.w500),
                    //           softWrap: true,
                    //         ),
                    //       ),
                    //       InkWell(
                    //         onTap: () async {
                    //           var val = await setValueModal(sampleFrequency,
                    //               "GPS Sample Frequency:");
                    //           setState(() {
                    //             sampleFrequency = val;
                    //           });
                    //         },
                    //         child: Container(
                    //           decoration: BoxDecoration(
                    //               color: Colors.black87,
                    //               borderRadius: BorderRadius.circular(20)),
                    //           child: Text(
                    //             "    ${sampleFrequency}    ",
                    //             style: TextStyle(
                    //                 fontSize: 14, color: Colors.white),
                    //           ),
                    //         ),
                    //       )
                    //     ],
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 15.0, right: 15.0, top: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () {
                          submit();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Form(
          key: _formKey,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 5.0),
                      child: Text(
                        '\nAuthenticate to modify Logic Settings:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Divider(
                      indent: 15,
                      endIndent: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: uidController,
                              keyboardType: TextInputType.text,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(17),
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9]')),
                              ],
                              onTapOutside: (event) {
                                setState(() {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                });
                              },
                              validator: (val) {
                                if (uidController.text.isEmpty) {
                                  return '*Please enter Admin ID';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                  filled: true,
                                  isDense: true,
                                  fillColor: Colors.white54,
                                  labelText: "Admin ID",
                                  hintText: "Enter Admin ID",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                      borderSide: BorderSide(
                                          width: 1.5,
                                          color: Colors.indigo.shade600))),
                              onChanged: (val) {
                                uidController.text = val;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: pwdController,
                              obscureText: true,
                              obscuringCharacter: '●',
                              keyboardType: TextInputType.text,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(17),
                                // FilteringTextInputFormatter.allow(
                                //     RegExp(r'[a-zA-Z0-9]')),
                              ],
                              onTapOutside: (event) {
                                setState(() {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                });
                              },
                              validator: (val) {
                                if (pwdController.text.isEmpty) {
                                  return '*Please enter password';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                  filled: true,
                                  isDense: true,
                                  fillColor: Colors.white54,
                                  labelText: "Password",
                                  hintText: "Enter Password",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                      borderSide: BorderSide(
                                          width: 1.5,
                                          color: Colors.indigo.shade600))),
                              onChanged: (val) {
                                pwdController.text = val;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                        visible: uidController.text.isNotEmpty &&
                            pwdController.text.isNotEmpty &&
                            !isAuthenticated,
                        child: Text(
                          "Invalid Username or Password",
                          style: TextStyle(color: Colors.red),
                        )),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 15.0, right: 15.0, top: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () {
                          checkAdmin();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.close_rounded, color: Colors.black54)),
          ],
        ),
      ],
    ));
  }
}
