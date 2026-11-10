import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

web.AudioContext? _audioContext;

web.AudioContext? _ensureContext() {
  try {
    return _audioContext ??= web.AudioContext();
  } catch (_) {
    return null;
  }
}

void unlockRestTimerAudio() {
  final ctx = _ensureContext();
  if (ctx == null) return;
  try {
    if (ctx.state == 'suspended') {
      ctx.resume();
    }
    final buffer = ctx.createBuffer(1, 1, 22050);
    final source = ctx.createBufferSource();
    source.buffer = buffer;
    source.connect(ctx.destination);
    source.start(0);
  } catch (_) {}
}

void playRestTimerDing() {
  HapticFeedback.heavyImpact();
  final ctx = _ensureContext();
  if (ctx == null) return;
  try {
    if (ctx.state == 'suspended') {
      ctx.resume();
    }
    final now = ctx.currentTime;
    // First chime note (A5 + soft A6 harmonic)
    _scheduleTone(ctx, startTime: now, frequency: 880.0, duration: 0.35, peakGain: 0.28);
    _scheduleTone(ctx, startTime: now, frequency: 1760.0, duration: 0.22, peakGain: 0.08);
    // Second chime note (E6 + soft E7 harmonic)
    _scheduleTone(ctx, startTime: now + 0.16, frequency: 1318.5, duration: 0.55, peakGain: 0.32);
    _scheduleTone(ctx, startTime: now + 0.16, frequency: 2637.0, duration: 0.35, peakGain: 0.10);
  } catch (_) {}
}

void _scheduleTone(
  web.AudioContext ctx, {
  required num startTime,
  required num frequency,
  required num duration,
  required num peakGain,
}) {
  final osc = ctx.createOscillator();
  final gain = ctx.createGain();
  osc.type = 'sine';
  osc.frequency.setValueAtTime(frequency, startTime);

  gain.gain.setValueAtTime(0.0001, startTime);
  gain.gain.linearRampToValueAtTime(peakGain, startTime + 0.015);
  gain.gain.exponentialRampToValueAtTime(0.0001, startTime + duration);

  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.start(startTime);
  osc.stop(startTime + duration + 0.02);
}
