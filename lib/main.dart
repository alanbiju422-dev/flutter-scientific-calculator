import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator_controller.dart';
import 'calculator_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0C11),
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF151722),
        ),
        useMaterial3: true,
      ),
      home: const CalculatorHomePage(),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key});

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  final CalculatorController _calculator = CalculatorController();
  final ScrollController _expressionScrollController = ScrollController();

  String _expression = '';
  String _result = '0';
  String? _error;
  String? _helperHint;
  bool _scientific = false; // Standard mode by default
  bool _second = false;
  bool _fractionDisplay = false;
  bool _justEvaluated = false;
  AngleMode _angleMode = AngleMode.degrees;

  void _insert(String text, {String? hint}) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_justEvaluated) {
        if (RegExp(r'^[0-9.]$').hasMatch(text)) {
          _expression = '';
        } else if (RegExp(r'^[+\-*/^%×÷−]$').hasMatch(text)) {
          _expression = 'ans';
        }
        _justEvaluated = false;
      }
      if (_result == 'Error' && RegExp(r'^[0-9.]$').hasMatch(text)) {
        _expression = '';
      }
      _expression += text;
      _error = null;
      _helperHint = hint;
      _refreshPreview();
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_expressionScrollController.hasClients) {
        _expressionScrollController.animateTo(
          _expressionScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _refreshPreview() {
    final trimmed = _expression.trim();
    if (trimmed.isEmpty) {
      _result = '0';
      _error = null;
      return;
    }

    // Auto-balance open parentheses for live preview
    int openParens = 0;
    for (int i = 0; i < trimmed.length; i++) {
      if (trimmed[i] == '(') openParens++;
      if (trimmed[i] == ')') openParens--;
    }
    String evalExpr = trimmed;
    if (openParens > 0) {
      evalExpr = trimmed + (')' * openParens);
    }

    try {
      final value = CalculatorEngine().evaluate(
        evalExpr,
        angleMode: _angleMode,
        answer: _calculator.answer,
      );
      _result = _fractionDisplay ? fractionFor(value) : formatCalculatorNumber(value);
      _error = null;
    } on CalculatorException catch (e) {
      if (_isPartialExpression(trimmed)) {
        _error = null;
      } else {
        _error = e.message;
      }
    } catch (_) {
      if (!_isPartialExpression(trimmed)) {
        _error = 'Invalid expression';
      }
    }
  }

  bool _isPartialExpression(String s) {
    if (s.isEmpty) return true;
    final last = s[s.length - 1];
    return '+-*/^%(,×÷−'.contains(last) ||
        s.endsWith('sqrt(') ||
        s.endsWith('sin(') ||
        s.endsWith('cos(') ||
        s.endsWith('tan(') ||
        s.endsWith('log(') ||
        s.endsWith('ln(');
  }

  void _equals() {
    if (_expression.trim().isEmpty) return;

    // Automatically close any open parentheses before evaluation
    int openParens = 0;
    for (int i = 0; i < _expression.length; i++) {
      if (_expression[i] == '(') openParens++;
      if (_expression[i] == ')') openParens--;
    }
    if (openParens > 0) {
      _expression += (')' * openParens);
    }

    try {
      final value = _calculator.evaluate(_expression, angleMode: _angleMode);
      HapticFeedback.mediumImpact();
      setState(() {
        _result = _fractionDisplay ? fractionFor(value) : formatCalculatorNumber(value);
        _error = null;
        _helperHint = null;
        _justEvaluated = true;
      });
    } on CalculatorException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _result = 'Error';
        _error = e.message;
      });
    } catch (_) {
      HapticFeedback.heavyImpact();
      setState(() {
        _result = 'Error';
        _error = 'Invalid expression';
      });
    }
  }

  void _clear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _expression = '';
      _result = '0';
      _error = null;
      _helperHint = null;
      _justEvaluated = false;
    });
  }

  void _backspace() {
    HapticFeedback.lightImpact();
    if (_expression.isEmpty) return;
    setState(() {
      final functions = [
        'asinh(', 'acosh(', 'atanh(', 'asin(', 'acos(', 'atan(',
        'sinh(', 'cosh(', 'tanh(', 'sin(', 'cos(', 'tan(',
        'log2(', 'log(', 'ln(', 'sqrt(', 'cbrt(', 'root(',
        'exp(', 'pow10(', 'recip(', 'abs(', 'frac(', 'rand()',
        'npr(', 'ncr(', 'gcd(', 'lcm(', 'mod(', 'ans'
      ];
      bool removed = false;
      for (final f in functions) {
        if (_expression.endsWith(f)) {
          _expression = _expression.substring(0, _expression.length - f.length);
          removed = true;
          break;
        }
      }
      if (!removed) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
      _error = null;
      _refreshPreview();
    });
  }

  void _toggleSign() {
    HapticFeedback.lightImpact();
    if (_expression.isEmpty) {
      _insert('-');
      return;
    }
    setState(() {
      if (_expression.startsWith('-(') && _expression.endsWith(')')) {
        _expression = _expression.substring(2, _expression.length - 1);
      } else {
        _expression = '-($_expression)';
      }
      _refreshPreview();
    });
  }

  void _toggleAngleMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _angleMode = _angleMode == AngleMode.degrees ? AngleMode.radians : AngleMode.degrees;
      _refreshPreview();
    });
  }

  void _toggleSecond() {
    HapticFeedback.selectionClick();
    setState(() {
      _second = !_second;
    });
  }

  void _fractionToggle() {
    HapticFeedback.selectionClick();
    setState(() {
      _fractionDisplay = !_fractionDisplay;
      _refreshPreview();
    });
  }

  void _openHistory() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF11131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, color: Color(0xFF8B5CF6), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Calculation History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  if (_calculator.history.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _calculator.history.clear());
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF87171)),
                      label: const Text('Clear', style: TextStyle(color: Color(0xFFF87171))),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white10),
              Expanded(
                child: _calculator.history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calculate_outlined, size: 48, color: Colors.white.withValues(alpha: 0.15)),
                            const SizedBox(height: 12),
                            const Text(
                              'No calculations recorded yet',
                              style: TextStyle(color: Colors.white38, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _calculator.history.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                        itemBuilder: (context, index) {
                          final item = _calculator.history[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            title: Text(
                              item.expression,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                            ),
                            trailing: Text(
                              '= ${formatCalculatorNumber(item.result)}',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _expression = item.expression;
                                _result = formatCalculatorNumber(item.result);
                                _error = null;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMoreFunctions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF11131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.functions_rounded, color: Color(0xFF8B5CF6), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Advanced Scientific Functions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSectionTitle('LOGARITHMS (ANY BASE SUPPORTED)'),
              _buildFunctionGrid([
                _FuncItem('logᵦ(x) Any Base', 'log('),
                _FuncItem('log₂(x) Base 2', 'log2('),
                _FuncItem('log(x) Base 10', 'log('),
                _FuncItem('ln(x) Base e', 'ln('),
              ]),
              const SizedBox(height: 16),
              _buildSectionTitle('HYPERBOLIC TRIGONOMETRY'),
              _buildFunctionGrid([
                _FuncItem('sinh', 'sinh('),
                _FuncItem('cosh', 'cosh('),
                _FuncItem('tanh', 'tanh('),
                _FuncItem('asinh', 'asinh('),
                _FuncItem('acosh', 'acosh('),
                _FuncItem('atanh', 'atanh('),
              ]),
              const SizedBox(height: 16),
              _buildSectionTitle('NUMBER THEORY & DISCRETE MATH'),
              _buildFunctionGrid([
                _FuncItem('GCD(a,b)', 'gcd('),
                _FuncItem('LCM(a,b)', 'lcm('),
                _FuncItem('mod(a,b)', 'mod('),
                _FuncItem('nPr(n,r)', 'npr('),
                _FuncItem('nCr(n,r)', 'ncr('),
                _FuncItem('frac(a,b)', 'frac('),
              ]),
              const SizedBox(height: 16),
              _buildSectionTitle('POWERS, ROOTS & RANDOM'),
              _buildFunctionGrid([
                _FuncItem('cbrt(x)', 'cbrt('),
                _FuncItem('root(n,x)', 'root('),
                _FuncItem('abs(x)', 'abs('),
                _FuncItem('rand()', 'rand()'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B5CF6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFunctionGrid(List<_FuncItem> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return ActionChip(
          backgroundColor: const Color(0xFF1E2130),
          side: const BorderSide(color: Color(0xFF2E334A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          label: Text(
            item.label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          onPressed: () {
            Navigator.pop(context);
            final hint = item.label.contains('Any Base')
                ? 'Tip: Enter log(base, value) — e.g. log(3, 81)'
                : null;
            _insert(item.insertText, hint: hint);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C11),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Top App Bar: App name "Calculator", Mode Toggle, History
                _buildTopHeader(),

                // Multi-line Display Section (Previous expression & Large result)
                _buildDisplayPanel(),

                // Calculator Keypad (Standard or Scientific)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                    child: _scientific ? _buildScientificPad() : _buildStandardPad(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          // App Name with Electric Blue to Purple Accent Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x408B5CF6),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Calculator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Smooth Segmented Toggle between Standard and Scientific modes
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151824),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTab('Standard', !_scientific, () => setState(() => _scientific = false)),
                _buildModeTab('Scientific', _scientific, () => setState(() => _scientific = true)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Calculation History Access Button
          IconButton(
            icon: Badge(
              isLabelVisible: _calculator.history.isNotEmpty,
              label: Text('${_calculator.history.length}'),
              backgroundColor: const Color(0xFF8B5CF6),
              child: const Icon(Icons.history_rounded, color: Colors.white70, size: 23),
            ),
            tooltip: 'History',
            onPressed: _openHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x403B82F6),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF07080C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E2234), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Annunciator row (in scientific mode)
          if (_scientific)
            Row(
              children: [
                // DEG / RAD Toggle Chip
                InkWell(
                  onTap: _toggleAngleMode,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151824),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _angleMode == AngleMode.degrees ? 'DEG' : 'RAD',
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 2nd Indicator Badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _second ? const Color(0x338B5CF6) : const Color(0xFF12141F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _second ? const Color(0xFF8B5CF6) : Colors.transparent),
                  ),
                  child: Text(
                    '2nd',
                    style: TextStyle(
                      color: _second ? const Color(0xFFC4B5FD) : Colors.white24,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Fraction Display Toggle (F⬄D)
                InkWell(
                  onTap: _fractionToggle,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _fractionDisplay ? const Color(0x33A855F7) : const Color(0xFF12141F),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _fractionDisplay ? const Color(0xFFA855F7) : Colors.transparent),
                    ),
                    child: Text(
                      'F⬄D',
                      style: TextStyle(
                        color: _fractionDisplay ? const Color(0xFFD8B4FE) : Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (_calculator.answer != 0)
                  Text(
                    'Ans = ${formatCalculatorNumber(_calculator.answer)}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
              ],
            ),
          if (_scientific) const SizedBox(height: 6),

          // Expression & Calculation Result View
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: _result));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Result copied to clipboard!'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Smaller Previous Expression
                SingleChildScrollView(
                  controller: _expressionScrollController,
                  scrollDirection: Axis.horizontal,
                  reverse: false,
                  child: Text(
                    _expression.isEmpty ? '0' : _expression,
                    style: TextStyle(
                      color: _expression.isEmpty ? Colors.white30 : const Color(0xFF94A3B8),
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                if (_helperHint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _helperHint!,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 4),

                // Large Calculation Result Display
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _result,
                    style: TextStyle(
                      color: _result == 'Error' ? const Color(0xFFF87171) : Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Standard Calculator Keypad (4 columns x 5 rows)
  // Standard calculator buttons: AC, DEL, %, ÷, ×, −, +, decimal, numbers and equals.
  Widget _buildStandardPad() {
    return Column(
      children: [
        _buildRow([
          _KeySpec('AC', _clear, type: _KeyType.clear),
          _KeySpec('DEL', _backspace, type: _KeyType.delete),
          _KeySpec('%', () => _insert('%'), type: _KeyType.utility),
          _KeySpec('÷', () => _insert('÷'), type: _KeyType.operator),
        ]),
        _buildRow([
          _KeySpec('7', () => _insert('7')),
          _KeySpec('8', () => _insert('8')),
          _KeySpec('9', () => _insert('9')),
          _KeySpec('×', () => _insert('×'), type: _KeyType.operator),
        ]),
        _buildRow([
          _KeySpec('4', () => _insert('4')),
          _KeySpec('5', () => _insert('5')),
          _KeySpec('6', () => _insert('6')),
          _KeySpec('−', () => _insert('−'), type: _KeyType.operator),
        ]),
        _buildRow([
          _KeySpec('1', () => _insert('1')),
          _KeySpec('2', () => _insert('2')),
          _KeySpec('3', () => _insert('3')),
          _KeySpec('+', () => _insert('+'), type: _KeyType.operator),
        ]),
        _buildRow([
          _KeySpec('0', () => _insert('0'), flex: 2),
          _KeySpec('.', () => _insert('.')),
          _KeySpec('=', _equals, type: _KeyType.equals),
        ]),
      ],
    );
  }

  // Scientific Calculator Keypad:
  // sin, cos, tan, log, ln, square root, powers and brackets, plus standard buttons.
  Widget _buildScientificPad() {
    return Column(
      children: [
        // Quick Bar: Advanced Functions Sheet, Comma
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: _buildBarButton('f(x) Advanced Functions', Icons.auto_awesome_rounded, _openMoreFunctions),
              ),
              const SizedBox(width: 8),
              _buildBarButton('Ans', null, () => _insert('ans')),
              const SizedBox(width: 8),
              _buildBarButton(',', null, () => _insert(',')),
            ],
          ),
        ),

        // Keypad Grid Rows (7 rows x 5 columns)
        Expanded(
          child: Column(
            children: [
              // Row 1: 2nd, sin, cos, tan, DEG/RAD
              _buildRow([
                _KeySpec(_second ? '2nd*' : '2nd', _toggleSecond, type: _second ? _KeyType.secondActive : _KeyType.scientific),
                _KeySpec(_second ? 'sin⁻¹' : 'sin', () => _insert(_second ? 'asin(' : 'sin('), type: _KeyType.scientific),
                _KeySpec(_second ? 'cos⁻¹' : 'cos', () => _insert(_second ? 'acos(' : 'cos('), type: _KeyType.scientific),
                _KeySpec(_second ? 'tan⁻¹' : 'tan', () => _insert(_second ? 'atan(' : 'tan('), type: _KeyType.scientific),
                _KeySpec(_angleMode == AngleMode.degrees ? 'DEG' : 'RAD', _toggleAngleMode, type: _KeyType.utility),
              ]),

              // Row 2: ln, log, logᵦ, powers (xʸ/x²), square root (√)
              _buildRow([
                _KeySpec(_second ? 'eˣ' : 'ln', () => _insert(_second ? 'exp(' : 'ln('), type: _KeyType.scientific),
                _KeySpec(_second ? '10ˣ' : 'log', () => _insert(_second ? 'pow10(' : 'log('), type: _KeyType.scientific),
                _KeySpec(_second ? 'xʸ' : 'logᵦ', () {
                  if (_second) {
                    _insert('^');
                  } else {
                    _insert('log(', hint: 'Tip: log(base, value) — e.g. log(3, 81) = 4');
                  }
                }, type: _KeyType.scientific),
                _KeySpec(_second ? 'x³' : 'x²', () => _insert(_second ? '^3' : '^2'), type: _KeyType.scientific),
                _KeySpec(_second ? '∛x' : '√x', () => _insert(_second ? 'cbrt(' : 'sqrt('), type: _KeyType.scientific),
              ]),

              // Row 3: Brackets (, ), powers/constants (xʸ, π, e)
              _buildRow([
                _KeySpec('(', () => _insert('('), type: _KeyType.scientific),
                _KeySpec(')', () => _insert(')'), type: _KeyType.scientific),
                _KeySpec('^', () => _insert('^'), type: _KeyType.scientific),
                _KeySpec(_second ? 'rand' : 'π', () => _insert(_second ? 'rand()' : 'π'), type: _KeyType.scientific),
                _KeySpec(_second ? 'n!' : 'e', () => _insert(_second ? '!' : 'e'), type: _KeyType.scientific),
              ]),

              // Row 4: AC, 7, 8, 9, ÷
              _buildRow([
                _KeySpec('AC', _clear, type: _KeyType.clear),
                _KeySpec('7', () => _insert('7')),
                _KeySpec('8', () => _insert('8')),
                _KeySpec('9', () => _insert('9')),
                _KeySpec('÷', () => _insert('÷'), type: _KeyType.operator),
              ]),

              // Row 5: DEL, 4, 5, 6, ×
              _buildRow([
                _KeySpec('DEL', _backspace, type: _KeyType.delete),
                _KeySpec('4', () => _insert('4')),
                _KeySpec('5', () => _insert('5')),
                _KeySpec('6', () => _insert('6')),
                _KeySpec('×', () => _insert('×'), type: _KeyType.operator),
              ]),

              // Row 6: +/-, 1, 2, 3, −
              _buildRow([
                _KeySpec('+/-', _toggleSign, type: _KeyType.utility),
                _KeySpec('1', () => _insert('1')),
                _KeySpec('2', () => _insert('2')),
                _KeySpec('3', () => _insert('3')),
                _KeySpec('−', () => _insert('−'), type: _KeyType.operator),
              ]),

              // Row 7: %, 0, ., +, =
              _buildRow([
                _KeySpec('%', () => _insert('%'), type: _KeyType.utility),
                _KeySpec('0', () => _insert('0')),
                _KeySpec('.', () => _insert('.')),
                _KeySpec('+', () => _insert('+'), type: _KeyType.operator),
                _KeySpec('=', _equals, type: _KeyType.equals),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarButton(String label, IconData? icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF141724),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFC4B5FD),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<_KeySpec> keys) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        child: Row(
          children: keys.map((key) {
            return Expanded(
              flex: key.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.5),
                child: _GradientCalcButton(keySpec: key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

enum _KeyType {
  number,
  operator,
  equals,
  clear,
  delete,
  scientific,
  secondActive,
  utility,
}

class _KeySpec {
  final String label;
  final VoidCallback onPressed;
  final _KeyType type;
  final int flex;

  const _KeySpec(
    this.label,
    this.onPressed, {
    this.type = _KeyType.number,
    this.flex = 1,
  });
}

class _FuncItem {
  final String label;
  final String insertText;
  const _FuncItem(this.label, this.insertText);
}

class _GradientCalcButton extends StatelessWidget {
  final _KeySpec keySpec;

  const _GradientCalcButton({required this.keySpec});

  @override
  Widget build(BuildContext context) {
    Gradient gradient;
    Color textColor;
    Border border;
    List<BoxShadow> shadows;

    switch (keySpec.type) {
      case _KeyType.equals:
        // Flagship button: Electric Blue to Purple gradient with soft ambient glow
        gradient = const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.white;
        border = Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1);
        shadows = const [
          BoxShadow(
            color: Color(0x558B5CF6),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ];
        break;

      case _KeyType.operator:
        // Electric Blue / Purple tinted deep slate
        gradient = const LinearGradient(
          colors: [Color(0xFF20263D), Color(0xFF161A2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = const Color(0xFF60A5FA); // Electric Blue glyph
        border = Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.35), width: 1);
        shadows = const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ];
        break;

      case _KeyType.clear:
        // AC: Crimson / Coral gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF381A22), Color(0xFF261117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = const Color(0xFFF87171);
        border = Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35), width: 1);
        shadows = const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
        ];
        break;

      case _KeyType.delete:
        // DEL: Warm amber / terracotta gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF332418), Color(0xFF22170F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = const Color(0xFFFBBF24);
        border = Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), width: 1);
        shadows = const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
        ];
        break;

      case _KeyType.secondActive:
        // 2nd Active: Glowing Purple to Pink gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.white;
        border = Border.all(color: Colors.white, width: 1.2);
        shadows = const [
          BoxShadow(
            color: Color(0x668B5CF6),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ];
        break;

      case _KeyType.scientific:
        // Subtle dark charcoal gradient with soft purple glyphs
        gradient = const LinearGradient(
          colors: [Color(0xFF181B26), Color(0xFF11131C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = const Color(0xFFC4B5FD); // Soft Purple/Lavender
        border = Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.8);
        shadows = const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
        ];
        break;

      case _KeyType.utility:
        // Slate utility keys (%, +/-, DEG/RAD)
        gradient = const LinearGradient(
          colors: [Color(0xFF222736), Color(0xFF181B26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = const Color(0xFFE2E8F0);
        border = Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.8);
        shadows = const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
        ];
        break;

      case _KeyType.number:
        // Charcoal gradient for tactile number keys 0-9, .
        gradient = const LinearGradient(
          colors: [Color(0xFF1C1E2A), Color(0xFF141620)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.white;
        border = Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.8);
        shadows = const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ];
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: keySpec.onPressed,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
          highlightColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                keySpec.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: keySpec.type == _KeyType.scientific
                      ? 15
                      : (keySpec.type == _KeyType.operator || keySpec.type == _KeyType.equals ? 24 : 21),
                  fontWeight: (keySpec.type == _KeyType.number || keySpec.type == _KeyType.equals)
                      ? FontWeight.bold
                      : FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
