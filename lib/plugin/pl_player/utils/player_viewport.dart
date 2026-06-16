import 'package:flutter/widgets.dart';

double playerViewportHeight({
  required double maxHeight,
  required EdgeInsets padding,
  required bool isFullScreen,
  required bool isWindowMode,
  required bool isPortrait,
}) {
  if (isFullScreen) {
    return maxHeight;
  }
  return maxHeight - (isWindowMode && !isPortrait ? 0 : padding.top);
}

EdgeInsets playerContentPadding({
  required EdgeInsets padding,
  required bool isFullScreen,
}) {
  return isFullScreen ? EdgeInsets.zero : padding;
}
