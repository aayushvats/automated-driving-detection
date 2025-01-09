import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PairBeacon extends StatefulWidget {
  const PairBeacon({super.key, required this.onPair});

  @override
  State<PairBeacon> createState() => _PairBeaconState();

  final Function(String) onPair;
}

class _PairBeaconState extends State<PairBeacon> {

  TextEditingController macController = TextEditingController();
  bool isSearchByText = false;
  bool isSearching = false;
  late MobileScannerController cameraController;

  List<String?> found = [];

  List<Barcode> barcodes = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    cameraController = MobileScannerController(); // Initialize in initState
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: (){
                  Navigator.pop(context);
                },
                  child: Icon(Icons.close_rounded, color: Colors.black54)),
            ],
          ),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 5.0),
                  child: Text(
                    'Pair your Beacon',
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 25,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Divider(
                  indent: 15,
                  endIndent: 15,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 5.0, right: 10, left: 10),
                  child: Text(
                    'Please Enter The MAC Address available on your Beacon Device:',
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: macController,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(17),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9]')),
                          ],
                          onTapOutside: (event){
                            setState(() {
                              isSearchByText = false;
                              FocusManager.instance.primaryFocus?.unfocus();
                            });
                          },

                          decoration: InputDecoration(
                              filled: true,
                              isDense: true,
                              fillColor: Colors.white54,
                              labelText: "MAC Address",
                              hintText: "Enter MAC Address",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                  borderSide: BorderSide(
                                      width: 1.5,
                                      color: Colors.indigo.shade600))
                            // ),
                          ),
                          onChanged: (val) {
                            val = val.toUpperCase();
                            macController.text =
                                formatString(unformatString(val));
                          },
                          // autofocus: true,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please enter Mac Address";
                            }
                            if(value.length != 17){
                              return 'Enter valid Mac Address';
                            }
                            return null;

                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if(_formKey.currentState!.validate()) {
                            SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                            prefs.setString('macAddress', macController.text);
                            // Navigator.of(context).pushReplacement(
                            //     new MaterialPageRoute(builder: (context) => new HomePage()));
                            widget.onPair(macController.text);
                            final service = await FlutterBackgroundService();
                            service.invoke("SearchMacAddress",
                                {'macAddressKey': macController.text});

                            Navigator.pop(context);
                          }
                        },
                        icon: Icon(Icons.send),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
                  child: Row(
                    children: [
                      Flexible(flex: 1, child:
                      Container(
                        height: 1.2,
                        color: Colors.grey.shade400,
                      ),),
                      Text('  OR  '),
                      Flexible(flex: 1, child:
                      Container(
                        height: 1.2,
                        color: Colors.grey.shade400,
                      ),),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 5.0, right: 10, left: 10),
                  child: Text(
                    'Scan the QR Code on the Beacon by the following button',
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  child: (isSearching)?Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width-40,
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: cameraController,
                            onDetect: (capture) {
                              setState(() {
                                barcodes = capture.barcodes;
                              });
                              for (final barcode in barcodes) {
                                debugPrint('${barcode.rawValue}');
                              }
                            },
                          ),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                      onTap: (){
                                        setState(() {
                                          isSearching = false;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Icon(Icons.close, color: Colors.white,),
                                      ))
                                ],
                              ),
                              Expanded(child: Container()),
                              SizedBox(
                                height: 85,
                                child: barcodes.isNotEmpty
                                    ? ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: barcodes.length,
                                    itemBuilder: (context, int index) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 19, horizontal: 10),
                                        child: InkWell(
                                          onTap: () async {
                                            SharedPreferences prefs =
                                            await SharedPreferences.getInstance();
                                            prefs.setString('macAddress', formatString(barcodes[index].rawValue!));
                                            widget.onPair(formatString(barcodes[index].rawValue!));
                                            // Navigator.of(context).pushReplacement(
                                            //     new MaterialPageRoute(builder: (context) => new HomePage()));
                                            final service = await FlutterBackgroundService();
                                            service.invoke("SearchMacAddress",
                                                {'macAddressKey': formatString(barcodes[index].rawValue!)});
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.indigo,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Text(
                                                  barcodes[index].rawValue!,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 19,
                                                      fontWeight: FontWeight.w400),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                    : const Text(
                                  "No code found",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ):InkWell(
                    onTap: (){
                      setState(() {
                        isSearching = true;
                      });
                    },
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20,)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
