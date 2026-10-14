// One payment plan of a unit, as `payment_plans[]` returns it. A unit has 1–10 of them.

double? _d(dynamic v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
int? _i(dynamic v) => v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

class PlanBulk {
  final double value;
  final double atYears; // when it falls due, counted in years from the start
  const PlanBulk(this.value, this.atYears);

  factory PlanBulk.fromJson(Map<String, dynamic> j) {
    final years = _d(j['at_years']) ?? 0;
    final months = _d(j['at_months']) ?? 0;
    return PlanBulk(_d(j['value']) ?? 0, years + months / 12);
  }
}

class PlanMilestone {
  final String name;
  final double? total;
  final bool includedInPrice;
  const PlanMilestone(this.name, this.total, this.includedInPrice);

  factory PlanMilestone.fromJson(Map<String, dynamic> j) =>
      PlanMilestone((j['name'] as String?) ?? '', _d(j['total']), j['included_in_price'] == true);
}

class PaymentPlan {
  final String? frequency; // quarterly | monthly | semi-annually | annually | one-time
  final int years;
  final double? unitPrice;
  final double? downPayment;
  final double? downPercent;
  final double? installment;
  final double? totalInstalments;
  final bool isCash;
  final bool isBackLoaded;
  final bool isOffer;
  final double? discountPercent;
  final List<PlanBulk> bulk;
  final List<PlanMilestone> milestones;

  const PaymentPlan({
    this.frequency,
    this.years = 0,
    this.unitPrice,
    this.downPayment,
    this.downPercent,
    this.installment,
    this.totalInstalments,
    this.isCash = false,
    this.isBackLoaded = false,
    this.isOffer = false,
    this.discountPercent,
    this.bulk = const [],
    this.milestones = const [],
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> j) => PaymentPlan(
        frequency: j['frequency'] as String?,
        years: _i(j['years']) ?? 0,
        unitPrice: _d(j['unit_price']),
        downPayment: _d(j['down_payment']),
        downPercent: _d(j['down_payment_percent']),
        installment: _d(j['installment_amount']),
        totalInstalments: _d(j['total_installments_amount']),
        isCash: j['is_cash'] == true,
        isBackLoaded: j['is_back_loaded'] == true,
        isOffer: j['is_offer'] == true,
        discountPercent: _d(j['discount_percent']),
        bulk: (j['bulk_payments'] is List ? j['bulk_payments'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(PlanBulk.fromJson)
            .toList(),
        milestones: (j['milestones'] is List ? j['milestones'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(PlanMilestone.fromJson)
            .toList(),
      );

  static List<PaymentPlan> listFrom(dynamic v) => v is List
      ? v.whereType<Map<String, dynamic>>().map(PaymentPlan.fromJson).toList()
      : const [];

  /// Paid in one go: no instalments to show.
  bool get payInFull => isCash || frequency == 'one-time' || (installment ?? 0) <= 0;

  /// How many instalments fall due in a year.
  int get perYear => switch (frequency) {
        'monthly' => 12,
        'quarterly' => 4,
        'semi-annually' => 2,
        'annually' => 1,
        _ => 4,
      };

  int get instalments => years * perYear;

  /// A real discount (0 and empty both mean "an offer, no number").
  double? get discount => (discountPercent ?? 0) > 0 ? discountPercent : null;

  /// The mark on the plan: a discount, or just "Offer".
  bool get hasOffer => isOffer || discount != null;

  /// The one-time maintenance fee, when the plan carries it.
  double? get maintenance {
    for (final m in milestones) {
      if (m.name.toLowerCase().contains('maintenance') && (m.total ?? 0) > 0) return m.total;
    }
    return null;
  }

  bool get maintenanceIncluded =>
      milestones.any((m) => m.name.toLowerCase().contains('maintenance') && m.includedInPrice);
}

/// The plan the unit page opens on: the one that matches the unit's own down payment and years
/// (what the source shows by default), else the first that is not cash.
PaymentPlan? defaultPlan(List<PaymentPlan> plans, {double? downPercent, int? years}) {
  if (plans.isEmpty) return null;
  if (downPercent != null && years != null) {
    for (final p in plans) {
      if (!p.payInFull && p.years == years && (p.downPercent ?? -1) == downPercent) return p;
    }
  }
  return plans.firstWhere((p) => !p.payInFull, orElse: () => plans.first);
}
