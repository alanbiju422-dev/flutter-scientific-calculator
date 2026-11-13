import 'dart:math' as math;

enum AngleMode { degrees, radians }

class CalculatorException implements Exception {
  const CalculatorException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A small recursive-descent expression engine. It supports implicit
/// multiplication, parentheses, unary signs, postfix factorial/percent, and
/// function calls with comma-separated arguments.
class CalculatorEngine {
  CalculatorEngine({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  late List<String> _tokens;
  int _position = 0;
  AngleMode _angleMode = AngleMode.degrees;
  double _answer = 0;

  double evaluate(String expression,
      {AngleMode angleMode = AngleMode.degrees, double answer = 0}) {
    final normalized = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('√', 'sqrt')
        .replaceAllMapped(
          RegExp(r'log_([0-9.]+)\s*\(\s*([^)]+)\s*\)', caseSensitive: false),
          (m) => 'log(${m[1]}, ${m[2]})',
        );
    _tokens = _tokenize(normalized);
    _position = 0;
    _angleMode = angleMode;
    _answer = answer;
    if (_tokens.isEmpty) throw const CalculatorException('Enter an expression');
    final result = _parseAdditive();
    if (_position != _tokens.length) {
      throw CalculatorException('Unexpected "$_peek"');
    }
    if (!result.isFinite) throw const CalculatorException('Result is out of range');
    return result;
  }

  List<String> _tokenize(String source) {
    final tokens = <String>[];
    var i = 0;
    while (i < source.length) {
      final c = source[i];
      if (c.trim().isEmpty) {
        i++;
      } else if (_isDigit(c) || (c == '.' && i + 1 < source.length && _isDigit(source[i + 1]))) {
        final start = i++;
        while (i < source.length && (_isDigit(source[i]) || source[i] == '.')) { i++; }
        if (i < source.length && (source[i] == 'e' || source[i] == 'E')) {
          i++;
          if (i < source.length && (source[i] == '+' || source[i] == '-')) i++;
          final exponentStart = i;
          while (i < source.length && _isDigit(source[i])) { i++; }
          if (i == exponentStart) throw const CalculatorException('Invalid scientific notation');
        }
        final token = source.substring(start, i);
        if (double.tryParse(token) == null) throw CalculatorException('Invalid number "$token"');
        tokens.add(token);
      } else if (_isIdentifierStart(c)) {
        final start = i++;
        while (i < source.length && _isIdentifierPart(source[i])) { i++; }
        tokens.add(source.substring(start, i).toLowerCase());
      } else if ('+-*/^!%(),'.contains(c)) {
        tokens.add(c);
        i++;
      } else {
        throw CalculatorException('Unsupported character "$c"');
      }
    }
    return tokens;
  }
  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool _isIdentifierStart(String c) =>
      (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90) ||
      (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122);
  bool _isIdentifierPart(String c) => _isIdentifierStart(c) || _isDigit(c) || c == '_';

  String? get _peek => _position < _tokens.length ? _tokens[_position] : null;
  String _take() => _tokens[_position++];
  bool _accept(String token) {
    if (_peek == token) { _position++; return true; }
    return false;
  }

  double _parseAdditive() {
    var value = _parseMultiplicative();
    while (_peek == '+' || _peek == '-') {
      final op = _take();
      final rhs = _parseMultiplicative();
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  double _parseMultiplicative() {
    var value = _parseUnary();
    while (true) {
      if (_accept('*')) {
        value *= _parseUnary();
      } else if (_accept('/')) {
        final rhs = _parseUnary();
        if (rhs == 0) throw const CalculatorException('Cannot divide by zero');
        value /= rhs;
      } else if (_peek == 'mod') {
        _take();
        value %= _parseUnary();
      } else if (_startsPrimary(_peek)) {
        // 2π, 2(3+4), and 2sin(30) are treated as multiplication.
        value *= _parseUnary();
      } else {
        return value;
      }
    }
  }

  bool _startsPrimary(String? token) => token == '(' ||
      (token != null && token.isNotEmpty && (_isDigit(token[0]) || token[0] == '.' || _isIdentifierStart(token[0])));

  double _parseUnary() {
    if (_accept('+')) return _parseUnary();
    if (_accept('-')) return -_parseUnary();
    return _parsePower();
  }

  double _parsePower() {
    var value = _parsePostfix();
    if (_accept('^')) value = math.pow(value, _parseUnary()).toDouble();
    return value;
  }

  double _parsePostfix() {
    var value = _parsePrimary();
    while (_peek == '!' || _peek == '%') {
      if (_accept('!')) {
        final n = _integer(value, 'Factorial requires a whole number');
        if (n < 0 || n > 170) throw const CalculatorException('Factorial is defined for integers 0 to 170');
        var result = 1.0;
        for (var i = 2; i <= n; i++) { result *= i; }
        value = result;
      } else {
        _take();
        value /= 100;
      }
    }
    return value;
  }

  double _parsePrimary() {
    final token = _peek;
    if (token == null) throw const CalculatorException('Incomplete expression');
    if (_accept('(')) {
      final value = _parseAdditive();
      if (!_accept(')')) throw const CalculatorException('Missing closing parenthesis');
      return value;
    }
    if (_isDigit(token[0]) || token[0] == '.') {
      _take();
      return double.parse(token);
    }
    if (_isIdentifierStart(token[0])) {
      final name = _take();
      if (name == 'pi') return math.pi;
      if (name == 'e') return math.e;
      if (name == 'ans') return _answer;
      if (!_accept('(')) throw CalculatorException('Unknown constant "$name"');
      final args = <double>[];
      if (!_accept(')')) {
        do { args.add(_parseAdditive()); } while (_accept(','));
        if (!_accept(')')) throw const CalculatorException('Missing closing parenthesis');
      }
      return _call(name, args);
    }
    throw CalculatorException('Unexpected "$token"');
  }

  int _integer(double value, String message) {
    if (!value.isFinite || value != value.roundToDouble()) throw CalculatorException(message);
    return value.toInt();
  }

  double _one(String name, List<double> a) {
    if (a.length != 1) throw CalculatorException('$name expects one argument');
    return a[0];
  }

  double _call(String name, List<double> a) {
    double arg() => _one(name, a);
    double angle(double value) => _angleMode == AngleMode.degrees ? value * math.pi / 180 : value;
    double inverseAngle(double value) => _angleMode == AngleMode.degrees ? value * 180 / math.pi : value;
    bool count(int n) => a.length == n;
    switch (name) {
      case 'sin': return math.sin(angle(arg()));
      case 'cos': return math.cos(angle(arg()));
      case 'tan':
        final x = angle(arg());
        if ((math.cos(x)).abs() < 1e-14) throw const CalculatorException('Tangent is undefined at this angle');
        return math.tan(x);
      case 'asin': return inverseAngle(math.asin(_unit(arg(), 'asin')));
      case 'acos': return inverseAngle(math.acos(_unit(arg(), 'acos')));
      case 'atan': return inverseAngle(math.atan(arg()));
      case 'sinh':
        return _sinh(arg());
      case 'cosh':
        return _cosh(arg());
      case 'tanh':
        final x = arg().abs();
        final result = 1 - 2 / (math.exp(2 * x) + 1);
        return a[0] < 0 ? -result : result;
      case 'asinh':
        final x = arg();
        final magnitude = x.abs();
        final result = magnitude > 1e150
            ? math.log(magnitude) + math.ln2
            : math.log(magnitude + math.sqrt(magnitude * magnitude + 1));
        return x < 0 ? -result : result;
      case 'acosh':
        final x = arg(); if (x < 1) throw const CalculatorException('acosh requires x ≥ 1');
        return x > 1e150 ? math.log(x) + math.ln2 : math.log(x + math.sqrt(x * x - 1));
      case 'atanh':
        final x = arg(); if (x.abs() >= 1) throw const CalculatorException('atanh requires -1 < x < 1');
        return 0.5 * math.log((1 + x) / (1 - x));
      case 'log':
        if (a.length == 1) return math.log(_positive(arg(), 'log')) / math.ln10;
        if (a.length == 2) {
          final base = _positive(a[0], 'Log base');
          if (base == 1) throw const CalculatorException('Log base cannot be 1');
          return math.log(_positive(a[1], 'Log argument')) / math.log(base);
        }
        throw const CalculatorException('log expects one argument or base and argument');
      case 'ln': return math.log(_positive(arg(), 'ln'));
      case 'log2': return math.log(_positive(arg(), 'log2')) / math.ln2;
      case 'sqrt': return math.sqrt(_nonnegative(arg(), 'sqrt'));
      case 'cbrt': return _cbrt(arg());
      case 'root':
        if (!count(2)) throw const CalculatorException('root expects degree and value');
        final n = _integer(a[0], 'Root degree must be an integer');
        if (n == 0) throw const CalculatorException('Root degree cannot be zero');
        if (a[1] < 0 && n.isEven) throw const CalculatorException('Even root of a negative number');
        return a[1] < 0 ? -math.pow(-a[1], 1 / n.abs()).toDouble() : math.pow(a[1], 1 / n.abs()).toDouble();
      case 'abs': return arg().abs();
      case 'recip':
        final x = arg(); if (x == 0) throw const CalculatorException('Reciprocal of zero is undefined');
        return 1 / x;
      case 'exp': return math.exp(arg());
      case 'pow10': return math.pow(10, arg()).toDouble();
      case 'mod':
        if (!count(2)) throw const CalculatorException('mod expects two arguments');
        if (a[1] == 0) throw const CalculatorException('Modulo by zero');
        return a[0] % a[1];
      case 'npr': return _permutation(a);
      case 'ncr': return _combination(a);
      case 'gcd': return _gcdLcm(a, lcm: false);
      case 'lcm': return _gcdLcm(a, lcm: true);
      case 'rand':
        if (a.isNotEmpty) throw const CalculatorException('rand expects no arguments');
        return _random.nextDouble();
      case 'frac':
        if (!count(2)) throw const CalculatorException('frac expects numerator and denominator');
        if (a[1] == 0) throw const CalculatorException('Fraction denominator cannot be zero');
        return a[0] / a[1];
      default: throw CalculatorException('Unknown function "$name"');
    }
  }

  double _unit(double x, String name) {
    if (x < -1 || x > 1) throw CalculatorException('$name requires a value from -1 to 1');
    return x;
  }
  double _positive(double x, String name) {
    if (x <= 0) throw CalculatorException('$name requires a value greater than zero');
    return x;
  }
  double _nonnegative(double x, String name) {
    if (x < 0) throw CalculatorException('$name requires a non-negative value');
    return x;
  }
  double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
  double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;
  double _cbrt(double x) => x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

  List<int> _pair(List<double> a, String name) {
    if (a.length != 2) throw CalculatorException('$name expects two integers');
    return [_integer(a[0], '$name requires integers'), _integer(a[1], '$name requires integers')];
  }
  double _permutation(List<double> a) {
    final p = _pair(a, 'nPr'); final n = p[0], r = p[1];
    if (n < 0 || r < 0 || r > n) throw const CalculatorException('Require n ≥ r ≥ 0');
    var result = 1.0; for (var i = n - r + 1; i <= n; i++) { result *= i; }
    return result;
  }
  double _combination(List<double> a) {
    final p = _pair(a, 'nCr'); final n = p[0], r = p[1];
    if (n < 0 || r < 0 || r > n) throw const CalculatorException('Require n ≥ r ≥ 0');
    final k = math.min(r, n - r); var result = 1.0;
    for (var i = 1; i <= k; i++) { result = result * (n - k + i) / i; }
    return result;
  }
  double _gcdLcm(List<double> a, {required bool lcm}) {
    final p = _pair(a, lcm ? 'lcm' : 'gcd');
    var x = p[0].abs(), y = p[1].abs(); final original = x * y;
    while (y != 0) { final t = x % y; x = y; y = t; }
    return lcm ? (x == 0 ? 0 : original / x) : x.toDouble();
  }
}

String formatCalculatorNumber(double value) {
  if (!value.isFinite) return 'Error';
  if (value == 0) return '0';
  final text = value.toStringAsPrecision(12);
  final parsed = double.parse(text);
  if (parsed == parsed.truncateToDouble() && parsed.abs() < 1e15) return parsed.toInt().toString();
  if (text.contains('e')) return text.replaceFirst(RegExp(r'0+e'), 'e');
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String fractionFor(double value) {
  if (!value.isFinite) return 'Error';
  final sign = value < 0 ? '-' : '';
  final x = value.abs();
  var h1 = 1, h2 = 0, k1 = 0, k2 = 1;
  var b = x;
  for (var i = 0; i < 32; i++) {
    final a = b.floor();
    final h = a * h1 + h2, k = a * k1 + k2;
    if (k > 100000 || (h / k - x).abs() < 1e-10) {
      if (k == 0) return formatCalculatorNumber(value);
      final whole = h ~/ k, remainder = h % k;
      if (remainder == 0) return '$sign$whole';
      if (whole == 0) return '$sign$remainder/$k';
      return '$sign$whole $remainder/$k';
    }
    h2 = h1; h1 = h; k2 = k1; k1 = k;
    final remainder = b - a;
    if (remainder == 0) break;
    b = 1 / remainder;
  }
  return formatCalculatorNumber(value);
}

