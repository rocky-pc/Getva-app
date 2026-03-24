class GetvaCoinSettings {
  final bool isEnabled;
  final double exchangeRate;
  final int minPurchase;
  final int maxPurchase;
  final int dailyPurchaseLimit;
  final int dailyWithdrawalLimit;
  final double withdrawalFee;
  final double rewardRate;
  final double transferFee;
  final int minTransfer;
  final int maxTransfer;
  final bool promotionActive;
  final int promotionBonus;
  final int promotionMinPurchase;

  GetvaCoinSettings({
    required this.isEnabled,
    required this.exchangeRate,
    required this.minPurchase,
    required this.maxPurchase,
    required this.dailyPurchaseLimit,
    required this.dailyWithdrawalLimit,
    required this.withdrawalFee,
    required this.rewardRate,
    required this.transferFee,
    required this.minTransfer,
    required this.maxTransfer,
    required this.promotionActive,
    required this.promotionBonus,
    required this.promotionMinPurchase,
  });

  factory GetvaCoinSettings.fromJson(Map<String, dynamic> json) {
    return GetvaCoinSettings(
      isEnabled: json['is_enabled'] == '1' || json['is_enabled'] == true,
      exchangeRate: double.tryParse(json['exchange_rate']?.toString() ?? '1.00') ?? 1.00,
      minPurchase: int.tryParse(json['min_purchase']?.toString() ?? '10') ?? 10,
      maxPurchase: int.tryParse(json['max_purchase']?.toString() ?? '5000') ?? 5000,
      dailyPurchaseLimit: int.tryParse(json['daily_purchase_limit']?.toString() ?? '10000') ?? 10000,
      dailyWithdrawalLimit: int.tryParse(json['daily_withdrawal_limit']?.toString() ?? '5000') ?? 5000,
      withdrawalFee: double.tryParse(json['withdrawal_fee']?.toString() ?? '0.05') ?? 0.05,
      rewardRate: double.tryParse(json['reward_rate']?.toString() ?? '0.10') ?? 0.10,
      transferFee: double.tryParse(json['transfer_fee']?.toString() ?? '0.02') ?? 0.02,
      minTransfer: int.tryParse(json['min_transfer']?.toString() ?? '10') ?? 10,
      maxTransfer: int.tryParse(json['max_transfer']?.toString() ?? '1000') ?? 1000,
      promotionActive: json['promotion_active'] == '1' || json['promotion_active'] == true,
      promotionBonus: int.tryParse(json['promotion_bonus']?.toString() ?? '0') ?? 0,
      promotionMinPurchase: int.tryParse(json['promotion_min_purchase']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'exchange_rate': exchangeRate,
      'min_purchase': minPurchase,
      'max_purchase': maxPurchase,
      'daily_purchase_limit': dailyPurchaseLimit,
      'daily_withdrawal_limit': dailyWithdrawalLimit,
      'withdrawal_fee': withdrawalFee,
      'reward_rate': rewardRate,
      'transfer_fee': transferFee,
      'min_transfer': minTransfer,
      'max_transfer': maxTransfer,
      'promotion_active': promotionActive,
      'promotion_bonus': promotionBonus,
      'promotion_min_purchase': promotionMinPurchase,
    };
  }
}

class GetvaCoinPackage {
  final int id;
  final int coinAmount;
  final double priceInRupees;
  final bool isActive;

  GetvaCoinPackage({
    required this.id,
    required this.coinAmount,
    required this.priceInRupees,
    required this.isActive,
  });

  factory GetvaCoinPackage.fromJson(Map<String, dynamic> json) {
    return GetvaCoinPackage(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      coinAmount: int.tryParse(json['coin_amount']?.toString() ?? '0') ?? 0,
      priceInRupees: double.tryParse(json['price_in_rupees']?.toString() ?? '0.00') ?? 0.00,
      isActive: json['is_active'] == '1' || json['is_active'] == true,
    );
  }

  double get ratePerCoin => priceInRupees / coinAmount;
}

class GetvaCoinWallet {
  final int userId;
  final double coinBalance;

  GetvaCoinWallet({
    required this.userId,
    required this.coinBalance,
  });

  factory GetvaCoinWallet.fromJson(Map<String, dynamic> json) {
    return GetvaCoinWallet(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      coinBalance: double.tryParse(json['coin_balance']?.toString() ?? '0.00') ?? 0.00,
    );
  }
}

class GetvaCoinTransaction {
  final int id;
  final int userId;
  final String transactionType;
  final double amount;
  final double coinValue;
  final double exchangeRate;
  final String status;
  final String? description;
  final DateTime createdAt;
  final String? userName;

  GetvaCoinTransaction({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.amount,
    required this.coinValue,
    required this.exchangeRate,
    required this.status,
    this.description,
    required this.createdAt,
    this.userName,
  });

  factory GetvaCoinTransaction.fromJson(Map<String, dynamic> json) {
    return GetvaCoinTransaction(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      transactionType: json['transaction_type'] ?? 'purchase',
      amount: double.tryParse(json['amount']?.toString() ?? '0.00') ?? 0.00,
      coinValue: double.tryParse(json['coin_value']?.toString() ?? '0.00') ?? 0.00,
      exchangeRate: double.tryParse(json['exchange_rate']?.toString() ?? '1.00') ?? 1.00,
      status: json['status'] ?? 'pending',
      description: json['description'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userName: json['user_name'],
    );
  }
}