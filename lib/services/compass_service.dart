import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class CompassData {
  final double heading;
  final bool isPointingAtIsrael;
  final double degreesOff;

  const CompassData({
    required this.heading,
    required this.isPointingAtIsrael,
    required this.degreesOff,
  });
}

class CompassService {
  // Bearing from São Paulo, Brazil to Jerusalem, Israel ≈ 57°
  static const double israelBearing = 57.0;
  static const double tolerance = 25.0;

  // Low-pass filter factor: 0 = no movement, 1 = no smoothing
  static const double _alpha = 0.12;

  static double _smoothed = -1;

  // Singleton broadcast stream — initialized once, shared across rebuilds
  static final Stream<CompassData> stream = _buildStream();

  static Stream<CompassData> _buildStream() {
    return magnetometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).map((event) {
      double raw = atan2(-event.x, event.y) * 180 / pi;
      if (raw < 0) raw += 360;

      if (_smoothed < 0) {
        _smoothed = raw;
      } else {
        // Angular delta normalized to [-180, 180] to handle wrapping correctly
        double delta = raw - _smoothed;
        if (delta > 180) delta -= 360;
        if (delta < -180) delta += 360;
        _smoothed = (_smoothed + _alpha * delta + 360) % 360;
      }

      final diff = _angularDiff(_smoothed, israelBearing);
      return CompassData(
        heading: _smoothed,
        isPointingAtIsrael: diff <= tolerance,
        degreesOff: diff,
      );
    }).asBroadcastStream().handleError((_) => const CompassData(
          heading: 0,
          isPointingAtIsrael: false,
          degreesOff: 999,
        ));
  }

  static double _angularDiff(double a, double b) {
    double diff = (a - b).abs();
    if (diff > 180) diff = 360 - diff;
    return diff;
  }
}
