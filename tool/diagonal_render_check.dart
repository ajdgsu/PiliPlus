import 'dart:math' as math;

import 'package:PiliPlus/plugin/pl_player/utils/diagonal_render.dart';
import 'package:flutter/widgets.dart' show BoxFit, Size;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(DiagonalRenderGeometryCache.resetForTest);

  test('calculates the short diagonal angle for foldable screen sizes', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );

    expect(geometry.baseAngleDegrees, closeTo(42.19, 0.01));
    expect(
      geometry.baseAngleForViewport(const Size(2248, 2480)) * 180 / math.pi,
      closeTo(47.81, 0.01),
    );
    expect(
      geometry.baseAngleForViewport(const Size(2480, 2248)) * 180 / math.pi,
      closeTo(42.19, 0.01),
    );
    expect(geometry.overscanScale, closeTo(1.4818, 0.0001));
    expect(geometry.underscanScale, closeTo(0.6748, 0.0001));
  });

  test('skips rotation when screen long ratio already fits the video', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2520, 1080),
    );

    final plan = geometry.planFor(
      viewportSize: const Size(2520, 1080),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 50,
    );

    expect(plan, isNull);
  });

  test('keeps arbitrary horizontal and vertical video ratios eligible', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );

    for (final ratio in [16 / 9, 21 / 9, 3 / 4, 9 / 16, 4 / 3]) {
      final plan = geometry.planFor(
        viewportSize: const Size(2248, 2480),
        videoAspectRatio: ratio,
        fit: BoxFit.contain,
        clockwise: true,
        angleOffsetDegrees: 0,
        scaleSliderValue: 50,
      );
      expect(plan, isNotNull);
    }
  });

  test('interpolates video-aware scale slider linearly', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );
    final plan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 50,
    )!;

    expect(plan.underscanScale, closeTo(0.8759, 0.0001));
    expect(plan.overscanScale, closeTo(2.3401, 0.0001));
    expect(
      plan.scale,
      closeTo((plan.underscanScale + plan.overscanScale) / 2, 0.0001),
    );
  });

  test('balances the render angle while preserving diagonal screen gain', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );

    final plan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 50,
    )!;
    final noCropPlan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 0,
    )!;

    expect(plan.baseAngleDegrees, closeTo(42.19, 0.01));
    expect(plan.balancedAngleDegrees, closeTo(35.04, 0.01));
    expect(
      _diagonalGain(
        const Size(2480, 2248),
        plan.balancedAngleRadians,
      ),
      greaterThanOrEqualTo(0.97),
    );
    expect(noCropPlan.balancedAngleRadians, noCropPlan.baseAngleRadians);
  });

  test('mirrors the balanced angle across device orientations', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );

    final landscapePlan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 50,
    )!;
    final portraitPlan = geometry.planFor(
      viewportSize: const Size(2248, 2480),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 50,
    )!;

    expect(
      landscapePlan.balancedAngleDegrees + portraitPlan.balancedAngleDegrees,
      closeTo(90, 0.01),
    );
  });

  test('caps interface scale so the rotated UI stays inside the viewport', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );
    final plan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 50,
    )!;

    expect(plan.scale, greaterThan(plan.maxInterfaceScale));
    expect(plan.interfaceScale, plan.maxInterfaceScale);
    expect(plan.maxInterfaceScale, closeTo(0.6886, 0.0001));
  });

  test('keeps interface scale aligned with video when it is already safe', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );
    final plan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.cover,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 0,
    )!;

    expect(plan.scale, lessThan(plan.maxInterfaceScale));
    expect(plan.interfaceScale, plan.scale);
  });

  test('angle offset changes rotation but not scale', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );

    final basePlan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 50,
    )!;
    final offsetPlan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 10,
      scaleSliderValue: 50,
    )!;

    expect(offsetPlan.scale, basePlan.scale);
    expect(offsetPlan.maxInterfaceScale, isNot(basePlan.maxInterfaceScale));
    expect(
      offsetPlan.rotationRadians - basePlan.rotationRadians,
      closeTo(10 * 3.141592653589793 / 180, 1e-12),
    );
  });

  test('direction only changes rotation sign', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );
    final cwPlan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: true,
      angleOffsetDegrees: 0,
      scaleSliderValue: 75,
    )!;
    final ccwPlan = geometry.planFor(
      viewportSize: const Size(2480, 2248),
      videoAspectRatio: 16 / 9,
      fit: BoxFit.contain,
      clockwise: false,
      angleOffsetDegrees: 0,
      scaleSliderValue: 75,
    )!;

    expect(cwPlan.rotationRadians, closeTo(-ccwPlan.rotationRadians, 1e-12));
    expect(cwPlan.scale, ccwPlan.scale);
  });

  test('cache skips recomputation until screen size changes', () {
    final geometry = DiagonalRenderGeometryCache.resolveForSize(
      const Size(2248, 2480),
    );
    final firstCount = DiagonalRenderGeometryCache.debugComputeCount;
    final portraitAngle = geometry.baseAngleForViewport(const Size(2248, 2480));
    final landscapeAngle = geometry.baseAngleForViewport(
      const Size(2480, 2248),
    );

    DiagonalRenderGeometryCache.resolveForSize(const Size(2480, 2248));
    expect(DiagonalRenderGeometryCache.debugComputeCount, firstCount);
    expect(portraitAngle, isNot(landscapeAngle));

    DiagonalRenderGeometryCache.resolveForSize(const Size(1080, 2400));
    expect(DiagonalRenderGeometryCache.debugComputeCount, firstCount + 1);
  });
}

double _diagonalGain(Size viewportSize, double angle) {
  final diagonal = math.sqrt(
    viewportSize.width * viewportSize.width +
        viewportSize.height * viewportSize.height,
  );
  final longSide = math.max(viewportSize.width, viewportSize.height);
  final span =
      viewportSize.width * math.cos(angle) +
      viewportSize.height * math.sin(angle);
  return (span - longSide) / (diagonal - longSide);
}
