import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/saved/data/models/saved_models.dart';

void main() {
  test('counts read both API dialects', () {
    // the app asks without X-Api-Version, so the server says "projects"
    final legacy = SavedCounts.fromJson({
      'listings': 2,
      'projects': 3,
      'developers': 1,
      'developer_projects': 7,
    });
    expect(legacy.compounds, 3);
    expect(legacy.developerProjects, 7);
    final v2 = SavedCounts.fromJson({'compounds': 3, 'developer_compounds': 7});
    expect(v2.compounds, 3);
    expect(v2.developerProjects, 7);
  });
}
