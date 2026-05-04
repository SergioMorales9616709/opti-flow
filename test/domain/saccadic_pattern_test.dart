import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optiflow/features/vision_training/domain/saccadic_pattern.dart';

void main() {
  group('SaccadicPattern.sequence', () {
    test('horizontal has 6 positions', () {
      expect(SaccadicPattern.horizontal.sequence.length, 6);
    });

    test('horizontal converges wide to narrow', () {
      final seq = SaccadicPattern.horizontal.sequence;
      expect(seq[0], const Alignment(-0.88, 0));
      expect(seq[1], const Alignment(0.88, 0));
      expect(seq[2], const Alignment(-0.44, 0));
      expect(seq[3], const Alignment(0.44, 0));
      expect(seq[4], const Alignment(-0.22, 0));
      expect(seq[5], const Alignment(0.22, 0));
    });

    test('vertical has 6 positions', () {
      expect(SaccadicPattern.vertical.sequence.length, 6);
    });

    test('vertical converges wide to narrow', () {
      final seq = SaccadicPattern.vertical.sequence;
      expect(seq[0], const Alignment(0, -0.88));
      expect(seq[1], const Alignment(0, 0.88));
      expect(seq[2], const Alignment(0, -0.44));
      expect(seq[3], const Alignment(0, 0.44));
      expect(seq[4], const Alignment(0, -0.22));
      expect(seq[5], const Alignment(0, 0.22));
    });

    test('zPattern has 4 positions', () {
      expect(SaccadicPattern.zPattern.sequence.length, 4);
    });

    test(
      'zPattern follows top-left, top-right, bottom-left, bottom-right order',
      () {
        final seq = SaccadicPattern.zPattern.sequence;
        expect(seq[0], const Alignment(-0.88, -0.88));
        expect(seq[1], const Alignment(0.88, -0.88));
        expect(seq[2], const Alignment(-0.88, 0.88));
        expect(seq[3], const Alignment(0.88, 0.88));
      },
    );

    test('nPattern has 4 positions', () {
      expect(SaccadicPattern.nPattern.sequence.length, 4);
    });

    test(
      'nPattern follows top-left, bottom-left, top-right, bottom-right order',
      () {
        final seq = SaccadicPattern.nPattern.sequence;
        expect(seq[0], const Alignment(-0.88, -0.88));
        expect(seq[1], const Alignment(-0.88, 0.88));
        expect(seq[2], const Alignment(0.88, -0.88));
        expect(seq[3], const Alignment(0.88, 0.88));
      },
    );

    test('crossPattern has 12 positions', () {
      expect(SaccadicPattern.crossPattern.sequence.length, 12);
    });

    test('crossPattern converges on vertical axis then horizontal axis', () {
      final seq = SaccadicPattern.crossPattern.sequence;
      // vertical axis: wide → mid → narrow
      expect(seq[0], const Alignment(0, -0.88));
      expect(seq[1], const Alignment(0, 0.88));
      expect(seq[2], const Alignment(0, -0.44));
      expect(seq[3], const Alignment(0, 0.44));
      expect(seq[4], const Alignment(0, -0.22));
      expect(seq[5], const Alignment(0, 0.22));
      // horizontal axis: wide → mid → narrow
      expect(seq[6], const Alignment(-0.88, 0));
      expect(seq[7], const Alignment(0.88, 0));
      expect(seq[8], const Alignment(-0.44, 0));
      expect(seq[9], const Alignment(0.44, 0));
      expect(seq[10], const Alignment(-0.22, 0));
      expect(seq[11], const Alignment(0.22, 0));
    });

    test('xPattern has 12 positions', () {
      expect(SaccadicPattern.xPattern.sequence.length, 12);
    });

    test('xPattern converges on diagonal 1 then diagonal 2', () {
      final seq = SaccadicPattern.xPattern.sequence;
      // diagonal 1: wide → mid → narrow
      expect(seq[0], const Alignment(-0.88, -0.88));
      expect(seq[1], const Alignment(0.88, 0.88));
      expect(seq[2], const Alignment(-0.44, -0.44));
      expect(seq[3], const Alignment(0.44, 0.44));
      expect(seq[4], const Alignment(-0.22, -0.22));
      expect(seq[5], const Alignment(0.22, 0.22));
      // diagonal 2: wide → mid → narrow
      expect(seq[6], const Alignment(0.88, -0.88));
      expect(seq[7], const Alignment(-0.88, 0.88));
      expect(seq[8], const Alignment(0.44, -0.44));
      expect(seq[9], const Alignment(-0.44, 0.44));
      expect(seq[10], const Alignment(0.22, -0.22));
      expect(seq[11], const Alignment(-0.22, 0.22));
    });
  });

  group('SaccadicPattern.label', () {
    test('horizontal label is Horizontal', () {
      expect(SaccadicPattern.horizontal.label, 'Horizontal');
    });

    test('vertical label is Vertical', () {
      expect(SaccadicPattern.vertical.label, 'Vertical');
    });

    test('zPattern label is Patrón Z', () {
      expect(SaccadicPattern.zPattern.label, 'Patrón Z');
    });

    test('nPattern label is Patrón N', () {
      expect(SaccadicPattern.nPattern.label, 'Patrón N');
    });

    test('crossPattern label is Cruz', () {
      expect(SaccadicPattern.crossPattern.label, 'Cruz');
    });

    test('xPattern label is Diagonal X', () {
      expect(SaccadicPattern.xPattern.label, 'Diagonal X');
    });
  });
}
