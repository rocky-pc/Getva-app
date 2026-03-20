import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium scratch card widget inspired by Google Pay's design.
/// Features a textured cover layer and smooth scratch interactions.
class SimpleScratchCard extends StatefulWidget {
  final Widget revealedContent;
  final Widget? scratchContent; // Optional content below the painter
  final VoidCallback? onRevealed;
  final double scratchThreshold;
  final double brushSize;
  final bool enableTapToReveal;
  final Color baseColor;

  const SimpleScratchCard({
    Key? key,
    required this.revealedContent,
    this.scratchContent,
    this.onRevealed,
    this.scratchThreshold = 0.40, // Increased for better feel
    this.brushSize = 45.0,
    this.enableTapToReveal = true,
    this.baseColor = const Color(0xFF1A73E8), // Google Blue
  }) : super(key: key);

  @override
  State<SimpleScratchCard> createState() => _SimpleScratchCardState();
}

class _SimpleScratchCardState extends State<SimpleScratchCard> {
  bool _isRevealed = false;
  final List<Offset> _scratchPoints = [];
  final GlobalKey _cardKey = GlobalKey();

  void _onPanStart(DragStartDetails details) {
    if (_isRevealed) return;
    _addPoint(details.localPosition);
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isRevealed) return;
    _addPoint(details.localPosition);
    if (_scratchPoints.length % 5 == 0) {
      HapticFeedback.selectionClick();
    }
  }

  void _onTap(TapUpDetails details) {
    if (_isRevealed || !widget.enableTapToReveal) return;
    final tapPos = details.localPosition;
    final brushSize = widget.brushSize;
    
    for (double angle = 0; angle < 2 * pi; angle += 0.8) {
      final offset = Offset(
        tapPos.dx + brushSize * 0.4 * cos(angle),
        tapPos.dy + brushSize * 0.4 * sin(angle),
      );
      _addPoint(offset);
    }
    _addPoint(tapPos);
    HapticFeedback.mediumImpact();
  }

  void _addPoint(Offset pos) {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    setState(() {
      _scratchPoints.add(pos);
      _checkThreshold(box.size);
    });
  }

  void _checkThreshold(Size size) {
    if (size.width == 0 || size.height == 0) return;
    
    const gridSize = 10;
    final cw = size.width / gridSize;
    final ch = size.height / gridSize;
    int scratched = 0;
    final halfBrush = widget.brushSize / 2;

    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);
        for (final pt in _scratchPoints) {
          if ((center - pt).distance < halfBrush) {
            scratched++;
            break;
          }
        }
      }
    }

    final pct = scratched / (gridSize * gridSize);
    if (pct >= widget.scratchThreshold && !_isRevealed) {
      setState(() => _isRevealed = true);
      widget.onRevealed?.call();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onTapUp: _onTap,
          child: Stack(
            key: _cardKey,
            fit: StackFit.expand,
            children: [
              // Revealed content (e.g., Reward Amount)
              Container(
                color: Colors.white,
                child: widget.revealedContent,
              ),
              
              if (!_isRevealed) ...[
                if (widget.scratchContent != null) widget.scratchContent!,
                CustomPaint(
                  size: Size.infinite,
                  painter: _GPayScratchPainter(
                    scratchPoints: _scratchPoints,
                    brushSize: widget.brushSize,
                    baseColor: widget.baseColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GPayScratchPainter extends CustomPainter {
  final List<Offset> scratchPoints;
  final double brushSize;
  final Color baseColor;

  const _GPayScratchPainter({
    required this.scratchPoints,
    required this.brushSize,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. Base Gradient (GPay Style)
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor,
          baseColor.withBlue(min(255, baseColor.blue + 40)).withGreen(min(255, baseColor.green + 20)),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 2. Geometric Pattern (Circles)
    final patternPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    
    const double spacing = 30.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        bool offsetRow = (y / spacing).floor() % 2 == 0;
        double currentX = offsetRow ? x : x - (spacing / 2);
        canvas.drawCircle(Offset(currentX, y), 3, patternPaint);
      }
    }

    // 3. Subtle Inner Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        const Radius.circular(10),
      ),
      borderPaint,
    );

    // 4. Scratch Instruction
    if (scratchPoints.isEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'SCRATCH HERE',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
    }

    // 5. Erase Scratched Areas
    if (scratchPoints.isNotEmpty) {
      final erasePaint = Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = brushSize
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (scratchPoints.length > 1) {
        final path = Path();
        path.moveTo(scratchPoints.first.dx, scratchPoints.first.dy);
        for (int i = 1; i < scratchPoints.length - 1; i++) {
          final p0 = scratchPoints[i];
          final p1 = scratchPoints[i + 1];
          path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        }
        path.lineTo(scratchPoints.last.dx, scratchPoints.last.dy);
        canvas.drawPath(path, erasePaint);
      }
      
      final circleErase = Paint()..blendMode = BlendMode.clear;
      for (final pt in scratchPoints) {
        canvas.drawCircle(pt, brushSize / 2, circleErase);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GPayScratchPainter old) =>
      old.scratchPoints.length != scratchPoints.length;
}
