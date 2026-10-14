import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
  /// [onDone] runs when the reading ends or is stopped.
  Future<void> speak(String text, String lang, {void Function()? onDone});
  Future<void> stop();
}

class DeviceSpeaker implements VoiceSpeaker {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> speak(
    String text,
    String lang, {
    void Function()? onDone,
  }) async {
    await _tts.setLanguage(lang == 'ar' ? 'ar-EG' : 'en-US');
    _tts.setCompletionHandler(() => onDone?.call());
    _tts.setCancelHandler(() => onDone?.call());
    _tts.setErrorHandler((_) => onDone?.call());
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}

/// Splits an answer into short pieces so the first one can be spoken while the rest are still being made.
List<String> speechChunks(String text, {int first = 140, int rest = 320}) {
  final sentences = RegExp(r'[^.!?؟۔\n]+[.!?؟۔]*').allMatches(text).map((m) => m.group(0)!.trim()).where((e) => e.isNotEmpty);
  final out = <String>[];
  var cur = '';
  for (final s in sentences) {
    final limit = out.isEmpty ? first : rest;
    if (cur.isNotEmpty && cur.length + s.length + 1 > limit) {
      out.add(cur);
      cur = s;
    } else {
      cur = cur.isEmpty ? s : '$cur $s';
    }
  }
  if (cur.isNotEmpty) out.add(cur);
  return out;
}

/// Natural speech from the server (Gemini). The answer is read piece by piece (the next piece is made while the
/// current one plays), and any failure falls back to the phone's own voice so a reply is never silent.
class ServerSpeaker implements VoiceSpeaker {
  final Future<List<int>> Function(String text, String lang) fetch;
  final VoiceSpeaker fallback;
  AudioPlayer? _p; // made on first use: the fallback path never needs the audio plugin
  AudioPlayer get _player => _p ??= AudioPlayer();
  int _run = 0; // a newer speak() or stop() cancels the one still going

  ServerSpeaker({required this.fetch, VoiceSpeaker? fallback}) : fallback = fallback ?? DeviceSpeaker();

  @override
  Future<void> speak(String text, String lang, {void Function()? onDone}) async {
    final run = ++_run;
    final chunks = speechChunks(text);
    if (chunks.isEmpty) {
      onDone?.call();
      return;
    }
    // start every request now, in order; playing waits for each one's turn
    final pending = [for (final c in chunks) fetch(c, lang)];
    for (final f in pending) {
      f.ignore(); // an error is handled where it is awaited below, not reported as unhandled
    }
    var i = 0;
    try {
      for (; i < pending.length; i++) {
        final bytes = await pending[i];
        if (run != _run) return;
        if (bytes.isEmpty) throw StateError('empty audio');
        final done = _player.onPlayerComplete.first;
        await _player.play(BytesSource(Uint8List.fromList(bytes), mimeType: 'audio/wav'));
        await done;
        if (run != _run) return;
      }
      onDone?.call();
    } catch (e) {
      debugPrint('ServerSpeaker fell back to the phone voice: $e');
      if (run != _run) return;
      await fallback.speak(chunks.sublist(i).join(' '), lang, onDone: onDone);
    }
  }

  @override
  Future<void> stop() async {
    _run++;
    await _p?.stop();
    await fallback.stop();
  }
}
