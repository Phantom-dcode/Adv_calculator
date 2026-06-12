// widgets/calc_button.dart — 3D button matching Tkinter Btn class
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum BtnStyle { num, op, func, eq, clear, mem }

const _palette = {
  BtnStyle.num:   {'face': Color(0xFF1A1A3E), 'hover': Color(0xFF2A2A5E), 'shadow': Color(0xFF05052A), 'glow': Color(0xFF00E5FF), 'fg': Colors.white},
  BtnStyle.op:    {'face': Color(0xFF0D2B4E), 'hover': Color(0xFF1A4A7A), 'shadow': Color(0xFF050E1F), 'glow': Color(0xFF00E5FF), 'fg': Color(0xFF00E5FF)},
  BtnStyle.func:  {'face': Color(0xFF1E0A3E), 'hover': Color(0xFF3A1A6E), 'shadow': Color(0xFF0A051A), 'glow': Color(0xFFBF00FF), 'fg': Color(0xFFBF00FF)},
  BtnStyle.eq:    {'face': Color(0xFF003366), 'hover': Color(0xFF0055AA), 'shadow': Color(0xFF001122), 'glow': Color(0xFF00E5FF), 'fg': Color(0xFF00FF9F)},
  BtnStyle.clear: {'face': Color(0xFF3D0000), 'hover': Color(0xFF660000), 'shadow': Color(0xFF1A0000), 'glow': Color(0xFFFF006E), 'fg': Color(0xFFFF006E)},
  BtnStyle.mem:   {'face': Color(0xFF0A1A2A), 'hover': Color(0xFF1A3A5A), 'shadow': Color(0xFF030A12), 'glow': Color(0xFFFFD700), 'fg': Color(0xFFFFD700)},
};

class CalcButton extends StatefulWidget {
  final String   label;
  final BtnStyle style;
  final VoidCallback onTap;
  final double width;
  final double height;

  const CalcButton({
    super.key,
    required this.label,
    required this.style,
    required this.onTap,
    this.width  = 68,
    this.height = 52,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton>
    with SingleTickerProviderStateMixin {
  bool _hover  = false;
  bool _pressed = false;

  // Ripple
  late AnimationController _rippleCtrl;
  late Animation<double>   _rippleAnim;
  Offset _tapPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _rippleAnim = CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);
    _rippleCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _rippleCtrl.reset();
    });
  }

  @override
  void dispose() { _rippleCtrl.dispose(); super.dispose(); }

  void _onTapDown(TapDownDetails d) {
    setState(() { _pressed = true; _hover = true; });
    _tapPos = d.localPosition;
    _rippleCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() { _pressed = false; });
    widget.onTap();
  }

  void _onTapCancel() => setState(() { _pressed = false; _hover = false; });

  @override
  Widget build(BuildContext context) {
    final c  = _palette[widget.style]!;
    final d  = _pressed ? 0.0 : 4.0;    // depth offset

    final face   = (_hover || _pressed) ? c['hover'] as Color : c['face'] as Color;
    final shadow = c['shadow'] as Color;
    final glow   = c['glow']   as Color;
    final fg     = (_hover || _pressed) ? glow : c['fg'] as Color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor:  SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown:   _onTapDown,
        onTapUp:     _onTapUp,
        onTapCancel: _onTapCancel,
        child: SizedBox(
          width: widget.width, height: widget.height,
          child: CustomPaint(
            painter: _BtnPainter(
              face:    face,
              shadow:  shadow,
              glow:    glow,
              depth:   d,
              hover:   _hover,
              pressed: _pressed,
              ripplePos:  _tapPos,
              rippleProg: _rippleAnim,
            ),
            child: AnimatedBuilder(
              animation: _rippleAnim,
              builder: (_, child) => child!,
              child: Align(
                child: Transform.translate(
                  offset: Offset(_pressed ? d*.6 : 0, _pressed ? d*.6 : 0),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color:      fg,
                      fontSize:   widget.label.length > 3 ? 11 : 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      shadows: _hover || _pressed ? [
                        Shadow(color: glow.withOpacity(0.8), blurRadius: 8),
                      ] : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BtnPainter extends CustomPainter {
  final Color   face, shadow, glow;
  final double  depth;
  final bool    hover, pressed;
  final Offset  ripplePos;
  final Animation<double> rippleProg;

  _BtnPainter({
    required this.face, required this.shadow, required this.glow,
    required this.depth, required this.hover, required this.pressed,
    required this.ripplePos, required this.rippleProg,
  }) : super(repaint: rippleProg);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = const Radius.circular(12);
    final d = depth;

    // Shadow
    if (d > 0) {
      final sp = Paint()..color = shadow;
      canvas.drawRRect(
        RRect.fromLTRBR(d, d, w, h, r), sp);
    }

    // Face
    final fp = Paint()..color = face;
    final faceRect = RRect.fromLTRBR(0, 0, w-d, h-d, r);
    canvas.drawRRect(faceRect, fp);

    // Glow border
    if (hover || pressed) {
      final gp = Paint()
        ..color = glow.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawRRect(faceRect, gp);
    }

    // Top specular highlight
    final hl = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromLTRBR(2, 2, w-d-2, (h-d)*0.35, const Radius.circular(9)), hl);

    // Ripple
    if (rippleProg.value > 0) {
      final maxR  = math.max(w, h) * 1.2;
      final rPaint = Paint()
        ..color = glow.withOpacity(0.22 * (1 - rippleProg.value))
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.clipRRect(faceRect);
      canvas.drawCircle(ripplePos, maxR * rippleProg.value, rPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BtnPainter old) =>
      old.face != face || old.hover != hover || old.pressed != pressed;
}

