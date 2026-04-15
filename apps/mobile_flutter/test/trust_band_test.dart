import 'package:flutter_test/flutter_test.dart';

import 'package:dealdropapp/src/core/models/app_models.dart';

void main() {
  test('trust band wire values round-trip cleanly', () {
    for (final band in TrustBand.values) {
      expect(trustBandFromApi(trustBandToApi(band)), band);
    }
  });

  test('disputed and merchant trust states expose product-facing copy', () {
    expect(TrustBand.disputed.label, 'Disputed');
    expect(TrustBand.disputed.explanation, contains('conflict'));
    expect(TrustBand.merchantConfirmed.label, 'Merchant confirmed');
    expect(TrustBand.merchantConfirmed.shortLabel, 'Merchant');
  });
}
