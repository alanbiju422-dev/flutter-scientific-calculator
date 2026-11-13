import 'package:flutter_test/flutter_test.dart';
import 'package:basic_calculator/calculator_controller.dart';
import 'package:basic_calculator/calculator_engine.dart';

void main() {
  final engine = CalculatorEngine();

  group('expression engine', () {
    test('basic arithmetic, precedence, chaining and parentheses', () {
      expect(engine.evaluate('5+7'), 12);
      expect(engine.evaluate('2^3+3^2'), 17);
      expect(engine.evaluate('2*(3+(4*5))'), 46);
      expect(engine.evaluate('2(3+4)'), 14);
      expect(engine.evaluate('-2^2'), -4);
    });

    test('trigonometry supports degrees, radians, inverse and hyperbolic forms', () {
      expect(engine.evaluate('sin(30)'), closeTo(.5, 1e-12));
      expect(engine.evaluate('cos(60)'), closeTo(.5, 1e-12));
      expect(engine.evaluate('sin(pi/6)', angleMode: AngleMode.radians), closeTo(.5, 1e-12));
      expect(engine.evaluate('asin(.5)'), closeTo(30, 1e-12));
      expect(engine.evaluate('sinh(1)'), closeTo(1.1752011936438, 1e-12));
      expect(engine.evaluate('sinh(-1)'), closeTo(-1.1752011936438, 1e-12));
      expect(engine.evaluate('asinh(0)'), 0);
      expect(engine.evaluate('asinh(-1)'), closeTo(-0.8813735870195, 1e-12));
      expect(engine.evaluate('acosh(1)'), 0);
      expect(engine.evaluate('cosh(0)'), 1);
      expect(engine.evaluate('tanh(0)'), 0);
    });

    test('custom-base and common logarithms', () {
      expect(engine.evaluate('log(3,81)'), closeTo(4, 1e-12));
      expect(engine.evaluate('log_3(81)'), closeTo(4, 1e-12));
      expect(engine.evaluate('log(2,32)'), closeTo(5, 1e-12));
      expect(engine.evaluate('log(5,125)'), closeTo(3, 1e-12));
      expect(engine.evaluate('log(7,49)'), closeTo(2, 1e-12));
      expect(engine.evaluate('log2(32)'), 5);
      expect(engine.evaluate('log(100)+1'), 3);
    });

    test('powers, roots, factorial and fractions', () {
      expect(engine.evaluate('sqrt(144)'), 12);
      expect(engine.evaluate('cbrt(-27)'), closeTo(-3, 1e-12));
      expect(engine.evaluate('root(3,125)'), 5);
      expect(engine.evaluate('5!'), 120);
      expect(engine.evaluate('frac(3,4)'), .75);
      expect(fractionFor(1.75), '1 3/4');
      expect(fractionFor(.5), '1/2');
    });

    test('combinatorics, number theory, modulo, constants and Ans', () {
      expect(engine.evaluate('npr(5,2)'), 20);
      expect(engine.evaluate('ncr(5,2)'), 10);
      expect(engine.evaluate('gcd(18,24)'), 6);
      expect(engine.evaluate('lcm(6,8)'), 24);
      expect(engine.evaluate('mod(17,5)'), 2);
      expect(engine.evaluate('2pi'), closeTo(2 * 3.141592653589793, 1e-12));
      expect(engine.evaluate('ans+2', answer: 5), 7);
    });

    test('invalid expressions and mathematical domains report useful errors', () {
      expect(() => engine.evaluate('1/0'), throwsA(isA<CalculatorException>()));
      expect(() => engine.evaluate('log(1,10)'), throwsA(isA<CalculatorException>()));
      expect(() => engine.evaluate('log(2,-1)'), throwsA(isA<CalculatorException>()));
      expect(() => engine.evaluate('sqrt(-1)'), throwsA(isA<CalculatorException>()));
      expect(() => engine.evaluate('(2+3'), throwsA(isA<CalculatorException>()));
      expect(() => engine.evaluate('3+'), throwsA(isA<CalculatorException>()));
      expect(() => engine.evaluate('2.5!'), throwsA(isA<CalculatorException>()));
    });
  });

  test('controller keeps Ans, memory and calculation history', () {
    final controller = CalculatorController();
    expect(controller.evaluate('5+7'), 12);
    expect(controller.evaluate('ans*2'), 24);
    controller.addToMemory(24);
    controller.subtractFromMemory(4);
    expect(controller.recallMemory(), 20);
    expect(controller.history, hasLength(2));
    controller.clearMemory();
    expect(controller.recallMemory(), 0);
  });
}
