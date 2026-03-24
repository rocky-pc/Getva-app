import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleScratchCard extends StatefulWidget {
  final Widget revealedContent;
  final Widget? scratchContent;
  final VoidCallback? onRevealed;
  final double scratchThreshold;
  final double brushSize;
  final Color baseColor;

  const SimpleScratchCard({
    Key? key,
    required this.revealedContent,
    this.scratchContent,
    this.onRevealed,
    this.scratchThreshold = 0.45,
    this.brushSize = 50.0,
    this.baseColor = const Color(0xFF1A73E8),
  }) : super(key: key);

  @override
  State<SimpleScratchCard> createState() => _SimpleScratchCardState();
}

class _SimpleScratchCardState extends State<SimpleScratchCard> with TickerProviderStateMixin {
  bool _isRevealed = false;
  bool _revealAnimationStarted = false;
  
  final Path _scratchPath = Path();
  final List<Offset> _points = [];
  
  late List<bool> _scratchedGrid;
  final int _gridColumns = 15;
  final int _gridRows = 15;
  int _totalScratchedCells = 0;

  final GlobalKey _cardKey = GlobalKey();
  
  late AnimationController _revealController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _revealScaleAnimation;

  late AnimationController _zoomController;
  late Animation<double> _interactionScaleAnimation;

  @override
  void initState() {
    super.initState();
    _scratchedGrid = List.filled(_gridColumns * _gridRows, false);
    
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _revealController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    
    _revealScaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutQuad),
    );

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _interactionScaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_revealAnimationStarted) return;
    _zoomController.forward();
    _handleNewPoint(details.localPosition, isNewPath: true);
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_revealAnimationStarted) return;
    _handleNewPoint(details.localPosition);
    if (_points.length % 6 == 0) {
      HapticFeedback.selectionClick();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_revealAnimationStarted) {
      _zoomController.reverse();
    }
  }

  void _handleNewPoint(Offset pos, {bool isNewPath = false}) {
    final RenderBox? box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    setState(() {
      if (isNewPath) {
        _scratchPath.moveTo(pos.dx, pos.dy);
        _points.add(pos);
      } else {
        final lastPos = _points.last;
        _scratchPath.quadraticBezierTo(
          lastPos.dx, lastPos.dy, 
          (lastPos.dx + pos.dx) / 2, (lastPos.dy + pos.dy) / 2
        );
        _points.add(pos);
      }
      _updateIncrementalThreshold(pos, box.size);
    });
  }

  void _updateIncrementalThreshold(Offset pos, Size size) {
    if (_revealAnimationStarted) return;

    final double cellWidth = size.width / _gridColumns;
    final double cellHeight = size.height / _gridRows;
    final double radius = widget.brushSize / 2;

    int startCol = ((pos.dx - radius) / cellWidth).floor().clamp(0, _gridColumns - 1);
    int endCol = ((pos.dx + radius) / cellWidth).floor().clamp(0, _gridColumns - 1);
    int startRow = ((pos.dy - radius) / cellHeight).floor().clamp(0, _gridRows - 1);
    int endRow = ((pos.dy + radius) / cellHeight).floor().clamp(0, _gridRows - 1);

    for (int col = startCol; col <= endCol; col++) {
      for (int row = startRow; row <= endRow; row++) {
        int index = row * _gridColumns + col;
        if (!_scratchedGrid[index]) {
          final cellCenter = Offset((col + 0.5) * cellWidth, (row + 0.5) * cellHeight);
          if ((cellCenter - pos).distance <= radius) {
            _scratchedGrid[index] = true;
            _totalScratchedCells++;
          }
        }
      }
    }

    if (_totalScratchedCells / (_gridColumns * _gridRows) >= widget.scratchThreshold) {
      _startReveal();
    }
  }

  void _startReveal() {
    if (_revealAnimationStarted) return;
    setState(() => _revealAnimationStarted = true);
    _zoomController.reverse();
    HapticFeedback.heavyImpact();
    _revealController.forward().then((_) {
      if (mounted) {
        setState(() => _isRevealed = true);
        widget.onRevealed?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _interactionScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _interactionScaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Stack(
                  key: _cardKey,
                  fit: StackFit.expand,
                  children: [
                    widget.revealedContent,
                    if (!_isRevealed)
                      AnimatedBuilder(
                        animation: _revealController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _opacityAnimation.value,
                            child: Transform.scale(
                              scale: _revealAnimationStarted ? _revealScaleAnimation.value : 1.0,
                              child: child,
                            ),
                          );
                        },
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _SmoothScratchPainter(
                            path: _scratchPath,
                            brushSize: widget.brushSize,
                            baseColor: widget.baseColor,
                            showHint: _points.isEmpty,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmoothScratchPainter extends CustomPainter {
  final Path path;
  final double brushSize;
  final Color baseColor;
  final bool showHint;

  _SmoothScratchPainter({
    required this.path,
    required this.brushSize,
    required this.baseColor,
    required this.showHint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor,
          baseColor.withBlue(min(255, baseColor.blue + 35)).withGreen(min(255, baseColor.green + 15)),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final patternPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    const double spacing = 36.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        bool offsetRow = (y / spacing).floor() % 2 == 0;
        double currentX = offsetRow ? x : x - (spacing / 2);
        canvas.drawCircle(Offset(currentX, y), 2.8, patternPaint);
      }
    }

    if (showHint) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'SCRATCH HERE',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
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

    final erasePaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, erasePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SmoothScratchPainter old) => true;
}
