import 'package:flutter_test/flutter_test.dart';
import 'package:kizunalog/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const KizunaLogApp());
    expect(find.text('こども思い出ノート'), findsOneWidget);
  });
}
