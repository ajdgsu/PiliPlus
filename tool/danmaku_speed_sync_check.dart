import 'package:PiliPlus/plugin/pl_player/utils/danmaku_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves enabled and disabled danmaku playback-speed policies', () {
    expect(
      resolveDanmakuPlaybackSpeed(playbackSpeed: 2.0, syncEnabled: true),
      2.0,
    );
    expect(
      resolveDanmakuPlaybackSpeed(playbackSpeed: 2.0, syncEnabled: false),
      1.0,
    );
  });

  test('falls back to base speed for invalid playback rates', () {
    expect(
      resolveDanmakuPlaybackSpeed(playbackSpeed: 0.0, syncEnabled: true),
      1.0,
    );
    expect(
      resolveDanmakuPlaybackSpeed(
        playbackSpeed: double.nan,
        syncEnabled: true,
      ),
      1.0,
    );
  });

  test('derives both durations from canonical base values', () {
    expect(
      resolveDanmakuDurations(
        baseDuration: 8.0,
        baseStaticDuration: 4.0,
        playbackSpeed: 2.0,
        syncEnabled: true,
      ),
      (duration: 4.0, staticDuration: 2.0),
    );
    expect(
      resolveDanmakuDurations(
        baseDuration: 8.0,
        baseStaticDuration: 4.0,
        playbackSpeed: 2.0,
        syncEnabled: false,
      ),
      (duration: 8.0, staticDuration: 4.0),
    );
  });
}
