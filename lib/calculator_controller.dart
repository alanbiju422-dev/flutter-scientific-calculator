import 'calculator_engine.dart';

class CalculationRecord {
  const CalculationRecord(this.expression, this.result);
  final String expression;
  final double result;
}

/// Holds answer, memory, and history independently of the calculator widgets.
class CalculatorController {
  CalculatorController({CalculatorEngine? engine}) : _engine = engine ?? CalculatorEngine();
  final CalculatorEngine _engine;
  double answer = 0;
  double memory = 0;
  final List<CalculationRecord> history = [];

  double evaluate(String expression, {AngleMode angleMode = AngleMode.degrees}) {
    final result = _engine.evaluate(expression, angleMode: angleMode, answer: answer);
    answer = result;
    history.insert(0, CalculationRecord(expression, result));
    if (history.length > 50) history.removeLast();
    return result;
  }

  void clearMemory() => memory = 0;
  double recallMemory() => memory;
  void addToMemory(double value) => memory += value;
  void subtractFromMemory(double value) => memory -= value;
}
