
import 'dart:math' as math;

class CalcResult {
  final String? value;
  final String? error;
  final String? sub;
  final String kind;
  const CalcResult({this.value, this.error, this.sub, this.kind = 'display'});
  bool get isError => error != null;
}

class Engine {
  double memory   = 0.0;
  String angleMode = 'DEG'; // DEG | RAD | GRAD
  final List<String> history = [];

  double _operand1 = 0;
  String? _operator;
  String _current  = '0';
  bool   _newNum   = true;
  String _expr     = '';

  // ── angle helpers ──────────────────────────────────────────────
  double _toRad(double x) {
    if (angleMode == 'DEG')  return x * math.pi / 180;
    if (angleMode == 'GRAD') return x * math.pi / 200;
    return x;
  }
  double _fromRad(double x) {
    if (angleMode == 'DEG')  return x * 180 / math.pi;
    if (angleMode == 'GRAD') return x * 200 / math.pi;
    return x;
  }

  // ── format ─────────────────────────────────────────────────────
  String fmt(double v) {
    if (v.isNaN)      return 'NaN';
    if (v.isInfinite) return v > 0 ? '∞' : '-∞';
    if (v == v.truncateToDouble() && v.abs() < 1e15) return v.toInt().toString();
    if (v.abs() >= 1e12 || (v.abs() < 1e-6 && v != 0))
      return v.toStringAsExponential(6);
    return v.toStringAsPrecision(10)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
  }

  // ── main press handler ─────────────────────────────────────────
  CalcResult press(String k) {
    try {
      return _handle(k);
    } catch (e) {
      _reset();
      return CalcResult(value: 'Error', error: e.toString(), kind: 'error');
    }
  }

  CalcResult _handle(String k) {
    // Clear
    if (k == 'AC') { _reset(); return _disp('0', ''); }
    if (k == 'C')  { _current = '0'; _newNum = true; return _disp('0', _expr); }
    if (k == '⌫') {
      if (!_newNum) {
        _current = _current.length > 1 ? _current.substring(0, _current.length - 1) : '0';
        if (_current == '-') _current = '0';
      }
      return _disp(_current, _expr);
    }

    // Memory
    if (k == 'MC') { memory = 0; return _disp(_current, 'M cleared'); }
    if (k == 'MR') { _current = fmt(memory); _newNum = false; return _disp(_current, 'MR = ${fmt(memory)}'); }
    if (k == 'M+') { memory += double.parse(_current); return _disp(_current, 'M = ${fmt(memory)}'); }
    if (k == 'M-') { memory -= double.parse(_current); return _disp(_current, 'M = ${fmt(memory)}'); }
    if (k == 'MS') { memory = double.parse(_current);  return _disp(_current, 'MS = ${fmt(memory)}'); }

    // Angle mode
    if (k == 'DEG' || k == 'RAD' || k == 'GRAD') {
      angleMode = k;
      return CalcResult(value: _current, sub: k, kind: 'mode');
    }

    // Constants
    const constants = {'π': math.pi, 'e': math.e};
    final phi = (1 + math.sqrt(5)) / 2;
    if (k == 'π') { _current = fmt(math.pi); _newNum = false; return _disp(_current, 'π'); }
    if (k == 'e') { _current = fmt(math.e);  _newNum = false; return _disp(_current, 'e'); }
    if (k == 'φ') { _current = fmt(phi);     _newNum = false; return _disp(_current, 'φ'); }
    if (k == 'Rand') {
      _current = fmt(math.Random().nextDouble()); _newNum = false;
      return _disp(_current, 'Rand');
    }

    // Digits
    if (RegExp(r'^[0-9.]$').hasMatch(k)) {
      if (_newNum) {
        _current = k == '.' ? '0.' : k; _newNum = false;
      } else {
        if (k == '.' && _current.contains('.')) return _disp(_current, _expr);
        _current = (_current == '0' && k != '.') ? k : (_current + k);
      }
      return _disp(_current, _expr);
    }

    // Unary functions
    final x = double.tryParse(_current) ?? 0;
    final Map<String, double Function(double)> unary = {
      'x²':    (v) => v * v,
      'x³':    (v) => v * v * v,
      '√':     (v) => math.sqrt(v),
      '∛':     (v) => v < 0 ? -math.pow(-v, 1/3).toDouble() : math.pow(v, 1/3).toDouble(),
      '1/x':   (v) => 1 / v,
      'x!':    (v) => _factorial(v.toInt()).toDouble(),
      '±':     (v) => -v,
      '%':     (v) => v / 100,
      'sin':   (v) => math.sin(_toRad(v)),
      'cos':   (v) => math.cos(_toRad(v)),
      'tan':   (v) => math.tan(_toRad(v)),
      'sin⁻¹': (v) => _fromRad(math.asin(v)),
      'cos⁻¹': (v) => _fromRad(math.acos(v)),
      'tan⁻¹': (v) => _fromRad(math.atan(v)),
      'sinh':  (v) => (math.exp(v) - math.exp(-v)) / 2,
      'cosh':  (v) => (math.exp(v) + math.exp(-v)) / 2,
      'tanh':  (v) { final e2 = math.exp(2 * v); return (e2 - 1) / (e2 + 1); },
      'ln':    (v) => math.log(v),
      'log':   (v) => math.log(v) / math.ln10,
      'log₂':  (v) => math.log(v) / math.log2e,
      'eˣ':    (v) => math.exp(v),
      '10ˣ':   (v) => math.pow(10, v).toDouble(),
      '2ˣ':    (v) => math.pow(2, v).toDouble(),
      'abs':   (v) => v.abs(),
      'ceil':  (v) => v.ceilToDouble(),
      'floor': (v) => v.floorToDouble(),
    };
    if (unary.containsKey(k)) {
      final r = unary[k]!(x);
      _expr    = '$k(${fmt(x)}) =';
      _current = fmt(r); _newNum = true;
      _addHistory('$_expr $_current');
      return CalcResult(value: _current, sub: _expr, kind: 'display');
    }

    // Binary
    const binaryOps = {'+', '−', '-', '×', '÷', '^', 'xⁿ', 'ˣ√y', 'mod', 'nCr', 'nPr'};
    if (binaryOps.contains(k)) {
      if (_operator != null && !_newNum) {
        final r = _binary(_operand1, _operator!, x);
        _current = fmt(r); _operand1 = r;
      } else {
        _operand1 = x;
      }
      _operator = k; _newNum = true;
      _expr = '${fmt(_operand1)} $k';
      return _disp(_current, _expr);
    }

    // Equals
    if (k == '=') {
      if (_operator != null) {
        final v2  = double.tryParse(_current) ?? 0;
        final r   = _binary(_operand1, _operator!, v2);
        final exp = '${fmt(_operand1)} $_operator ${fmt(v2)} =';
        _addHistory('$exp ${fmt(r)}');
        _current = fmt(r); _expr = exp;
        _operator = null; _newNum = true;
        return CalcResult(value: _current, sub: _expr, kind: 'result');
      }
    }

    return _disp(_current, _expr);
  }

  double _binary(double a, String op, double b) {
    switch (op) {
      case '+':   return a + b;
      case '−':
      case '-':   return a - b;
      case '×':   return a * b;
      case '÷':   if (b == 0) throw Exception('÷ by Zero'); return a / b;
      case '^':
      case 'xⁿ':  return math.pow(a, b).toDouble();
      case 'ˣ√y': return math.pow(b, 1/a).toDouble();
      case 'mod': return a % b;
      case 'nCr': return _comb(a.toInt(), b.toInt()).toDouble();
      case 'nPr': return _perm(a.toInt(), b.toInt()).toDouble();
      default:    throw Exception('Unknown op: $op');
    }
  }

  int _factorial(int n) {
    if (n < 0)  throw Exception('Factorial of negative');
    if (n > 20) throw Exception('Factorial too large');
    return n <= 1 ? 1 : n * _factorial(n - 1);
  }

  int _comb(int n, int k) {
    if (k > n) return 0;
    return _factorial(n) ~/ (_factorial(k) * _factorial(n - k));
  }

  int _perm(int n, int k) => _factorial(n) ~/ _factorial(n - k);

  CalcResult _disp(String val, String sub) =>
      CalcResult(value: val, sub: sub, kind: 'display');

  void _reset() {
    _current = '0'; _expr = ''; _operand1 = 0;
    _operator = null; _newNum = true;
  }

  void _addHistory(String s) {
    history.add(s);
    if (history.length > 50) history.removeAt(0);
  }

  String get current => _current;
}