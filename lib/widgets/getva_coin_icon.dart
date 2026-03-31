import 'package:flutter/material.dart';

class GetvaCoinIcon extends StatelessWidget {
  final double size;
  final bool isCircular;

  const GetvaCoinIcon({
    super.key,
    this.size = 100,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(size * 0.25),
        boxShadow: [
          // Elegant glow for a "perfect" coin
          BoxShadow(
            color: const Color(0xFFD4A847).withOpacity(0.5),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.05,
          ),
          BoxShadow(
            color: const Color(0xFFFFE066).withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: Offset(-size * 0.05, -size * 0.05),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isCircular ? BorderRadius.circular(size) : BorderRadius.circular(size * 0.25),
        child: Image.asset(
          'asserts/getva_coin.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to a simple circle if image fails to load
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFD4A847),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
