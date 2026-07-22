import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zero_trust_client/main.dart';
import 'package:zero_trust_client/providers/app_state.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const ZeroTrustClientApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ZeroTrustClient'), findsOneWidget);
    expect(find.text('Profiles'), findsOneWidget);
  });
}
