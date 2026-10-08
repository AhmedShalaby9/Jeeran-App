import 'package:flutter/material.dart';

/// Facilities are free text typed in the dashboard, so the icon is chosen from the wording
/// (English or Arabic). Anything unrecognised gets a neutral check.
IconData facilityIcon(String text) {
  final t = text.toLowerCase();
  bool has(List<String> words) => words.any(t.contains);

  if (has(['pool', 'swim', 'سباحة', 'بحيرة', 'lagoon']))
    return Icons.pool_rounded;
  if (has(['club', 'نادي'])) return Icons.groups_rounded;
  if (has([
    'gym',
    'fitness',
    'جيم',
    'رياض',
    'sport',
    'tennis',
    'تنس',
    'padel',
    'باديل',
  ]))
    return Icons.fitness_center_rounded;
  if (has(['golf', 'جولف'])) return Icons.sports_golf_rounded;
  if (has(['secur', 'gate', 'أمن', 'امن', 'بوابة', 'حراسة']))
    return Icons.shield_outlined;
  if (has(['beach', 'sea', 'marina', 'شاطئ', 'شاطي', 'بحر', 'مارينا']))
    return Icons.beach_access_rounded;
  if (has([
    'park',
    'garden',
    'green',
    'landscape',
    'حديقة',
    'حدائق',
    'مساحات خضراء',
    'خضراء',
  ]))
    return Icons.park_rounded;
  if (has(['kid', 'child', 'play', 'nursery', 'أطفال', 'اطفال', 'حضانة']))
    return Icons.child_care_rounded;
  if (has(['school', 'university', 'مدرسة', 'مدارس', 'جامعة']))
    return Icons.school_rounded;
  if (has(['mosque', 'church', 'مسجد', 'كنيسة'])) return Icons.mosque_rounded;
  if (has(['mall', 'retail', 'shop', 'commercial', 'مول', 'تجاري', 'محلات']))
    return Icons.storefront_rounded;
  if (has(['restaurant', 'cafe', 'café', 'dining', 'مطعم', 'مطاعم', 'كافيه']))
    return Icons.restaurant_rounded;
  if (has([
    'medical',
    'clinic',
    'hospital',
    'عيادة',
    'عيادات',
    'مستشفى',
    'طبي',
  ]))
    return Icons.local_hospital_rounded;
  if (has(['spa', 'sauna', 'سبا', 'ساونا'])) return Icons.spa_rounded;
  if (has(['parking', 'garage', 'جراج', 'موقف', 'ركن']))
    return Icons.local_parking_rounded;
  if (has(['wifi', 'internet', 'إنترنت', 'انترنت'])) return Icons.wifi_rounded;
  return Icons.check_circle_outline_rounded;
}
