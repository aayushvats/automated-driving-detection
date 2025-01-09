// import 'package:app_settings/app_settings.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

class PermissionAlert extends StatefulWidget {
  PermissionAlert({super.key, required this.isLoc, required this.isBlu, required this.isNot, required this.onPermissionsGiven, required this.isAct, required this.isBat});
  final bool isLoc;
  final bool isBlu;
  final bool isNot;
  final bool isAct;
  final bool isBat;

  final Function(bool) onPermissionsGiven;

  @override
  State<PermissionAlert> createState() => _PermissionAlertState();
}

class _PermissionAlertState extends State<PermissionAlert> {

  final GlobalKey<State> _dialogKey = GlobalKey<State>();

  bool _isLoc = false;
  bool _isBlu = false;
  bool _isNot = false;
  bool _isAct = false;
  bool _isBat = false;
  late SharedPreferences prefs;

  @override
  void initState() {
    initPrefs();
    setState(() {
      _isLoc = widget.isLoc;
      _isBlu = widget.isBlu;
      _isNot = widget.isNot;
      _isAct = widget.isAct;
      _isBat = widget.isBat;
    });
    super.initState();
  }

  initPrefs() async {
    var val = await SharedPreferences.getInstance();
    setState(() {
      prefs = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: _dialogKey,
        title: Text('Alert!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('The following permissions are required for this App to work efficiently.'),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: false,
              visualDensity: VisualDensity(vertical: -4),
              title: Text('GPS Location Permission', style: TextStyle(color: _isLoc?CupertinoColors.black:Colors.grey.shade600),),
              trailing: Icon(_isLoc?Icons.check_circle:Icons.my_location_rounded, color: _isLoc?CupertinoColors.systemGreen:Colors.grey.shade600,),
              onTap: _isLoc?null:() async {
                await Permission.location.request();
                // await Permission.locationAlways.request();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return PopScope(
                        canPop: false,
                        child: AlertDialog(
                          title: Text("Always allow Location"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('For this app to work even when it is not open, allow access to device location always.'),
                              Divider(),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Step 1: Click on Permissions', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                                      Image.asset('assets/images/Loc-Step-1.png'),
                                      Text('Step 2: Click on Location', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                                      Image.asset('assets/images/Loc-Step-2.png'),
                                      Text('Step 3: Allow all the time', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                                      Image.asset('assets/images/Loc-Step-3.png'),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 12.0, bottom: 6.0, left: 12.0, right: 6.0),
                                      child: InkWell(
                                        onTap: () async {
                                            await openAppSettings();
                                            if(await Permission.location.isGranted){
                                              setState(() {
                                                _isLoc = true;
                                              });
                                              if(_isLoc && _isBlu && _isNot && _isAct && _isBat){
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                                widget.onPermissionsGiven(true);
                                              }
                                            }
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
                                                  "Open App Settings",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            )),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 12.0, bottom: 6.0, left: 12.0, right: 6.0),
                                    child: InkWell(
                                      onTap: () {
                                          Navigator.of(context).pop();
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
                                                "  Done  ",
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          )),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                    );
                  }
                );
                //ToBeDone
              },
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: false,
              visualDensity: VisualDensity(vertical: -4),
              title: Text('Bluetooth Access', style: TextStyle(color: _isBlu?CupertinoColors.black:Colors.grey.shade600),),
              trailing: Icon(_isBlu?Icons.check_circle:Icons.bluetooth_connected_rounded, color: _isBlu?CupertinoColors.systemGreen:Colors.grey.shade600,),
              onTap: _isBlu?null:() async {
                if(Platform.isIOS)
                {
                await Permission.bluetooth.request();
                print("111111111111");
                //openAppSettings();
                if(await Permission.bluetooth.isGranted){
                  setState(() {
                    _isBlu = true;
                  });
                  if(_isLoc && _isBlu && _isNot && _isAct && _isBat){
                    Navigator.of(context).pop();
                    widget.onPermissionsGiven(true);
                  }
                }
              }else if(Platform.isAndroid){
                await Permission.bluetoothScan.request();
                // await Permission.bluetooth.request();
                if(await Permission.bluetoothScan.isGranted){
                  setState(() {
                    _isBlu = true;
                  });
                  if(_isLoc && _isBlu && _isNot && _isAct){
                    Navigator.of(context).pop();
                    widget.onPermissionsGiven(true);
                  }
                }
              }
              },
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: false,
              visualDensity: VisualDensity(vertical: -4),
              title: Text('Push Notifications', style: TextStyle(color: _isNot?CupertinoColors.black:Colors.grey.shade600),),
              trailing: Icon(_isNot?Icons.check_circle:Icons.notifications_none, color: _isNot?CupertinoColors.systemGreen:Colors.grey.shade600,),
              onTap: _isNot?null:() async {
                await Permission.notification.request();
                if(await Permission.notification.isGranted){
                  setState(() {
                    _isNot = true;
                  });
                  if(_isLoc && _isBlu && _isNot && _isAct && _isBat){
                    Navigator.of(context).pop();
                    widget.onPermissionsGiven(true);
                  }
                }
              },
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: false,
              visualDensity: VisualDensity(vertical: -4),
              title: Text('Disable Hibernation', style: TextStyle(color: _isAct?CupertinoColors.black:Colors.grey.shade600),),
              trailing: Icon(_isAct?Icons.check_circle:Icons.app_settings_alt_rounded, color: _isAct?CupertinoColors.systemGreen:Colors.grey.shade600,),
              onTap: _isAct?null:() async {
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return PopScope(
                          canPop: false,
                          child: AlertDialog(
                            title: Text("Disable Pause Activity if App Unused"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('For this app to work even when it is not open, disable pause activity if app is unused.'),
                                Divider(),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Step 1: Scroll Below to find the Setting', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                                        Image.asset('assets/images/Act-Step-1.png'),
                                        Text('Step 2: Disable the Pause app activity if unused Toggle', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                                        Image.asset('assets/images/Act-Step-2.png'),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 12.0, bottom: 6.0, left: 12.0, right: 6.0),
                                        child: InkWell(
                                          onTap: () async {
                                            setState(() {
                                              _isAct = true;
                                              prefs.setBool("isHibernationDisabled", true);
                                            });
                                            if(_isLoc && _isBlu && _isNot && _isAct && _isBat){
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                              widget.onPermissionsGiven(true);
                                            }
                                            await openAppSettings();
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
                                                    "Open App Settings",
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                              )),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 12.0, bottom: 6.0, left: 12.0, right: 6.0),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context).pop();
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
                                                  "  Done  ",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            )),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                      );
                    }
                );
                //ToBeDone
              },
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: false,
              visualDensity: VisualDensity(vertical: -4),
              title: Text('Disable Battery Optimisation', style: TextStyle(color: _isBat?CupertinoColors.black:Colors.grey.shade600),),
              trailing: Icon(_isBat?Icons.check_circle:Icons.battery_alert_rounded, color: _isBat?CupertinoColors.systemGreen:Colors.grey.shade600,),
              onTap: _isBat?null:() async {
                // await Permission.
                await DisableBatteryOptimization.showDisableAllOptimizationsSettings(
                    "Enable Auto Start",
                    "Follow the steps and enable the auto start of this app",
                    "Your device has additional battery optimization",
                    "Follow the steps and disable the optimizations to allow smooth functioning of this app"
                );
                // await Permission.locationAlways.request();
                // await openAppSettings();
                //ToBeDone
                while(true){
                  if(await DisableBatteryOptimization.isAllBatteryOptimizationDisabled??false){
                    print('in here');
                    setState(() {
                      _isBat = true;
                      prefs.setBool("isBatteryDisabled", true);
                    });
                    if(_isLoc && _isBlu && _isNot && _isAct && _isBat){
                      Navigator.of(context).pop();
                      widget.onPermissionsGiven(true);
                    }
                    break;
                  }else{
                    print('in else');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );;
  }
}
