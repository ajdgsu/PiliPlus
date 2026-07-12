import 'package:PiliPlus/utils/extension/box_ext.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';

double resolveDanmakuPlaybackSpeed({
  required double playbackSpeed,
  required bool syncEnabled,
}) {
  if (!syncEnabled || !playbackSpeed.isFinite || playbackSpeed <= 0) {
    return 1.0;
  }
  return playbackSpeed;
}

({double duration, double staticDuration}) resolveDanmakuDurations({
  required double baseDuration,
  required double baseStaticDuration,
  required double playbackSpeed,
  required bool syncEnabled,
}) {
  final speed = resolveDanmakuPlaybackSpeed(
    playbackSpeed: playbackSpeed,
    syncEnabled: syncEnabled,
  );
  return (
    duration: baseDuration / speed,
    staticDuration: baseStaticDuration / speed,
  );
}

abstract final class DanmakuOptions {
  static final Set<int> blockTypes = Pref.danmakuBlockType;
  static bool blockColorful = blockTypes.contains(6);

  static int danmakuWeight = Pref.danmakuWeight;
  static double danmakuFontScaleFS = Pref.danmakuFontScaleFS;
  static double danmakuFontScale = Pref.danmakuFontScale;
  static int danmakuFontWeight = Pref.danmakuFontWeight;
  static double danmakuShowArea = Pref.danmakuShowArea;
  static double danmakuDuration = Pref.danmakuDuration;
  static double danmakuStaticDuration = Pref.danmakuStaticDuration;
  static double danmakuStrokeWidth = Pref.danmakuStrokeWidth;
  static bool danmakuFixedV = Pref.danmakuFixedV;
  static bool danmakuStatic2Scroll = Pref.danmakuStatic2Scroll;
  static bool danmakuMassiveMode = Pref.danmakuMassiveMode;
  static double danmakuLineHeight = Pref.danmakuLineHeight;

  static bool get sameFontScale => danmakuFontScale == danmakuFontScaleFS;

  static DanmakuOption applyPlaybackSpeed(
    DanmakuOption option,
    double playbackSpeed,
  ) {
    final durations = resolveDanmakuDurations(
      baseDuration: danmakuDuration,
      baseStaticDuration: danmakuStaticDuration,
      playbackSpeed: playbackSpeed,
      syncEnabled: Pref.syncDanmakuPlaybackSpeed,
    );
    return option.copyWith(
      duration: durations.duration,
      staticDuration: durations.staticDuration,
    );
  }

  static DanmakuOption get({
    required bool notFullscreen,
    double speed = 1.0,
  }) {
    final durations = resolveDanmakuDurations(
      baseDuration: danmakuDuration,
      baseStaticDuration: danmakuStaticDuration,
      playbackSpeed: speed,
      syncEnabled: Pref.syncDanmakuPlaybackSpeed,
    );
    return DanmakuOption(
      fontSize: 15 * (notFullscreen ? danmakuFontScale : danmakuFontScaleFS),
      fontWeight: danmakuFontWeight,
      area: danmakuShowArea,
      duration: durations.duration,
      staticDuration: durations.staticDuration,
      hideBottom: blockTypes.contains(4),
      hideScroll: blockTypes.contains(2),
      hideTop: blockTypes.contains(5),
      hideSpecial: blockTypes.contains(7),
      strokeWidth: danmakuStrokeWidth,
      scrollFixedVelocity: danmakuFixedV,
      massiveMode: danmakuMassiveMode,
      static2Scroll: danmakuStatic2Scroll,
      safeArea: true,
      lineHeight: danmakuLineHeight,
    );
  }

  static Future<void>? save(double danmakuOpacity) {
    return GStorage.setting.putAllNE({
      SettingBoxKey.danmakuBlockType: blockTypes.toList(),
      SettingBoxKey.danmakuShowArea: danmakuShowArea,
      SettingBoxKey.danmakuFontScale: danmakuFontScale,
      SettingBoxKey.danmakuFontScaleFS: danmakuFontScaleFS,
      SettingBoxKey.danmakuDuration: danmakuDuration,
      SettingBoxKey.danmakuStaticDuration: danmakuStaticDuration,
      SettingBoxKey.danmakuStrokeWidth: danmakuStrokeWidth,
      SettingBoxKey.danmakuFontWeight: danmakuFontWeight,
      SettingBoxKey.danmakuLineHeight: danmakuLineHeight,
      SettingBoxKey.danmakuMassiveMode: danmakuMassiveMode,
      SettingBoxKey.danmakuStatic2Scroll: danmakuStatic2Scroll,
      SettingBoxKey.danmakuFixedV: danmakuFixedV,
      SettingBoxKey.danmakuWeight: danmakuWeight,
      SettingBoxKey.danmakuOpacity: danmakuOpacity,
    });
  }
}
