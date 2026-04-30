import 'package:flutter_test/flutter_test.dart';
import 'package:pace_tcc/main.dart';

void main() {
  testWidgets('app inicia sem erro', (WidgetTester tester) async {
    await tester.pumpWidget(const PaceApp());
    expect(find.text('Organize sua vida.'), findsOneWidget);
  });
}
