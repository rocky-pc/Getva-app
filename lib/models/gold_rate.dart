class GoldRate {
  final int id;
  final String goldType;
  final double ratePerGram;
  final double ratePerTola;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoldRate({
    required this.id,
    required this.goldType,
    required this.ratePerGram,
    required this.ratePerTola,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoldRate.fromJson(Map<String, dynamic> json) {
    return GoldRate(
      id: json['id'] ?? 0,
      goldType: json['gold_type'] ?? '24K',
      ratePerGram: double.tryParse(json['rate_per_gram']?.toString() ?? '0') ?? 0,
      ratePerTola: double.tryParse(json['rate_per_tola']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gold_type': goldType,
      'rate_per_gram': ratePerGram,
      'rate_per_tola': ratePerTola,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class GoldRateHistory {
  final String date;
  final double rate;

  GoldRateHistory({
    required this.date,
    required this.rate,
  });

  factory GoldRateHistory.fromJson(Map<String, dynamic> json) {
    return GoldRateHistory(
      date: json['date'] ?? '',
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0,
    );
  }
}

class GoldPurchase {
  final int id;
  final int userId;
  final String goldType;
  final double grams;
  final double ratePerGram;
  final double totalAmount;
  final int? transactionId;
  final String status;
  final DateTime purchasedAt;

  GoldPurchase({
    required this.id,
    required this.userId,
    required this.goldType,
    required this.grams,
    required this.ratePerGram,
    required this.totalAmount,
    this.transactionId,
    required this.status,
    required this.purchasedAt,
  });

  factory GoldPurchase.fromJson(Map<String, dynamic> json) {
    return GoldPurchase(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      goldType: json['gold_type'] ?? '24K',
      grams: double.tryParse(json['grams']?.toString() ?? '0') ?? 0,
      ratePerGram: double.tryParse(json['rate_per_gram']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      transactionId: json['transaction_id'],
      status: json['status'] ?? 'completed',
      purchasedAt: json['purchased_at'] != null
          ? DateTime.tryParse(json['purchased_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class GoldWallet {
  final int id;
  final int userId;
  final String goldType;
  final double grams;
  final DateTime updatedAt;

  GoldWallet({
    required this.id,
    required this.userId,
    required this.goldType,
    required this.grams,
    required this.updatedAt,
  });

  factory GoldWallet.fromJson(Map<String, dynamic> json) {
    return GoldWallet(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      goldType: json['gold_type'] ?? '24K',
      grams: double.tryParse(json['grams']?.toString() ?? '0') ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}