import 'dart:math' as math;

import 'package:flutter/widgets.dart' show BoxFit, Size, WidgetsBinding;

final class DiagonalRenderPlan {
  const DiagonalRenderPlan({
    required this.viewportSize,
    required this.videoContentSize,
    required this.baseAngleRadians,
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
  final double rotationRadians;
  final double underscanScale;
  final double overscanScale;
  final double scale;
  final double maxInterfaceScale;
  final double interfaceScale;

  double get baseAngleDegrees => baseAngleRadians * 180 / math.pi;
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
    final absAngle = baseAngle.abs();
    final cosTheta = math.cos(absAngle);
    final sinTheta = math.sin(absAngle);
    final rotatedContentWidth =
        videoContentSize.width * cosTheta + videoContentSize.height * sinTheta;
    final rotatedContentHeight =
        videoContentSize.width * sinTheta + videoContentSize.height * cosTheta;
    final underscanScale = math.min(
      viewportSize.width / rotatedContentWidth,
      viewportSize.height / rotatedContentHeight,
    );

    final inverseViewportWidth =
        viewportSize.width * cosTheta + viewportSize.height * sinTheta;
    final inverseViewportHeight =
        viewportSize.width * sinTheta + viewportSize.height * cosTheta;
    final rawOverscanScale = math.max(
      inverseViewportWidth / videoContentSize.width,
      inverseViewportHeight / videoContentSize.height,
    );
    final overscanScale = math.max(rawOverscanScale, underscanScale);
    final scale = _scaleFor(
      scaleSliderValue,
      underscanScale: underscanScale,
      overscanScale: overscanScale,
    );
    final direction = clockwise ? 1.0 : -1.0;
    final rotation = direction * baseAngle + angleOffsetDegrees * math.pi / 180;
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
      rotationRadians: rotation,
      underscanScale: underscanScale,
      overscanScale: overscanScale,
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
