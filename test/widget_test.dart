
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter/main.dart';

void main() {
  testWidgets('Welcome page is shown on launch', (tester) async {
    await tester.pumpWidget(const CalorieCounterApp());

    expect(find.text('Calorie Counter'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
