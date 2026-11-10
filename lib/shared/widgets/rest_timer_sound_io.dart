import 'package:flutter/services.dart';

void unlockRestTimerAudio() {}

void playRestTimerDing() {
  HapticFeedback.heavyImpact();
  SystemSound.play(SystemSoundType.alert);
}
