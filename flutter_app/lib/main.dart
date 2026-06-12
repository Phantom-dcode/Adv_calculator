import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════════
//  Quantum Calculator — Flutter Port
//  Mirrors Python version: Basic · Scientific · Programmer · Stats
// ══════════════════════════════════════════════════════════════════

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const QuantumCalcApp());
}

// ─── Palette ──────────────────────────────────────────────────────
class P {
  static const bgDeep     = Color(0xFF050A14);
  static const bgCard     = Color(0xFF0B1426);
  static const surface    = Color(0xFF111E35);
  static const surface2   = Color(0xFF162040);
  static const neonBlue   = Color(0xFF00D4FF);
  static const neonPurple = Color(0xFFA855F7);
  static const neonGreen  = Color(0xFF00FF94);
  static const neonOrange = Color(0xFFFF6B35);
  static const neonPink   = Color(0xFFFF2D78);
  static const textBright = Color(0xFFFFFFFF);
  static const textDim    = Color(0xFF8899BB);
  static const border     = Color(0xFF1E3A5F);
  static const btnNum     = Color(0xFF131F38);
  static const btnOp     = Color(0xFF1A1040);
  static const btnEq     = Color(0xFF003D6B);
  static const btnFn     = Color(0xFF0D2030);
  static const btnClear  = Color(0xFF2A0A0A);
}

// ─── App Root ─────────────────────────────────────────────────────
class QuantumCalcApp extends StatelessWidget {
  const QuantumCalcApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quantum Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: P.bgDeep,
        colorScheme: const ColorScheme.dark(primary: P.neonBlue),
      ),
      home: const CalculatorScreen(),
    );
  }
}

// ─── Math Engine (Dart port) ──────────────────────────────────────
class MathEngine {
  bool degMode = true;
  double memory = 0;
  double ans = 0;

  double _toRad(double x) => degMode ? x * pi / 180 : x;
  double _fromRad(double x) => degMode ? x * 180 / pi : x;

  String evaluate(String expr) {
    try {
      final result = _evalExpr(expr.trim());
      ans = result;
      return _fmt(result);
    } catch (e) {
      return 'Error';
    }
  }

  double _evalExpr(String expr) {
    expr = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('^', '**')
        .replaceAll('π', '${pi}')
        .replaceAll('ans', '$ans');

    // Simple expression parser supporting +, -, *, /, **, ()
    return _parseExpr(expr);
  }

  // Recursive descent parser
  double _parseExpr(String s) {
    s = s.trim();
    return _addSub(s, [0]);
  }

  double _addSub(String s, List<int> pos) {
    double left = _mulDiv(s, pos);
    while (pos[0] < s.length) {
      final c = s[pos[0]];
      if (c == '+') { pos[0]++; left += _mulDiv(s, pos); }
      else if (c == '-' && pos[0] > 0) { pos[0]++; left -= _mulDiv(s, pos); }
      else break;
    }
    return left;
  }

  double _mulDiv(String s, List<int> pos) {
    double left = _pow(s, pos);
    while (pos[0] < s.length) {
      final c = s[pos[0]];
      if (c == '*' && (pos[0]+1 >= s.length || s[pos[0]+1] != '*')) {
        pos[0]++; left *= _pow(s, pos);
      } else if (c == '/') {
        pos[0]++; final r = _pow(s, pos);
        if (r == 0) throw Exception('Division by zero');
        left /= r;
      } else break;
    }
    return left;
  }

  double _pow(String s, List<int> pos) {
    double base = _unary(s, pos);
    if (pos[0]+1 < s.length && s[pos[0]] == '*' && s[pos[0]+1] == '*') {
      pos[0] += 2;
      final exp = _pow(s, pos);
      base = math_pow(base, exp).toDouble();
    }
    return base;
  }

  double _unary(String s, List<int> pos) {
    if (pos[0] < s.length && s[pos[0]] == '-') {
      pos[0]++;
      return -_primary(s, pos);
    }
    return _primary(s, pos);
  }

  double _primary(String s, List<int> pos) {
    if (pos[0] >= s.length) return 0;
    if (s[pos[0]] == '(') {
      pos[0]++;
      final v = _addSub(s, pos);
      if (pos[0] < s.length && s[pos[0]] == ')') pos[0]++;
      return v;
    }
    // Named functions
    for (final fn in ['sqrt','cbrt','sin','cos','tan','asin','acos','atan',
                       'sinh','cosh','tanh','log2','log','ln','abs','exp',
                       'ceil','floor','round']) {
      if (s.startsWith(fn, pos[0])) {
        pos[0] += fn.length;
        if (pos[0] < s.length && s[pos[0]] == '(') {
          pos[0]++;
          final arg = _addSub(s, pos);
          if (pos[0] < s.length && s[pos[0]] == ')') pos[0]++;
          return _applyFn(fn, arg);
        }
      }
    }
    // Number
    final start = pos[0];
    if (s[pos[0]] == '-') pos[0]++;
    while (pos[0] < s.length &&
           (RegExp(r'[0-9.]').hasMatch(s[pos[0]]) ||
            (s[pos[0]] == 'e' && pos[0] > start))) {
      pos[0]++;
    }
    return double.parse(s.substring(start, pos[0]));
  }

  double _applyFn(String fn, double x) {
    switch (fn) {
      case 'sqrt':  return sqrt(x);
      case 'cbrt':  return x >= 0 ? pow(x, 1/3).toDouble() : -pow(-x, 1/3).toDouble();
      case 'sin':   return sin(_toRad(x));
      case 'cos':   return cos(_toRad(x));
      case 'tan':   return tan(_toRad(x));
      case 'asin':  return _fromRad(asin(x));
      case 'acos':  return _fromRad(acos(x));
      case 'atan':  return _fromRad(atan(x));
      case 'sinh':  return (exp(x) - exp(-x)) / 2;
      case 'cosh':  return (exp(x) + exp(-x)) / 2;
      case 'tanh':  return (exp(2*x)-1)/(exp(2*x)+1);
      case 'log':   return log(x) / ln10;
      case 'ln':    return log(x);
      case 'log2':  return log(x) / ln2;
      case 'abs':   return x.abs();
      case 'exp':   return exp(x);
      case 'ceil':  return x.ceilToDouble();
      case 'floor': return x.floorToDouble();
      case 'round': return x.roundToDouble();
      default:      return x;
    }
  }

  num math_pow(double b, double e) => pow(b, e);

  String _fmt(double v) {
    if (v.isNaN) return 'NaN';
    if (v.isInfinite) return v > 0 ? '∞' : '-∞';
    if (v == v.truncateToDouble() && v.abs() < 1e15) return v.toInt().toString();
    return double.parse(v.toStringAsFixed(10)).toString();
  }

  void memStore(double v)  => memory = v;
  void memAdd(double v)    => memory += v;
  void memSub(double v)    => memory -= v;
  void memClear()          => memory = 0;
  double memRecall()       => memory;
}

// ─── Calculator Screen ────────────────────────────────────────────
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with TickerProviderStateMixin {
  final engine = MathEngine();
  String _expr    = '';
  String _result  = '';
  String _history = '';
  int _mode = 0; // 0=basic, 1=sci, 2=prog, 3=stat

  late AnimationController _flashCtrl;
  late Animation<Color?> _flashAnim;
  Color _resultColor = P.textBright;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flashAnim = ColorTween(begin: P.neonGreen, end: P.textBright).animate(_flashCtrl)
      ..addListener(() => setState(() => _resultColor = _flashAnim.value ?? P.textBright));
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  void _append(String s) => setState(() {
    if (_expr == '0' && RegExp(r'^\d$').hasMatch(s)) _expr = s;
    else _expr += s;
  });

  void _clear() => setState(() { _expr = ''; _result = ''; _history = ''; });

  void _back() => setState(() {
    if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
  });

  void _evaluate() {
    if (_expr.isEmpty) return;
    final res = engine.evaluate(_expr);
    setState(() {
      _history = '$_expr =';
      _result  = res;
      if (!res.startsWith('Error')) {
        _expr = res;
        _resultColor = P.neonGreen;
        _flashCtrl.forward(from: 0);
      } else {
        _resultColor = P.neonPink;
      }
    });
  }

  void _negate() => setState(() {
    if (_expr.startsWith('-')) _expr = _expr.substring(1);
    else _expr = '-$_expr';
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: P.bgDeep,
      body: SafeArea(
        child: Stack(children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF050A14), Color(0xFF0B1426), Color(0xFF050A14)],
              ),
            ),
          ),
          Column(children: [
            _buildTitleBar(),
            _buildDisplay(),
            const SizedBox(height: 8),
            Expanded(child: _buildButtons()),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTitleBar() {
    final modes = ['BAS', 'SCI', 'PRG', 'STAT'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        Text('⚛ QUANTUM', style: GoogleFonts.jetBrainsMono(
          color: P.neonBlue, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Text('CALCULATOR', style: GoogleFonts.jetBrainsMono(
          color: P.textDim, fontSize: 14)),
        const Spacer(),
        ...List.generate(modes.length, (i) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => setState(() => _mode = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _mode == i ? P.neonBlue.withOpacity(0.25) : P.surface2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _mode == i ? P.neonBlue : P.border, width: 1),
              ),
              child: Text(modes[i], style: GoogleFonts.jetBrainsMono(
                color: _mode == i ? P.neonBlue : P.textDim,
                fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _buildDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: P.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: P.border, width: 1),
        boxShadow: [BoxShadow(color: P.neonBlue.withOpacity(0.08),
            blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // History
        Text(_history, style: GoogleFonts.jetBrainsMono(
          color: P.textDim, fontSize: 13), textAlign: TextAlign.right),
        const SizedBox(height: 4),
        // Expression
        Text(_expr.isEmpty ? '0' : _expr,
          style: GoogleFonts.jetBrainsMono(
            color: P.neonBlue,
            fontSize: _expr.length > 20 ? 20 : (_expr.length > 14 ? 24 : 28),
            fontWeight: FontWeight.bold),
          textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        // Result
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: GoogleFonts.jetBrainsMono(
            color: _resultColor,
            fontSize: _result.length > 16 ? 28 : 40,
            fontWeight: FontWeight.bold),
          child: Text(_result, textAlign: TextAlign.right)),
        const SizedBox(height: 8),
        // Mode strip
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _modeChip(engine.degMode ? 'DEG' : 'RAD', P.neonBlue),
          _modeChip('MEM:${engine.memory.toStringAsFixed(0)}', P.neonGreen),
          _modeChip(['BASIC','SCI','PROG','STAT'][_mode], P.neonPurple),
        ]),
      ]),
    );
  }

  Widget _modeChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10)),
    );
  }

  Widget _buildButtons() {
    switch (_mode) {
      case 0: return _basicGrid();
      case 1: return _sciGrid();
      case 2: return _progGrid();
      case 3: return _statGrid();
      default: return _basicGrid();
    }
  }

  // ── Basic Grid ────────────────────────────────────────────────────
  Widget _basicGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(children: [
        _row([
          _btn('MC',  () { engine.memClear(); setState((){}); }, color: P.btnFn,   tc: P.neonGreen),
          _btn('MR',  () => _append(engine.memRecall().toString()), color: P.btnFn, tc: P.neonGreen),
          _btn('M+',  () { try { engine.memAdd(double.parse(_result.isEmpty ? _expr : _result)); setState((){}); } catch(_) {} }, color: P.btnFn, tc: P.neonGreen),
          _btn('M−',  () { try { engine.memSub(double.parse(_result.isEmpty ? _expr : _result)); setState((){}); } catch(_) {} }, color: P.btnFn, tc: P.neonGreen),
        ]),
        _row([
          _btn('AC', _clear,    color: P.btnClear, tc: P.neonPink),
          _btn('⌫',  _back,     color: P.btnClear, tc: P.neonPink),
          _btn('%',  () => _append('%'), color: P.btnOp, tc: P.neonOrange),
          _btn('÷',  () => _append('÷'), color: P.btnOp, tc: P.neonPurple),
        ]),
        _row([_num('7'), _num('8'), _num('9'),
          _btn('×', () => _append('×'), color: P.btnOp, tc: P.neonPurple)]),
        _row([_num('4'), _num('5'), _num('6'),
          _btn('−', () => _append('−'), color: P.btnOp, tc: P.neonPurple)]),
        _row([_num('1'), _num('2'), _num('3'),
          _btn('+', () => _append('+'), color: P.btnOp, tc: P.neonPurple)]),
        _row([
          _btn('±', _negate, color: P.btnOp, tc: P.neonOrange),
          _num('0'),
          _btn('.', () => _append('.'), tc: P.textBright),
          _btn('=', _evaluate, color: P.btnEq, tc: P.neonBlue, glow: P.neonBlue),
        ]),
      ]),
    );
  }

  // ── Scientific Grid ───────────────────────────────────────────────
  Widget _sciGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        _row5([
          _sbtn('sin',   () => _append('sin(')),
          _sbtn('cos',   () => _append('cos(')),
          _sbtn('tan',   () => _append('tan(')),
          _sbtn('π',     () => _append('π'), tc: P.neonOrange),
          _sbtn('e',     () => _append('e'), tc: P.neonOrange),
        ]),
        _row5([
          _sbtn('sin⁻¹', () => _append('asin(')),
          _sbtn('cos⁻¹', () => _append('acos(')),
          _sbtn('tan⁻¹', () => _append('atan(')),
          _sbtn('x²',    () => _append('**2'), tc: P.neonOrange),
          _sbtn('x³',    () => _append('**3'), tc: P.neonOrange),
        ]),
        _row5([
          _sbtn('log',   () => _append('log(')),
          _sbtn('ln',    () => _append('ln(')),
          _sbtn('√',     () => _append('sqrt(')),
          _sbtn('∛',     () => _append('cbrt(')),
          _sbtn('xʸ',    () => _append('**'), tc: P.neonOrange),
        ]),
        _row5([
          _sbtn('(',   () => _append('('),  tc: P.neonOrange),
          _sbtn(')',   () => _append(')'),  tc: P.neonOrange),
          _sbtn('AC',  _clear,  color: P.btnClear, tc: P.neonPink),
          _sbtn('⌫',   _back,   color: P.btnClear, tc: P.neonPink),
          _sbtn('DEG', () => setState(() => engine.degMode = !engine.degMode),
              color: P.btnOp, tc: P.neonOrange),
        ]),
        _row5([
          _sbtn('7', () => _append('7'), color: P.btnNum, tc: P.textBright),
          _sbtn('8', () => _append('8'), color: P.btnNum, tc: P.textBright),
          _sbtn('9', () => _append('9'), color: P.btnNum, tc: P.textBright),
          _sbtn('÷', () => _append('÷'), color: P.btnOp, tc: P.neonPurple),
          _sbtn('×', () => _append('×'), color: P.btnOp, tc: P.neonPurple),
        ]),
        _row5([
          _sbtn('4', () => _append('4'), color: P.btnNum, tc: P.textBright),
          _sbtn('5', () => _append('5'), color: P.btnNum, tc: P.textBright),
          _sbtn('6', () => _append('6'), color: P.btnNum, tc: P.textBright),
          _sbtn('−', () => _append('−'), color: P.btnOp, tc: P.neonPurple),
          _sbtn('+', () => _append('+'), color: P.btnOp, tc: P.neonPurple),
        ]),
        _row5([
          _sbtn('1', () => _append('1'), color: P.btnNum, tc: P.textBright),
          _sbtn('2', () => _append('2'), color: P.btnNum, tc: P.textBright),
          _sbtn('3', () => _append('3'), color: P.btnNum, tc: P.textBright),
          _sbtn('0', () => _append('0'), color: P.btnNum, tc: P.textBright),
          _sbtn('=', _evaluate, color: P.btnEq, tc: P.neonBlue),
        ]),
      ]),
    );
  }

  // ── Programmer Grid ───────────────────────────────────────────────
  Widget _progGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(children: [
        _row([
          _btn('HEX→DEC', _hexToDec, color: P.btnFn, tc: P.neonGreen, fs: 10),
          _btn('DEC→HEX', _decToHex, color: P.btnFn, tc: P.neonGreen, fs: 10),
          _btn('DEC→BIN', _decToBin, color: P.btnFn, tc: P.neonGreen, fs: 10),
          _btn('BIN→DEC', _binToDec, color: P.btnFn, tc: P.neonGreen, fs: 10),
        ]),
        _row([
          _btn('AND', () => _append(' & '), color: P.btnOp, tc: P.neonPurple),
          _btn('OR',  () => _append(' | '), color: P.btnOp, tc: P.neonPurple),
          _btn('XOR', () => _append(' ^ '), color: P.btnOp, tc: P.neonPurple),
          _btn('NOT', _bitwiseNot, color: P.btnFn, tc: P.neonGreen),
        ]),
        _row([
          _btn('<<', () => _append(' << '), color: P.btnOp, tc: P.neonPurple),
          _btn('>>', () => _append(' >> '), color: P.btnOp, tc: P.neonPurple),
          _btn('0b', () => _append('0b'), color: P.btnOp, tc: P.neonOrange),
          _btn('0x', () => _append('0x'), color: P.btnOp, tc: P.neonOrange),
        ]),
        _row([
          _btn('AC', _clear, color: P.btnClear, tc: P.neonPink),
          _btn('⌫',  _back,  color: P.btnClear, tc: P.neonPink),
          _btn('÷',  () => _append('÷'), color: P.btnOp, tc: P.neonPurple),
          _btn('×',  () => _append('×'), color: P.btnOp, tc: P.neonPurple),
        ]),
        _row([_num('7'), _num('8'), _num('9'), _btn('−', () => _append('−'), color: P.btnOp, tc: P.neonPurple)]),
        _row([_num('4'), _num('5'), _num('6'), _btn('+', () => _append('+'), color: P.btnOp, tc: P.neonPurple)]),
        _row([_num('1'), _num('2'), _num('3'), _btn('=', _evaluate, color: P.btnEq, tc: P.neonBlue)]),
        _row([_num('0'), _btn('.', () => _append('.'), tc: P.textBright), _btn('%', () => _append('%'), tc: P.neonOrange), _btn('±', _negate, color: P.btnOp, tc: P.neonOrange)]),
      ]),
    );
  }

  // ── Stats Grid ────────────────────────────────────────────────────
  Widget _statGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('Enter comma-separated numbers',
            style: GoogleFonts.jetBrainsMono(color: P.textDim, fontSize: 11))),
        _row([
          _btn('MEAN',  _statMean,  color: P.btnFn, tc: P.neonGreen, fs: 11),
          _btn('MED',   _statMed,   color: P.btnFn, tc: P.neonGreen, fs: 11),
          _btn('STD',   _statStd,   color: P.btnFn, tc: P.neonGreen, fs: 11),
          _btn('VAR',   _statVar,   color: P.btnFn, tc: P.neonGreen, fs: 11),
        ]),
        _row([
          _btn('SUM',   _statSum,   color: P.btnFn, tc: P.neonGreen, fs: 11),
          _btn('MIN',   _statMin,   color: P.btnFn, tc: P.neonGreen, fs: 11),
          _btn('MAX',   _statMax,   color: P.btnFn, tc: P.neonGreen, fs: 11),
          _btn('COUNT', _statCount, color: P.btnFn, tc: P.neonGreen, fs: 11),
        ]),
        _row([
          _btn(',',  () => _append(','), color: P.btnOp, tc: P.neonOrange),
          _btn('AC', _clear, color: P.btnClear, tc: P.neonPink),
          _btn('⌫',  _back,  color: P.btnClear, tc: P.neonPink),
          _btn('=',  _evaluate, color: P.btnEq, tc: P.neonBlue),
        ]),
        _row([_num('7'), _num('8'), _num('9'), _btn('÷', () => _append('÷'), color: P.btnOp, tc: P.neonPurple)]),
        _row([_num('4'), _num('5'), _num('6'), _btn('×', () => _append('×'), color: P.btnOp, tc: P.neonPurple)]),
        _row([_num('1'), _num('2'), _num('3'), _btn('−', () => _append('−'), color: P.btnOp, tc: P.neonPurple)]),
        _row([_num('0'), _btn('.', () => _append('.'), tc: P.textBright), _btn('±', _negate, color: P.btnOp, tc: P.neonOrange), _btn('+', () => _append('+'), color: P.btnOp, tc: P.neonPurple)]),
      ]),
    );
  }

  // ── Button helpers ─────────────────────────────────────────────────
  Widget _btn(String label, VoidCallback onTap, {
    Color color = P.btnNum, Color tc = P.textBright,
    Color? glow, double fs = 16}) {
    return Expanded(child: _CalcButton(
      label: label, onTap: onTap,
      color: color, textColor: tc, glowColor: glow, fontSize: fs));
  }

  Widget _num(String d) => _btn(d, () => _append(d), tc: P.textBright);

  Widget _sbtn(String label, VoidCallback onTap, {
    Color color = P.btnFn, Color tc = P.neonGreen, double fs = 12}) {
    return Expanded(child: _CalcButton(
      label: label, onTap: onTap,
      color: color, textColor: tc, fontSize: fs, height: 52));
  }

  Widget _row(List<Widget> children) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: IntrinsicHeight(child: Row(children: children)));

  Widget _row5(List<Widget> children) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: IntrinsicHeight(child: Row(children: children)));

  // ── Programmer ops ─────────────────────────────────────────────────
  void _hexToDec() { try { setState(() { _result = int.parse(_expr, radix: 16).toString(); }); } catch(_) { setState(() => _result = 'Error'); } }
  void _decToHex() { try { setState(() { _result = '0x${int.parse(_expr).toRadixString(16).toUpperCase()}'; }); } catch(_) { setState(() => _result = 'Error'); } }
  void _decToBin() { try { setState(() { _result = '0b${int.parse(_expr).toRadixString(2)}'; }); } catch(_) { setState(() => _result = 'Error'); } }
  void _binToDec() { try { setState(() { _result = int.parse(_expr.replaceFirst('0b',''), radix: 2).toString(); }); } catch(_) { setState(() => _result = 'Error'); } }
  void _bitwiseNot() { try { setState(() { _result = (~int.parse(_expr)).toString(); }); } catch(_) { setState(() => _result = 'Error'); } }

  // ── Stats ops ──────────────────────────────────────────────────────
  List<double>? _parseNums() { try { return _expr.split(',').map((s) => double.parse(s.trim())).toList(); } catch(_) { return null; } }
  void _statOp(String name, double Function(List<double>) fn) {
    final nums = _parseNums();
    if (nums == null || nums.isEmpty) { setState(() => _result = 'Error: need numbers'); return; }
    setState(() { _result = '$name: ${fn(nums).toStringAsFixed(6)}'; });
  }
  void _statMean()  => _statOp('Mean',   (l) => l.reduce((a,b)=>a+b)/l.length);
  void _statMed()   => _statOp('Median', (l) { l.sort(); return l.length.isOdd ? l[l.length~/2] : (l[l.length~/2-1]+l[l.length~/2])/2; });
  void _statSum()   => _statOp('Sum',    (l) => l.reduce((a,b)=>a+b));
  void _statMin()   => _statOp('Min',    (l) { l.sort(); return l.first; });
  void _statMax()   => _statOp('Max',    (l) { l.sort(); return l.last; });
  void _statCount() => _statOp('Count',  (l) => l.length.toDouble());
  void _statVar()   => _statOp('Var',    (l) { final m = l.reduce((a,b)=>a+b)/l.length; return l.map((x)=>(x-m)*(x-m)).reduce((a,b)=>a+b)/l.length; });
  void _statStd()   => _statOp('Std',    (l) { final m = l.reduce((a,b)=>a+b)/l.length; return sqrt(l.map((x)=>(x-m)*(x-m)).reduce((a,b)=>a+b)/l.length); });
}

// ─── Animated Calc Button ─────────────────────────────────────────
class _CalcButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color? glowColor;
  final double fontSize;
  final double height;

  const _CalcButton({
    required this.label, required this.onTap,
    this.color = P.btnNum, this.textColor = P.textBright,
    this.glowColor, this.fontSize = 18, this.height = 62});

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? widget.textColor;
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown:   (_) => _ctrl.forward(),
          onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
          onTapCancel: ()  => _ctrl.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: widget.height,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _hover ? widget.color.withOpacity(0.85) : widget.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hover ? glow.withOpacity(0.6) : P.border,
                width: _hover ? 1.5 : 1,
              ),
              boxShadow: _hover ? [BoxShadow(
                color: glow.withOpacity(0.25),
                blurRadius: 12, spreadRadius: 1)] : [],
            ),
            alignment: Alignment.center,
            child: Text(widget.label,
              style: GoogleFonts.jetBrainsMono(
                color: widget.textColor,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
