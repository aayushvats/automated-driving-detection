import 'dart:math';

class KalmanFilter {
  late double latitude;
  late double longitude;
  late double variance;
  double minAccuracy;

  KalmanFilter({this.minAccuracy = 1}) {
    variance = -1;
  }

  List<double> process(double lat, double lng, double accuracy) {
    if (accuracy < minAccuracy) accuracy = minAccuracy;

    if (variance < 0) {
      latitude = lat;
      longitude = lng;
      variance = accuracy * accuracy;
    } else {
      final timeIncMs = 500; // Assuming fixed interval of 500ms

      variance += (timeIncMs * 3 * 3) / 1000;

      final _k = variance / (variance + (accuracy * accuracy));
      latitude += _k * (lat - latitude);
      longitude += _k * (lng - longitude);

      variance = (1 - _k) * variance;
    }

    return [longitude, latitude];
  }
}
