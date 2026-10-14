import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/voice/voice_services.dart';

class _Phone implements VoiceSpeaker {
  final said = <String>[];
  @override
  Future<void> speak(String text, String lang, {void Function()? onDone}) async => said.add('$lang:$text');
  @override
  Future<void> stop() async {}
}

void main() {
  chunks();
  TestWidgetsFlutterBinding.ensureInitialized();
  test('falls back to the phone voice when the server cannot speak', () async {
    final phone = _Phone();
    final s = ServerSpeaker(fetch: (_, _) async => throw Exception('503'), fallback: phone);
    await s.speak('مرحبا', 'ar');
    expect(phone.said, ['ar:مرحبا']);
  });

  test('empty audio also falls back', () async {
    final phone = _Phone();
    final s = ServerSpeaker(fetch: (_, _) async => <int>[], fallback: phone);
    await s.speak('hello', 'en');
    expect(phone.said, ['en:hello']);
  });
}

void chunks() {
  test('the first piece is short so speech starts early, the rest is grouped', () {
    final text = 'First sentence is here. Second one follows now. Third is also short. Fourth ends it.';
    final c = speechChunks(text, first: 40, rest: 200);
    expect(c.first, 'First sentence is here.');
    expect(c.length, 2);
    expect(c.join(' '), text);
  });

  test('Arabic question marks split sentences too', () {
    expect(speechChunks('عايز شقة؟ في التجمع.', first: 8, rest: 8), ['عايز شقة؟', 'في التجمع.']);
  });
}
