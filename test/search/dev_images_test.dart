import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/search/data/search_api.dart';

Map<String, dynamic> _dev(int id, {String? logo, String? cover}) => {
  'id': id,
  'name_ar': 'مطور $id',
  'name_en': 'Developer $id',
  'logo': logo,
  'cover_image': cover,
  'is_verified': false,
  'compounds_count': 2,
  'units_count': 10,
};

void main() {
  test('logo and cover are both optional', () {
    final all = DeveloperSummary.fromJson(_dev(1, logo: 'https://x/l.png', cover: 'https://x/c.jpg'));
    expect(all.logo, 'https://x/l.png');
    expect(all.cover, 'https://x/c.jpg');
    final none = DeveloperSummary.fromJson(_dev(2));
    expect(none.logo, isNull);
    expect(none.cover, isNull);
    // a field cleared in the dashboard counts as nothing, so the card keeps its plain look
    expect(DeveloperSummary.fromJson(_dev(3, logo: '', cover: '  ')).cover, isNull);
    expect(DeveloperSummary.fromJson(_dev(3, logo: '', cover: '  ')).logo, isNull);
  });
}
