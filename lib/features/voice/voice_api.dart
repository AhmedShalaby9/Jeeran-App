import 'package:dio/dio.dart';

import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';

class VoiceHeard {
  final int id;
  final String transcript; // empty when nothing was understood
  const VoiceHeard(this.id, this.transcript);
}

class VoiceApi {
  final ApiClient client;
  VoiceApi(this.client);

  /// Uploads the clip; the server keeps it and returns what it heard.
  /// Throws [ServerException] when recognition is unavailable.
  Future<VoiceHeard> transcribe(
    String path, {
    required int seconds,
    String? language,
  }) async {
    final res = await client.postMultipart(
      '/voice/transcribe',
      filePath: path,
      fileField: 'audio',
      fields: {'duration': seconds, 'language': ?language},
      contentType: DioMediaType('audio', 'mp4'),
    );
    final d = res.data['data'] as Map<String, dynamic>;
    return VoiceHeard(
      (d['id'] as num).toInt(),
      (d['transcript'] as String? ?? '').trim(),
    );
  }
}
