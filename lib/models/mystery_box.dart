class MysteryBox {
  final int id;
  final String name;
  final String image;
  final List<int> giftPositions;
  final Map<int, double> giftRewards; // Position -> Reward amount
  final double price;
  final int giftCount;
  final bool isRandom;
  final int scratchLimit; // Number of scratches allowed per purchase (set by admin panel)

  MysteryBox({
    required this.id,
    required this.name,
    required this.image,
    required this.giftPositions,
    this.giftRewards = const {},
    this.price = 0.0,
    this.giftCount = 3,
    this.isRandom = false,
    this.scratchLimit = 0, // Must be set by admin panel - 0 means not configured
  });

  factory MysteryBox.fromJson(Map<String, dynamic> json) {
    // Parse gift rewards from JSON or use default
    Map<int, double> rewards = {};
    if (json['gift_rewards'] != null && json['gift_rewards'] is Map) {
      final rewardsMap = json['gift_rewards'] as Map<String, dynamic>;
      rewards = rewardsMap.map((key, value) => MapEntry(int.parse(key), (value as num).toDouble()));
    } else {
      // Default rewards based on gift positions
      final positions = List<int>.from(json['gift_positions'] ?? []);
      for (var pos in positions) {
        rewards[pos] = _getDefaultReward(pos);
      }
    }
    
    // Parse scratch_limit from admin panel settings - MUST be set by admin
    int scratchLimit = 0;
    if (json['scratch_limit'] != null) {
      scratchLimit = int.tryParse(json['scratch_limit'].toString()) ?? 0;
    } else if (json['scratch_card_limit'] != null) {
      scratchLimit = int.tryParse(json['scratch_card_limit'].toString()) ?? 0;
    }
    // If still 0, it will be fetched from API settings in the screen
    
    return MysteryBox(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      giftPositions: List<int>.from(json['gift_positions'] ?? []),
      giftRewards: rewards,
      price: (json['price'] ?? 0).toDouble(),
      giftCount: json['gift_count'] ?? 3,
      isRandom: json['is_random'] ?? false,
      scratchLimit: scratchLimit,
    );
  }

  static double _getDefaultReward(int position) {
    // Default reward values based on position
    final defaultRewards = {
      1: 10.0,
      2: 15.0,
      3: 20.0,
      4: 25.0,
      5: 30.0,
      6: 35.0,
      7: 40.0,
      8: 45.0,
      9: 50.0,
      10: 60.0,
      11: 75.0,
      12: 100.0,
      13: 150.0,
      14: 200.0,
      15: 250.0,
    };
    return defaultRewards[position] ?? 10.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'gift_positions': giftPositions,
      'gift_rewards': giftRewards,
      'price': price,
      'gift_count': giftCount,
      'is_random': isRandom,
      'scratch_limit': scratchLimit,
    };
  }
}
