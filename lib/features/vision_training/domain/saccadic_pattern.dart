import 'package:flutter/material.dart';

enum SaccadicPattern {
  horizontal,
  vertical,
  zPattern,
  nPattern,
  crossPattern,
  xPattern;

  List<Alignment> get sequence => switch (this) {
    SaccadicPattern.horizontal => [
      const Alignment(-0.88, 0),
      const Alignment(0.88, 0),
      const Alignment(-0.44, 0),
      const Alignment(0.44, 0),
      const Alignment(-0.22, 0),
      const Alignment(0.22, 0),
    ],
    SaccadicPattern.vertical => [
      const Alignment(0, -0.88),
      const Alignment(0, 0.88),
      const Alignment(0, -0.44),
      const Alignment(0, 0.44),
      const Alignment(0, -0.22),
      const Alignment(0, 0.22),
    ],
    SaccadicPattern.zPattern => [
      const Alignment(-0.88, -0.88),
      const Alignment(0.88, -0.88),
      const Alignment(-0.88, 0.88),
      const Alignment(0.88, 0.88),
    ],
    SaccadicPattern.nPattern => [
      const Alignment(-0.88, -0.88),
      const Alignment(-0.88, 0.88),
      const Alignment(0.88, -0.88),
      const Alignment(0.88, 0.88),
    ],
    SaccadicPattern.crossPattern => [
      const Alignment(0, -0.88), // 1  top extreme
      const Alignment(0, 0.88), // 2  bottom extreme
      const Alignment(0, -0.44), // 3  mid top
      const Alignment(0, 0.44), // 4  mid bottom
      const Alignment(0, -0.22), // 5  near-center top
      const Alignment(0, 0.22), // 6  near-center bottom
      const Alignment(-0.88, 0), // 7  left extreme
      const Alignment(0.88, 0), // 8  right extreme
      const Alignment(-0.44, 0), // 9  mid left
      const Alignment(0.44, 0), // 10 mid right
      const Alignment(-0.22, 0), // 11 near-center left
      const Alignment(0.22, 0), // 12 near-center right
    ],
    SaccadicPattern.xPattern => [
      const Alignment(-0.88, -0.88), // 1  top-left extreme
      const Alignment(0.88, 0.88), // 2  bottom-right extreme
      const Alignment(-0.44, -0.44), // 3  mid top-left
      const Alignment(0.44, 0.44), // 4  mid bottom-right
      const Alignment(-0.22, -0.22), // 5  near-center top-left
      const Alignment(0.22, 0.22), // 6  near-center bottom-right
      const Alignment(0.88, -0.88), // 7  top-right extreme
      const Alignment(-0.88, 0.88), // 8  bottom-left extreme
      const Alignment(0.44, -0.44), // 9  mid top-right
      const Alignment(-0.44, 0.44), // 10 mid bottom-left
      const Alignment(0.22, -0.22), // 11 near-center top-right
      const Alignment(-0.22, 0.22), // 12 near-center bottom-left
    ],
  };

  String get label => switch (this) {
    SaccadicPattern.horizontal => 'Horizontal',
    SaccadicPattern.vertical => 'Vertical',
    SaccadicPattern.zPattern => 'Patrón Z',
    SaccadicPattern.nPattern => 'Patrón N',
    SaccadicPattern.crossPattern => 'Cruz',
    SaccadicPattern.xPattern => 'Diagonal X',
  };
}
