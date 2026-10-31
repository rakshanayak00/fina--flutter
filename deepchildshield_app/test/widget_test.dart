import 'package:flutter_test/flutter_test.dart';
import 'package:deepchildshield_app/main.dart';

void main() {
  testWidgets('DeepChildShield app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const DeepChildShieldApp());
    expect(find.byType(DeepChildShieldApp), findsOneWidget);
  });
}
