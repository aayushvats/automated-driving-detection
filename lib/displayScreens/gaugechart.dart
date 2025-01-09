import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';


class GaugeChart extends StatefulWidget {
  const GaugeChart({Key? key}) : super(key: key);

  @override
  State<GaugeChart> createState() => _GaugeChartState();
}

class _GaugeChartState extends State<GaugeChart> {
  double _needleValue = 50;
  double _value = 0 ;

  @override
  void initState() {
    super.initState();
    _animateNeedle();
    counter();
  }

  void _animateNeedle() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _needleValue = 75; // Set the value to animate the needle
      });
    });
  }

  void counter(){
    Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        _value = _value + 1;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Gauge Chart Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              // color: Colors.black12,
              child: AnimatedFlipCounter(
                padding: EdgeInsets.all(15),
                value: _value,
                // prefix: "Level ",
                textStyle: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -8.0,
                  color: Colors.yellow,
                  shadows: [
                    BoxShadow(
                      color: Colors.orange,
                      offset: Offset(8, 8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              // color: Colors.red,
              // width: 500,
              width: MediaQuery.of(context).size.width*0.7,
              // height: MediaQuery.of(context).size.height*0.7,
              child: SfRadialGauge(
                enableLoadingAnimation: true,
                backgroundColor: Colors.white,
                axes: <RadialAxis>[
                  RadialAxis(
                    radiusFactor: 1,
                    showLastLabel: true,
                    // showLabels: true,
                    minimum: 0,
                    maximum: 100,
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: 33,
                        color: Colors.brown,
                        startWidth: 50,
                        endWidth: 50,
                        label: 'BRONZE',
                        labelStyle: GaugeTextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        rangeOffset: -42,
                      ),
                      GaugeRange(
                        startValue: 33,
                        endValue: 66,
                        color: Colors.orange,
                        startWidth: 50,
                        endWidth: 50,
                        label: 'GOLD',
                        labelStyle: GaugeTextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        rangeOffset: -42,
                        // cornerStyle: CornerStyle.bothCurve,
                      ),
                      GaugeRange(
                        startValue: 66,
                        endValue: 100,
                        color: Colors.blue,
                        startWidth: 50,
                        endWidth: 50,
                        label: 'PLATINUM',
                        labelStyle: GaugeTextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        rangeOffset: -42,
                      ),

                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: _needleValue,
                        enableAnimation: true,
                        animationType: AnimationType.ease,
                        animationDuration: 2000,
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Container(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Your Safety Score Rank',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Bronze',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                            ],
                          ),
                        ),
                        angle: 90,
                        positionFactor: 1.3,
                      ),
                      GaugeAnnotation(
                        widget: Container(
                          child: Text(
                            'One point advice',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        angle: 90,
                        positionFactor: 1.7,
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
