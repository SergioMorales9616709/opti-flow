import 'dart:math' as math;

enum PursuitPattern {
  circle,
  infinity,
  horizontalBounce;

  /// Returns (x, y) in [-1, 1] for a given animation value [t] in [0, 2π].
  (double, double) position(double t) => switch (this) {
    PursuitPattern.circle => (math.cos(t), math.sin(t)),
    PursuitPattern.infinity => (math.sin(t), math.sin(2 * t) / 2),
    PursuitPattern.horizontalBounce => (math.sin(t), 0.0),
  };

  String get label => switch (this) {
    PursuitPattern.circle => 'Círculo',
    PursuitPattern.infinity => 'Infinito',
    PursuitPattern.horizontalBounce => 'Horizontal',
  };
}
