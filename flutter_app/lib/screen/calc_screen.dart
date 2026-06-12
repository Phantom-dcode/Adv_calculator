// screens/calculator_screen.dart
// Mirrors the Python PhantomCalc UI:
//   - Deep dark background + animated star field
//   - Holographic display with scan-line + burst particles
//   - Cyan / purple / pink neon palette
//   - Scientific + Basic button grids
//   - 3D card tilt on mouse/touch drag
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/calculator_engine.dart';
import '../widgets/calc_button.dart';

// ── Colours matching Python C dict ────────────────────────────────
const kBg      = Color(0xFF0A0A1A);
const kBgMid   = Color(0xFF0F0F2E);
const kCyan    = Color(0xFF00E5FF);
const kPurple  = Color(0xFFBF00FF);
const kPink    = Color(0xFFFF006E);
const kGreen   = Color(0xFF00FF9F);
const kGold    = Color(0xFFFFD700);
const kDispTxt = Color(0xFFE8F4FD);
const kDispSub = Color(0xFF7EB8DA);
const kTextDim = Color(0xFF8899BB);

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with TickerProviderStateMixin {

  final Engine _engine = Engine();
  bool   _sciMode = true;

  // Display state
  String _mainVal = '0';
  String _subVal  = '';
  String _memStr  = '';
  bool   _isError = false;

  // ── 3D tilt ────────────────────────────────────────────────────
  double _tiltX = 0, _tiltY = 0, _tgtX = 0, _tgtY = 0;
  late AnimationController _tiltCtrl;

  // ── Star field ─────────────────────────────────────────────────
  late AnimationController _starCtrl;
  final List<_Star> _stars = [];

  // ── Display particle burst ──────────────────────────────────────
  final List<_Burst> _bursts = [];
  late AnimationController _burstCtrl;
  double _scanY = 0;

  // ── Cursor blink ────────────────────────────────────────────────
  bool _cursorOn = true;
  late AnimationController _cursorCtrl;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    for (int i = 0; i < 140; i++) {
      _stars.add(_Star.random(rng));
    }

    _tiltCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() {
        setState(() {
          _tiltX += (_tgtX - _tiltX) * 0.1;
          _tiltY += (_tgtY - _tiltY) * 0.1;
        });
      })
      ..repeat();

    _starCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..addListener(() {
        setState(() { _scanY = (_scanY + 3) % 112; });
      })
      ..repeat();

    _burstCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(() => setState(() {}));

    _cursorCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 530))
      ..addListener(() {
        if (_cursorCtrl.value == 0) setState(() => _cursorOn = !_cursorOn);
      })
      ..repeat();
  }

  @override
  void dispose() {
    _tiltCtrl.dispose(); _starCtrl.dispose();
    _burstCtrl.dispose(); _cursorCtrl.dispose();
    super.dispose();
  }

  // ── press handler ──────────────────────────────────────────────
  void _press(String k) {
    HapticFeedback.lightImpact();
    final result = _engine.press(k);
    setState(() {
      _mainVal = result.value ?? 'Error';
      _subVal  = result.sub  ?? '';
      _isError = result.isError;
      _memStr  = _engine.memory != 0 ? 'M = ${_engine.fmt(_engine.memory)}' : '';
      // burst animation
      _bursts.clear();
      final rng = math.Random();
      for (int i = 0; i < 6; i++) {
        _bursts.add(_Burst(
          x: rng.nextDouble() * 508,
          y: rng.nextDouble() * 112,
          color: [kCyan, kPurple, kGreen, kPink][rng.nextInt(4)],
          radius: rng.nextDouble() * 2 + 1.5,
        ));
      }
      _burstCtrl.forward(from: 0);
    });
  }

  // ── tilt ───────────────────────────────────────────────────────
  void _onPan(DragUpdateDetails d, Size sz) {
    final cx = sz.width / 2, cy = sz.height / 2;
    _tgtX = (d.localPosition.dy - cy) / cy * -8;
    _tgtY = (d.localPosition.dx - cx) / cx * 12;
  }
  void _onPanEnd(DragEndDetails _) { _tgtX = 0; _tgtY = 0; }

  // ── build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sz  = MediaQuery.of(context).size;
    final isW = sz.width > 600;
    return Scaffold(
      backgroundColor: kBg,
      body: GestureDetector(
        onPanUpdate: (d) => _onPan(d, sz),
        onPanEnd:    _onPanEnd,
        child: Stack(
          children: [
            // Star field
            CustomPaint(
              painter: _StarPainter(_stars, _starCtrl.value),
              size: sz,
            ),
            // Calc card centered
            Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_tiltX * math.pi / 180)
                  ..rotateY(_tiltY * math.pi / 180),
                child: _buildCard(isW),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(bool wide) {
    final w = wide ? 528.0 : double.infinity;
    return Container(
      width: w,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCyan.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: kCyan.withOpacity(0.12), blurRadius: 30, spreadRadius: -4),
          BoxShadow(color: kPurple.withOpacity(0.08), blurRadius: 40, spreadRadius: -8),
          const BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitleBar(),
          _buildDisplay(),
          _buildModeBar(),
          if (_sciMode) _buildSciPad(),
          _buildBasicPad(),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 2),
            child: Text(
              'Phantom ✦  KPR Institute of Engineering & Technology',
              style: TextStyle(color: kTextDim, fontSize: 9, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Title bar ──────────────────────────────────────────────────
  Widget _buildTitleBar() => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        const Text('◈  NOVA CALCX',
            style: TextStyle(color: kCyan, fontSize: 14,
                fontFamily: 'monospace', fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        const Spacer(),
        // History
        GestureDetector(
          onTap: _showHistory,
          child: const Text('📋', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        // SCI toggle
        GestureDetector(
          onTap: () => setState(() => _sciMode = !_sciMode),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E0A3E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kPurple.withOpacity(0.4)),
            ),
            child: Text(
              _sciMode ? '⊟ BASIC' : '⊞ SCI',
              style: const TextStyle(color: kPurple, fontSize: 10,
                  fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Display ────────────────────────────────────────────────────
  Widget _buildDisplay() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 10),
    height: 112,
    child: CustomPaint(
      painter: _DisplayPainter(
        mainVal:  _mainVal,
        subVal:   _subVal,
        memStr:   _memStr,
        mode:     _engine.angleMode,
        scanY:    _scanY.toDouble(),
        bursts:   _bursts,
        burstProg: _burstCtrl.value,
        isError:  _isError,
        cursorOn: _cursorOn,
      ),
      size: const Size(double.infinity, 112),
    ),
  );

  // ── Mode bar ───────────────────────────────────────────────────
  Widget _buildModeBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    child: Row(
      children: [
        for (final mode in ['DEG','RAD','GRAD'])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () { _press(mode); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _engine.angleMode == mode
                      ? const Color(0xFF004488)
                      : const Color(0xFF0A0A1A),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: kCyan.withOpacity(0.3)),
                ),
                child: Text(mode,
                    style: TextStyle(
                        color: _engine.angleMode == mode ? kCyan : kTextDim,
                        fontSize: 10, fontFamily: 'monospace')),
              ),
            ),
          ),
        const Spacer(),
        if (_memStr.isNotEmpty)
          Text(_memStr, style: const TextStyle(color: kGold, fontSize: 10, fontFamily: 'monospace')),
      ],
    ),
  );

  // ── Scientific pad ─────────────────────────────────────────────
  Widget _buildSciPad() {
    final rows = [
      [('MC',BtnStyle.mem),('MR',BtnStyle.mem),('M+',BtnStyle.mem),('M-',BtnStyle.mem),('MS',BtnStyle.mem)],
      [('DEG',BtnStyle.func),('RAD',BtnStyle.func),('π',BtnStyle.func),('e',BtnStyle.func),('φ',BtnStyle.func)],
      [('x²',BtnStyle.func),('x³',BtnStyle.func),('xⁿ',BtnStyle.op),('√',BtnStyle.func),('∛',BtnStyle.func)],
      [('sin',BtnStyle.func),('cos',BtnStyle.func),('tan',BtnStyle.func),('sin⁻¹',BtnStyle.func),('cos⁻¹',BtnStyle.func)],
      [('tan⁻¹',BtnStyle.func),('sinh',BtnStyle.func),('cosh',BtnStyle.func),('tanh',BtnStyle.func),('1/x',BtnStyle.func)],
      [('ln',BtnStyle.func),('log',BtnStyle.func),('log₂',BtnStyle.func),('eˣ',BtnStyle.func),('10ˣ',BtnStyle.func)],
      [('x!',BtnStyle.func),('mod',BtnStyle.op),('nCr',BtnStyle.func),('nPr',BtnStyle.func),('Rand',BtnStyle.func)],
      [('abs',BtnStyle.func),('ceil',BtnStyle.func),('floor',BtnStyle.func),('ˣ√y',BtnStyle.op),('2ˣ',BtnStyle.func)],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  for (final (lbl, sty) in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: CalcButton(
                          label: lbl, style: sty, height: 44,
                          onTap: () => _press(lbl),
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

  // ── Basic pad ──────────────────────────────────────────────────
  Widget _buildBasicPad() {
    final rows = [
      [('AC',BtnStyle.clear,1),('⌫',BtnStyle.clear,1),('%',BtnStyle.func,1),('÷',BtnStyle.op,1)],
      [('7',BtnStyle.num,1),('8',BtnStyle.num,1),('9',BtnStyle.num,1),('×',BtnStyle.op,1)],
      [('4',BtnStyle.num,1),('5',BtnStyle.num,1),('6',BtnStyle.num,1),('−',BtnStyle.op,1)],
      [('1',BtnStyle.num,1),('2',BtnStyle.num,1),('3',BtnStyle.num,1),('+',BtnStyle.op,1)],
      [('±',BtnStyle.func,1),('0',BtnStyle.num,1),('.',BtnStyle.num,1),('=',BtnStyle.eq,1)],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (final (lbl, sty, span) in row)
                    Expanded(
                      flex: span,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: CalcButton(
                          label: lbl, style: sty, height: 54,
                          onTap: () => _press(lbl),
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

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgMid,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text('📋  CALCULATION HISTORY',
                style: TextStyle(color: kCyan, fontSize: 14,
                    fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _engine.history.length,
              itemBuilder: (_, i) {
                final entry = _engine.history[_engine.history.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(entry,
                      style: const TextStyle(color: kDispTxt, fontSize: 12,
                          fontFamily: 'monospace')),
                );
              },
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('✕  Close',
                style: TextStyle(color: kPink, fontSize: 14)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Star field painter ─────────────────────────────────────────────
class _Star { double x, y, r, phase; _Star({required this.x,required this.y,required this.r,required this.phase});
  factory _Star.random(math.Random rng) => _Star(x: rng.nextDouble(), y: rng.nextDouble(), r: rng.nextDouble()*1.5+0.3, phase: rng.nextDouble()*math.pi*2);
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarPainter(this.stars, this.t);
  @override
  void paint(Canvas c, Size s) {
    for (final st in stars) {
      final a = 0.4 + 0.6 * math.sin(t * math.pi * 2 * 0.25 + st.phase);
      final v = (a * 210).toInt();
      final col = Color.fromARGB(255, v, v, math.min(255, v + 30));
      c.drawCircle(Offset(st.x * s.width, st.y * s.height), st.r,
          Paint()..color = col);
    }
  }
  @override bool shouldRepaint(covariant _StarPainter o) => o.t != t;
}

// ── Display painter (scan line + burst + holographic) ──────────────
class _Burst { double x, y, radius; Color color; _Burst({required this.x,required this.y,required this.color,required this.radius}); }

class _DisplayPainter extends CustomPainter {
  final String mainVal, subVal, memStr, mode;
  final double scanY, burstProg;
  final List<_Burst> bursts;
  final bool isError, cursorOn;

  _DisplayPainter({
    required this.mainVal, required this.subVal, required this.memStr,
    required this.mode,    required this.scanY,  required this.bursts,
    required this.burstProg, required this.isError, required this.cursorOn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // BG gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF070715), const Color(0xFF0A0A20)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(RRect.fromLTRBR(0, 0, w, h, const Radius.circular(10)), bgPaint);

    // Glow border
    for (final (th, a) in [(3.0,0x11),(2.0,0x22),(1.0,0x44)]) {
      canvas.drawRRect(
        RRect.fromLTRBR(th, th, w-th, h-th, const Radius.circular(9)),
        Paint()..color = Color(0xFF00E5FF).withAlpha(a)
               ..style = PaintingStyle.stroke
               ..strokeWidth = 1,
      );
    }

    // Corner ticks
    final tickP = Paint()..color = kCyan..strokeWidth = 2;
    final sz = 8.0;
    for (final (cx, cy, dx, dy) in [(0.0,0.0,1.0,1.0),(w,0.0,-1.0,1.0),(0.0,h,1.0,-1.0),(w,h,-1.0,-1.0)]) {
      canvas.drawLine(Offset(cx, cy), Offset(cx + dx*sz, cy), tickP);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy + dy*sz), tickP);
    }

    // Memory
    if (memStr.isNotEmpty) {
      _drawText(canvas, memStr, 10, 12, 9, kGold, TextAlign.left);
    }

    // Mode badge
    final modeColors = {'DEG': const Color(0xFF004488), 'RAD': const Color(0xFF440088), 'GRAD': const Color(0xFF004400)};
    final mc = modeColors[mode] ?? const Color(0xFF004488);
    canvas.drawRect(Rect.fromLTWH(w-52, 5, 46, 16), Paint()..color = mc);
    canvas.drawRect(Rect.fromLTWH(w-52, 5, 46, 16),
        Paint()..color = kCyan..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawText(canvas, mode, w-29, 12, 9, kCyan, TextAlign.center);

    // Sub line (expression)
    _drawText(canvas, subVal, w-10, 34, 12, kDispSub, TextAlign.right);

    // Main value
    final mainLen  = mainVal.length;
    final mainSize = mainLen <= 7 ? 36.0 : mainLen <= 12 ? 28.0 : mainLen <= 18 ? 22.0 : 16.0;
    final mainColor = isError ? const Color(0xFFFF5555) : kDispTxt;
    _drawText(canvas, mainVal, w-10, h-14, mainSize, mainColor, TextAlign.right, bold: true);

    // Cursor
    canvas.drawRect(Rect.fromLTWH(w-12, h-10, 4, 4),
        Paint()..color = cursorOn ? kCyan : Colors.transparent);

    // Scan line
    canvas.drawLine(Offset(0, scanY), Offset(w, scanY),
        Paint()..color = Colors.white.withAlpha(0x09)..strokeWidth = 2);

    // Burst particles
    final alpha = (1 - burstProg) * 0.8;
    for (final b in bursts) {
      canvas.drawCircle(
        Offset(b.x, b.y), b.radius * (1 - burstProg * 0.5),
        Paint()..color = b.color.withOpacity(alpha));
    }
  }

  void _drawText(Canvas c, String text, double x, double y, double size,
      Color color, TextAlign align, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(
          color: color, fontSize: size, fontFamily: 'monospace',
          fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 500);

    final dx = align == TextAlign.right ? x - tp.width
             : align == TextAlign.center ? x - tp.width / 2
             : x;
    tp.paint(c, Offset(dx, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DisplayPainter o) => true;
}
