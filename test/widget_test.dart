import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_connect/main.dart';

void main() {
  testWidgets('TutorConnect app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}