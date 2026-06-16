import 'package:PiliPlus/plugin/pl_player/utils/player_viewport.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const padding = EdgeInsets.only(top: 48, bottom: 12, left: 8, right: 10);

  test('fullscreen viewport ignores hidden status-bar padding', () {
    final fullHeight = playerViewportHeight(
      maxHeight: 1000,
      padding: padding,
      isFullScreen: true,
      isWindowMode: false,
      isPortrait: true,
    );

    expect(fullHeight, 1000);
  });

  test('embedded viewport preserves existing safe-area behavior', () {
    final embeddedHeight = playerViewportHeight(
      maxHeight: 1000,
      padding: padding,
      isFullScreen: false,
      isWindowMode: false,
      isPortrait: true,
    );

    expect(embeddedHeight, 952);

    final windowLandscapeHeight = playerViewportHeight(
      maxHeight: 1000,
      padding: padding,
      isFullScreen: false,
      isWindowMode: true,
      isPortrait: false,
    );

    expect(windowLandscapeHeight, 1000);
  });

  test('fullscreen content padding is zeroed only in fullscreen', () {
    expect(
      playerContentPadding(padding: padding, isFullScreen: true),
      EdgeInsets.zero,
    );
    expect(
      playerContentPadding(padding: padding, isFullScreen: false),
      padding,
    );
  });
}
