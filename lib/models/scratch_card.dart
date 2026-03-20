class ScratchCard {
  final int id;
  final String name;
  final String description;
  final double price;
  final bool isBox;
  final int? quantityInBox; // null if not a box

  const ScratchCard({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isBox,
    this.quantityInBox,
  });
}