// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  print('====================================');
  print('       CLI BASIC CALCULATOR         ');
  print('====================================');
  print('Supported operations: +, -, *, /, %');
  print('Type "exit" or "quit" to stop.');
  print('------------------------------------');

  while (true) {
    stdout.write('\nEnter first number: ');
    final String? input1 = stdin.readLineSync();
    if (input1 == null || input1.trim().toLowerCase() == 'exit' || input1.trim().toLowerCase() == 'quit') {
      print('Exiting calculator. Goodbye!');
      break;
    }

    final double? num1 = double.tryParse(input1.trim());
    if (num1 == null) {
      print('Invalid number. Please try again.');
      continue;
    }

    stdout.write('Enter operator (+, -, *, /, %): ');
    final String? op = stdin.readLineSync()?.trim();
    if (op == null || !['+', '-', '*', '/', '%'].contains(op)) {
      print('Invalid operator. Supported operators: +, -, *, /, %');
      continue;
    }

    stdout.write('Enter second number: ');
    final String? input2 = stdin.readLineSync();
    final double? num2 = double.tryParse(input2?.trim() ?? '');
    if (num2 == null) {
      print('Invalid number. Please try again.');
      continue;
    }

    if (op == '/' && num2 == 0) {
      print('Error: Division by zero is not allowed.');
      continue;
    }

    double result = 0;
    switch (op) {
      case '+':
        result = num1 + num2;
        break;
      case '-':
        result = num1 - num2;
        break;
      case '*':
        result = num1 * num2;
        break;
      case '/':
        result = num1 / num2;
        break;
      case '%':
        result = num1 % num2;
        break;
    }

    print('Result: $num1 $op $num2 = ${formatNumber(result)}');
  }
}

String formatNumber(double n) {
  if (n == n.truncateToDouble()) {
    return n.toInt().toString();
  }
  return n.toString();
}
