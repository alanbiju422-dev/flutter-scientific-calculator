import 'package:flutter_test/flutter_test.dart';
import 'package:basic_calculator/main.dart';

void main() {
  testWidgets('Standard calculator smoke test: 7 + 8 = 15', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    // Initially starts in Standard Mode
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('0'), findsWidgets);

    // Tap '7'
    await tester.tap(find.text('7'));
    await tester.pump();
    expect(find.text('7'), findsWidgets);

    // Tap '+'
    await tester.tap(find.text('+'));
    await tester.pump();

    // Tap '8'
    await tester.tap(find.text('8'));
    await tester.pump();

    // Tap '='
    await tester.tap(find.text('='));
    await tester.pump();

    // Result should be 15
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('Switch to Scientific mode and calculate sin(30)', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    // Tap 'Scientific'
    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();

    // Tap 'sin'
    await tester.tap(find.text('sin'));
    await tester.pump();

    // Tap '3', '0', ')'
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text(')'));
    await tester.pump();

    // Tap '='
    await tester.tap(find.text('='));
    await tester.pump();

    // sin(30) in degree mode is 0.5
    expect(find.text('0.5'), findsOneWidget);
  });

  testWidgets('Scientific mode arbitrary base logarithm: log base 3 of 81 = 4', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    // Switch to Scientific
    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();

    // Tap 'logᵦ' (any base logarithm button)
    await tester.tap(find.text('logᵦ'));
    await tester.pump();

    // Enter '3' (base)
    await tester.tap(find.text('3'));
    await tester.pump();

    // Enter ',' (comma separator)
    await tester.tap(find.text(',').first);
    await tester.pump();

    // Enter '8', '1' (value)
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();

    // Enter ')'
    await tester.tap(find.text(')'));
    await tester.pump();

    // Tap '='
    await tester.tap(find.text('='));
    await tester.pump();

    // Result of log_3(81) is 4 (display output + keypad button '4')
    expect(find.text('4'), findsNWidgets(2));
  });

  testWidgets('Switch between Standard and Scientific modes', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    // Initially in Standard mode: 'sin' should NOT be present
    expect(find.text('sin'), findsNothing);

    // Tap 'Scientific'
    await tester.tap(find.text('Scientific'));
    await tester.pumpAndSettle();

    // 'sin' and 'logᵦ' should now be present
    expect(find.text('sin'), findsOneWidget);
    expect(find.text('logᵦ'), findsOneWidget);

    // Tap 'Standard'
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();

    // 'sin' is gone again
    expect(find.text('sin'), findsNothing);
  });
}
