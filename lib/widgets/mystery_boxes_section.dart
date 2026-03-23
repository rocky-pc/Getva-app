import 'package:flutter/material.dart';
import '../models/mystery_box.dart';

class MysteryBoxesSection extends StatelessWidget {
  final List<MysteryBox> boxes;
  final Function(MysteryBox) onBoxTap;

  const MysteryBoxesSection({
    Key? key,
    required this.boxes,
    required this.onBoxTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Changed to GridView with 2 columns
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: boxes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85, // Adjust height-to-width ratio
            ),
            itemBuilder: (context, index) {
              final box = boxes[index];
              return _buildBoxCard(box);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoxCard(MysteryBox box) {
    return GestureDetector(
      onTap: () => onBoxTap(box),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Slightly lighter than pure black
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1), // Subtle border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.05), // Subtle glow
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  box.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.inventory_2, color: Colors.amber),
                  ),
                ),
              ),

              // Gradient Overlay for text legibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // Gift Count Badge (Top Right)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: Text(
                    '${box.giftPositions.length} 🎁',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),

              // Name Label (Bottom)
              Positioned(
                bottom: 12,
                left: 8,
                right: 8,
                child: Column(
                  children: [
                    Text(
                      box.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (box.price > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A847),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${box.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF1A1200),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const Text(
                        "TAP TO OPEN",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}