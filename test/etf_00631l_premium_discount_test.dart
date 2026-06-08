import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_stock_research_assistant/models/leveraged_etf_lab.dart';

void main() {
  PremiumDiscountAssessment assess(
    double? premiumDiscountPct, {
    EtfDataStatus sourceStatus = EtfDataStatus.proxy,
    bool isStale = false,
  }) {
    return PremiumDiscountAssessment.evaluate(
      premiumDiscountPct: premiumDiscountPct,
      sourceStatus: sourceStatus,
      isStale: isStale,
    );
  }

  test('premium discount level handles unavailable data states', () {
    expect(assess(null).level, PremiumDiscountLevel.unavailable);
    expect(
      assess(0.75, sourceStatus: EtfDataStatus.error).level,
      PremiumDiscountLevel.unavailable,
    );
    expect(
      assess(0.75, sourceStatus: EtfDataStatus.mock).level,
      PremiumDiscountLevel.unavailable,
    );
    expect(assess(0.75, isStale: true).level, PremiumDiscountLevel.stale);
  });

  test('premium discount level classifies normal values', () {
    final premium = assess(0.10);
    final discount = assess(-0.10);

    expect(premium.level, PremiumDiscountLevel.normal);
    expect(premium.label, '正常');
    expect(discount.level, PremiumDiscountLevel.normal);
    expect(discount.label, '正常');
  });

  test('premium discount level classifies watch values', () {
    final premium = assess(0.35);
    final discount = assess(-0.35);

    expect(premium.level, PremiumDiscountLevel.watch);
    expect(premium.label, '溢價觀察');
    expect(discount.level, PremiumDiscountLevel.watch);
    expect(discount.label, '折價觀察');
  });

  test('premium discount level classifies elevated values', () {
    final premium = assess(0.75);
    final discount = assess(-0.75);

    expect(premium.level, PremiumDiscountLevel.elevated);
    expect(premium.label, '溢價偏高');
    expect(discount.level, PremiumDiscountLevel.elevated);
    expect(discount.label, '折價偏深');
  });

  test('premium discount level classifies extreme values', () {
    final premium = assess(1.20);
    final discount = assess(-1.20);

    expect(premium.level, PremiumDiscountLevel.extreme);
    expect(premium.label, '溢價極端');
    expect(discount.level, PremiumDiscountLevel.extreme);
    expect(discount.label, '折價極端');
  });
}
