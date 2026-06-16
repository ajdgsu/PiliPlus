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

    expect(plan.underscanScale, closeTo(0.8329, 0.0001));
    expect(plan.overscanScale, closeTo(2.3879, 0.0001));
    expect(
      plan.scale,
      closeTo((plan.underscanScale + plan.overscanScale) / 2, 0.0001),
    );
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
