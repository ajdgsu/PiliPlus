import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/widgets.dart'
    show
        BoxFit,
        BuildContext,
        EdgeInsets,
        InheritedWidget,
        Offset,
        Size,
        WidgetsBinding;

final class DiagonalRenderPlan {
  const DiagonalRenderPlan({
    required this.viewportSize,
    required this.videoContentSize,
    required this.baseAngleRadians,
    required this.balancedAngleRadians,
    required this.rotationRadians,
    required this.underscanScale,
    required this.overscanScale,
    required this.scale,
    required this.maxInterfaceScale,
    required this.interfaceScale,
  });

  final Size viewportSize;
  final Size videoContentSize;
  final double baseAngleRadians;
  final double balancedAngleRadians;
  final double rotationRadians;
  final double underscanScale;
  final double overscanScale;
  final double scale;
  final double maxInterfaceScale;
  final double interfaceScale;

  double get baseAngleDegrees => baseAngleRadians * 180 / math.pi;

  double get balancedAngleDegrees => balancedAngleRadians * 180 / math.pi;

  double get danmakuPositionScale => scale.isFinite && scale > 0 ? scale : 1.0;

  EdgeInsets get interfaceInsets {
    final safeScale = maxInterfaceScale.clamp(0.0, 1.0).toDouble();
    if (safeScale >= 1.0) {
      return EdgeInsets.zero;
    }
    return EdgeInsets.symmetric(
      horizontal: viewportSize.width * (1.0 - safeScale) / 2,
      vertical: viewportSize.height * (1.0 - safeScale) / 2,
    );
  }
}

final class DiagonalRenderOverlayTransform {
  const DiagonalRenderOverlayTransform({
    required this.viewportSize,
    required this.rotationRadians,
    required this.interfaceInsets,
  });

  factory DiagonalRenderOverlayTransform.fromPlan(DiagonalRenderPlan plan) {
    return DiagonalRenderOverlayTransform(
      viewportSize: plan.viewportSize,
      rotationRadians: plan.rotationRadians,
      interfaceInsets: plan.interfaceInsets,
    );
  }

  final Size viewportSize;
  final double rotationRadians;
  final EdgeInsets interfaceInsets;
}

abstract final class DiagonalRenderToastTransform {
  static final ValueNotifier<DiagonalRenderOverlayTransform?> notifier =
      ValueNotifier(null);

  static DiagonalRenderOverlayTransform? get value => notifier.value;

  static void update(DiagonalRenderOverlayTransform? transform) {
    if (same(value, transform)) {
      return;
    }
    notifier.value = transform;
  }

  static bool same(
    DiagonalRenderOverlayTransform? a,
    DiagonalRenderOverlayTransform? b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return _close(a.viewportSize.width, b.viewportSize.width) &&
        _close(a.viewportSize.height, b.viewportSize.height) &&
        _close(a.rotationRadians, b.rotationRadians) &&
        _close(a.interfaceInsets.left, b.interfaceInsets.left) &&
        _close(a.interfaceInsets.top, b.interfaceInsets.top) &&
        _close(a.interfaceInsets.right, b.interfaceInsets.right) &&
        _close(a.interfaceInsets.bottom, b.interfaceInsets.bottom);
  }

  static bool _close(double a, double b) => (a - b).abs() < 1e-6;
}

class DiagonalRenderScope extends InheritedWidget {
  const DiagonalRenderScope({
    super.key,
    required this.danmakuPositionScale,
    required super.child,
  });

  final double danmakuPositionScale;

  static double danmakuPositionScaleOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DiagonalRenderScope>();
    return scope?.danmakuPositionScale ?? 1.0;
  }

  @override
  bool updateShouldNotify(covariant DiagonalRenderScope oldWidget) {
    return danmakuPositionScale != oldWidget.danmakuPositionScale;
  }
}

final class DiagonalRenderGeometry {
  const DiagonalRenderGeometry({
    required this.screenSize,
    required this.baseAngleRadians,
    required this.underscanScale,
    required this.overscanScale,
  });

  final Size screenSize;
  final double baseAngleRadians;
  final double underscanScale;
  final double overscanScale;

  static const double _balancedAngleGainFloor = 0.97;
  static const int _balancedAngleScanSteps = 48;
  static const int _balancedAngleRefineRounds = 3;

  double get baseAngleDegrees => baseAngleRadians * 180 / math.pi;

  double get alternateBaseAngleRadians => math.pi / 2 - baseAngleRadians;

  double baseAngleForViewport(Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return baseAngleRadians;
    }
    return viewportSize.height > viewportSize.width
        ? alternateBaseAngleRadians
        : baseAngleRadians;
  }

  bool shouldRotateForVideoAspect({
    required Size viewportSize,
    required double videoAspectRatio,
  }) {
    if (!_isValidSize(viewportSize) || !_isValidAspect(videoAspectRatio)) {
      return false;
    }
    final screenRatio = _longSideRatio(viewportSize.width, viewportSize.height);
    final videoRatio = videoAspectRatio >= 1
        ? videoAspectRatio
        : 1 / videoAspectRatio;
    return screenRatio < videoRatio - 1e-6;
  }

  DiagonalRenderPlan? planFor({
    required Size viewportSize,
    required double videoAspectRatio,
    required BoxFit fit,
    required bool clockwise,
    required double angleOffsetDegrees,
    required double scaleSliderValue,
    double? aspectRatioOverride,
  }) {
    if (!shouldRotateForVideoAspect(
      viewportSize: viewportSize,
      videoAspectRatio: videoAspectRatio,
    )) {
      return null;
    }

    final contentAspectRatio = _isValidAspect(aspectRatioOverride)
        ? aspectRatioOverride!
        : videoAspectRatio;
    final videoContentSize = _fittedVideoContentSize(
      viewportSize: viewportSize,
      aspectRatio: contentAspectRatio,
      fit: fit,
    );
    if (!_isValidSize(videoContentSize)) {
      return null;
    }

    final baseAngle = baseAngleForViewport(viewportSize);
    final balancedAngle = _balancedAngleFor(
      viewportSize: viewportSize,
      contentSize: videoContentSize,
      baseAngle: baseAngle,
      scaleSliderValue: scaleSliderValue,
    );
    final scaleBounds = _scaleBoundsForAngle(
      viewportSize: viewportSize,
      contentSize: videoContentSize,
      angle: balancedAngle,
    );
    final scale = _scaleFor(
      scaleSliderValue,
      underscanScale: scaleBounds.underscan,
      overscanScale: scaleBounds.overscan,
    );
    final direction = clockwise ? 1.0 : -1.0;
    final rotation =
        direction * balancedAngle + angleOffsetDegrees * math.pi / 180;
    final maxInterfaceScale = _maxScaleForRotatedSize(
      viewportSize: viewportSize,
      contentSize: viewportSize,
      rotationRadians: rotation,
    );
    final interfaceScale = math.min(scale, maxInterfaceScale);

    return DiagonalRenderPlan(
      viewportSize: viewportSize,
      videoContentSize: videoContentSize,
      baseAngleRadians: baseAngle,
      balancedAngleRadians: balancedAngle,
      rotationRadians: rotation,
      underscanScale: scaleBounds.underscan,
      overscanScale: scaleBounds.overscan,
      scale: scale,
      maxInterfaceScale: maxInterfaceScale,
      interfaceScale: interfaceScale,
    );
  }

  double scaleFor(double sliderValue) {
    return _scaleFor(
      sliderValue,
      underscanScale: underscanScale,
      overscanScale: overscanScale,
    );
  }

  double rotationFor({
    required bool clockwise,
    required double angleOffsetDegrees,
  }) {
    final direction = clockwise ? 1.0 : -1.0;
    return direction * baseAngleRadians + angleOffsetDegrees * math.pi / 180;
  }

  static double _scaleFor(
    double sliderValue, {
    required double underscanScale,
    required double overscanScale,
  }) {
    final t = sliderValue.clamp(0.0, 100.0).toDouble() / 100.0;
    return underscanScale * (1.0 - t) + overscanScale * t;
  }

  static Size _fittedVideoContentSize({
    required Size viewportSize,
    required double aspectRatio,
    required BoxFit fit,
  }) {
    final viewportAspectRatio = viewportSize.width / viewportSize.height;
    return switch (fit) {
      BoxFit.fill => viewportSize,
      BoxFit.cover =>
        viewportAspectRatio > aspectRatio
            ? Size(viewportSize.width, viewportSize.width / aspectRatio)
            : Size(viewportSize.height * aspectRatio, viewportSize.height),
      BoxFit.fitWidth => Size(
        viewportSize.width,
        viewportSize.width / aspectRatio,
      ),
      BoxFit.fitHeight => Size(
        viewportSize.height * aspectRatio,
        viewportSize.height,
      ),
      BoxFit.contain || BoxFit.none || BoxFit.scaleDown =>
        viewportAspectRatio > aspectRatio
            ? Size(viewportSize.height * aspectRatio, viewportSize.height)
            : Size(viewportSize.width, viewportSize.width / aspectRatio),
    };
  }

  static _ScaleBounds _scaleBoundsForAngle({
    required Size viewportSize,
    required Size contentSize,
    required double angle,
  }) {
    final absAngle = angle.abs();
    final cosTheta = math.cos(absAngle);
    final sinTheta = math.sin(absAngle);
    final rotatedContentWidth =
        contentSize.width * cosTheta + contentSize.height * sinTheta;
    final rotatedContentHeight =
        contentSize.width * sinTheta + contentSize.height * cosTheta;
    final underscanScale = math.min(
      viewportSize.width / rotatedContentWidth,
      viewportSize.height / rotatedContentHeight,
    );

    final inverseViewportWidth =
        viewportSize.width * cosTheta + viewportSize.height * sinTheta;
    final inverseViewportHeight =
        viewportSize.width * sinTheta + viewportSize.height * cosTheta;
    final rawOverscanScale = math.max(
      inverseViewportWidth / contentSize.width,
      inverseViewportHeight / contentSize.height,
    );
    return _ScaleBounds(
      underscan: underscanScale,
      overscan: math.max(rawOverscanScale, underscanScale),
    );
  }

  static double _balancedAngleFor({
    required Size viewportSize,
    required Size contentSize,
    required double baseAngle,
    required double scaleSliderValue,
  }) {
    final diagonal = math.sqrt(
      viewportSize.width * viewportSize.width +
          viewportSize.height * viewportSize.height,
    );
    final longSide = math.max(viewportSize.width, viewportSize.height);
    final diagonalGain = diagonal - longSide;
    if (diagonalGain <= 0) {
      return baseAngle;
    }

    final minSpan =
        longSide + diagonalGain * _balancedAngleGainFloor.clamp(0.0, 1.0);
    final maxDelta = math.acos((minSpan / diagonal).clamp(-1.0, 1.0));
    if (maxDelta <= 1e-9) {
      return baseAngle;
    }

    final startAngle = math.max(0.0, baseAngle - maxDelta);
    final endAngle = math.min(math.pi / 2, baseAngle + maxDelta);
    var bestAngle = baseAngle;
    var bestScore = _cornerCropImbalance(
      viewportSize: viewportSize,
      contentSize: contentSize,
      angle: baseAngle,
      scaleSliderValue: scaleSliderValue,
    );
    var searchStart = startAngle;
    var searchEnd = endAngle;

    for (var round = 0; round <= _balancedAngleRefineRounds; round++) {
      final step = (searchEnd - searchStart) / _balancedAngleScanSteps;
      if (step <= 0) {
        break;
      }

      for (var i = 0; i <= _balancedAngleScanSteps; i++) {
        final angle = searchStart + step * i;
        final score = _cornerCropImbalance(
          viewportSize: viewportSize,
          contentSize: contentSize,
          angle: angle,
          scaleSliderValue: scaleSliderValue,
        );
        if (score < bestScore - 1e-9) {
          bestScore = score;
          bestAngle = angle;
        }
      }

      searchStart = math.max(startAngle, bestAngle - step);
      searchEnd = math.min(endAngle, bestAngle + step);
    }

    return bestAngle;
  }

  static double _cornerCropImbalance({
    required Size viewportSize,
    required Size contentSize,
    required double angle,
    required double scaleSliderValue,
  }) {
    final scaleBounds = _scaleBoundsForAngle(
      viewportSize: viewportSize,
      contentSize: contentSize,
      angle: angle,
    );
    final scale = _scaleFor(
      scaleSliderValue,
      underscanScale: scaleBounds.underscan,
      overscanScale: scaleBounds.overscan,
    );
    if (scale <= scaleBounds.underscan + 1e-9) {
      return 0.0;
    }

    final scaledWidth = contentSize.width * scale;
    final scaledHeight = contentSize.height * scale;
    final quadrantArea = scaledWidth * scaledHeight / 4;
    final halfWidth = scaledWidth / 2;
    final halfHeight = scaledHeight / 2;
    final quadrants = <List<Offset>>[
      [
        Offset(-halfWidth, -halfHeight),
        Offset(0, -halfHeight),
        Offset.zero,
        Offset(-halfWidth, 0),
      ],
      [
        Offset(0, -halfHeight),
        Offset(halfWidth, -halfHeight),
        Offset(halfWidth, 0),
        Offset.zero,
      ],
      [
        Offset.zero,
        Offset(halfWidth, 0),
        Offset(halfWidth, halfHeight),
        Offset(0, halfHeight),
      ],
      [
        Offset(-halfWidth, 0),
        Offset.zero,
        Offset(0, halfHeight),
        Offset(-halfWidth, halfHeight),
      ],
    ];
    final halfPlanes = _viewportHalfPlanes(viewportSize, angle);
    var minCrop = double.infinity;
    var maxCrop = 0.0;
    for (final quadrant in quadrants) {
      final visibleArea = _clipAreaByHalfPlanes(quadrant, halfPlanes);
      final cropArea = math.max(0.0, quadrantArea - visibleArea);
      minCrop = math.min(minCrop, cropArea);
      maxCrop = math.max(maxCrop, cropArea);
    }

    return (maxCrop - minCrop) / (scaledWidth * scaledHeight);
  }

  static List<_HalfPlane> _viewportHalfPlanes(Size viewportSize, double angle) {
    final cosTheta = math.cos(angle);
    final sinTheta = math.sin(angle);
    return [
      _HalfPlane(cosTheta, -sinTheta, viewportSize.width / 2),
      _HalfPlane(-cosTheta, sinTheta, viewportSize.width / 2),
      _HalfPlane(sinTheta, cosTheta, viewportSize.height / 2),
      _HalfPlane(-sinTheta, -cosTheta, viewportSize.height / 2),
    ];
  }

  static double _clipAreaByHalfPlanes(
    List<Offset> polygon,
    List<_HalfPlane> halfPlanes,
  ) {
    var clipped = polygon;
    for (final halfPlane in halfPlanes) {
      clipped = _clipPolygon(clipped, halfPlane);
      if (clipped.isEmpty) {
        return 0.0;
      }
    }
    return _polygonArea(clipped);
  }

  static List<Offset> _clipPolygon(
    List<Offset> polygon,
    _HalfPlane halfPlane,
  ) {
    if (polygon.isEmpty) {
      return const [];
    }

    final output = <Offset>[];
    for (var i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final next = polygon[(i + 1) % polygon.length];
      final currentDistance = halfPlane.distance(current);
      final nextDistance = halfPlane.distance(next);
      final currentInside = currentDistance <= 1e-9;
      final nextInside = nextDistance <= 1e-9;

      if (currentInside && nextInside) {
        output.add(next);
      } else if (currentInside != nextInside) {
        final t = currentDistance / (currentDistance - nextDistance);
        output.add(
          Offset(
            current.dx + (next.dx - current.dx) * t,
            current.dy + (next.dy - current.dy) * t,
          ),
        );
        if (nextInside) {
          output.add(next);
        }
      }
    }
    return output;
  }

  static double _polygonArea(List<Offset> polygon) {
    if (polygon.length < 3) {
      return 0.0;
    }

    var area = 0.0;
    for (var i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final next = polygon[(i + 1) % polygon.length];
      area += current.dx * next.dy - next.dx * current.dy;
    }
    return area.abs() / 2;
  }

  static double _maxScaleForRotatedSize({
    required Size viewportSize,
    required Size contentSize,
    required double rotationRadians,
  }) {
    final cosTheta = math.cos(rotationRadians).abs();
    final sinTheta = math.sin(rotationRadians).abs();
    final rotatedContentWidth =
        contentSize.width * cosTheta + contentSize.height * sinTheta;
    final rotatedContentHeight =
        contentSize.width * sinTheta + contentSize.height * cosTheta;
    return math.min(
      viewportSize.width / rotatedContentWidth,
      viewportSize.height / rotatedContentHeight,
    );
  }

  static bool _isValidSize(Size size) {
    return size.width.isFinite &&
        size.height.isFinite &&
        size.width > 0 &&
        size.height > 0;
  }

  static bool _isValidAspect(double? aspectRatio) {
    return aspectRatio != null && aspectRatio.isFinite && aspectRatio > 0;
  }

  static double _longSideRatio(double width, double height) {
    return math.max(width, height) / math.min(width, height);
  }
}

final class _ScaleBounds {
  const _ScaleBounds({
    required this.underscan,
    required this.overscan,
  });

  final double underscan;
  final double overscan;
}

final class _HalfPlane {
  const _HalfPlane(this.a, this.b, this.c);

  final double a;
  final double b;
  final double c;

  double distance(Offset point) => a * point.dx + b * point.dy - c;
}

abstract final class DiagonalRenderGeometryCache {
  static const double _sizeTolerance = 0.5;

  static Size? _lastCanonicalSize;
  static DiagonalRenderGeometry? _geometry;
  static int _debugComputeCount = 0;

  static DiagonalRenderGeometry? get current => _geometry;

  static int get debugComputeCount => _debugComputeCount;

  static bool refreshCurrentView() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      return false;
    }
    final view = views.first;
    final devicePixelRatio = view.devicePixelRatio;
    if (devicePixelRatio <= 0) {
      return false;
    }
    return updateForSize(view.physicalSize / devicePixelRatio);
  }

  static DiagonalRenderGeometry resolveForSize(Size size) {
    updateForSize(size);
    final geometry = _geometry;
    if (geometry == null) {
      throw ArgumentError.value(size, 'size', 'must be non-empty');
    }
    return geometry;
  }

  static bool updateForSize(Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return false;
    }
    final canonicalSize = _canonicalSize(size);
    if (_lastCanonicalSize case final lastSize?
        when _sameSize(lastSize, canonicalSize)) {
      return false;
    }

    _lastCanonicalSize = canonicalSize;
    _geometry = _calculate(canonicalSize);
    _debugComputeCount += 1;
    return true;
  }

  static void resetForTest() {
    _lastCanonicalSize = null;
    _geometry = null;
    _debugComputeCount = 0;
  }

  static Size _canonicalSize(Size size) {
    final shortSide = math.min(size.width, size.height);
    final longSide = math.max(size.width, size.height);
    return Size(longSide, shortSide);
  }

  static bool _sameSize(Size a, Size b) {
    return (a.width - b.width).abs() < _sizeTolerance &&
        (a.height - b.height).abs() < _sizeTolerance;
  }

  static DiagonalRenderGeometry _calculate(Size size) {
    final width = size.width;
    final height = size.height;
    final theta = math.atan(height / width);
    final cosTheta = math.cos(theta);
    final sinTheta = math.sin(theta);
    final bboxW = width * cosTheta + height * sinTheta;
    final bboxH = width * sinTheta + height * cosTheta;
    final scaleW = bboxW / width;
    final scaleH = bboxH / height;
    final overscanScale = math.max(scaleW, scaleH);
    final underscanScale = math.min(1 / scaleW, 1 / scaleH);

    return DiagonalRenderGeometry(
      screenSize: size,
      baseAngleRadians: theta,
      underscanScale: underscanScale,
      overscanScale: overscanScale,
    );
  }
}
