import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records one voice message to a file. Behind an interface so tests do not need a microphone.
abstract class VoiceRecorder {
  Future<bool> requestPermission();

  /// Starts recording; throws if the microphone cannot be opened.
  Future<void> start();

  /// Stops and returns the file path, or null when nothing was captured.
  Future<String?> stop();
  Future<void> cancel();
  void dispose();
}

class DeviceRecorder implements VoiceRecorder {
  final AudioRecorder _rec = AudioRecorder();

  @override
  Future<bool> requestPermission() => _rec.hasPermission();

  @override
  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000, // all Whisper needs; keeps the upload small
        numChannels: 1,
        bitRate: 48000,
      ),
      path: path,
    );
  }

  @override
  Future<String?> stop() async {
    final path = await _rec.stop();
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  @override
  Future<void> cancel() => _rec.cancel();

  @override
  void dispose() => _rec.dispose();
}

/// Reads an answer aloud.
abstract class VoiceSpeaker {
  Future<void> speak(String text, String lang);
  Future<void> stop();
}

class DeviceSpeaker implements VoiceSpeaker {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> speak(String text, String lang) async {
    await _tts.setLanguage(lang == 'ar' ? 'ar-EG' : 'en-US');
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
