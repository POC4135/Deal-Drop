import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dealdropapp/src/app/dealdrop_app.dart';

void main() {
  testWidgets('guest can enter the deals shell from the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: DealDropApp()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Deal'), findsWidgets);
    expect(find.text('Continue as guest'), findsOneWidget);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Atlanta, GA'), findsOneWidget);
    expect(find.text('Deals'), findsWidgets);
  });
}
