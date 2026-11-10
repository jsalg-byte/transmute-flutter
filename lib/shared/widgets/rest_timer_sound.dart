import 'rest_timer_sound_io.dart'
    if (dart.library.js_interop) 'rest_timer_sound_web.dart' as impl;

/// Plays an audible chime when the workout rest timer finishes.
abstract final class RestTimerSound {
  /// Unlocks the audio context during a direct user gesture (such as logging
  /// a set or starting the rest timer) so mobile browsers allow playback when
  /// the countdown completes.
  static void unlock() => impl.unlockRestTimerAudio();

  /// Plays the rest-complete ding sound and haptic cue.
  static void playDing() => impl.playRestTimerDing();
}
