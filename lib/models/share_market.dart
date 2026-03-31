class Company {
  final int id;
  final String symbol;
  final String name;
  final String sector;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.symbol,
    required this.name,
    required this.sector,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? 0,
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      sector: json['sector'] ?? '',
      description: json['description'] ?? '',
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
      'symbol': symbol,
      'name': name,
      'sector': sector,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Share {
  final int id;
  final int companyId;
  final String companySymbol;
  final String companyName;
  final String sector;
  final double currentPrice;
  final double previousClose;
  final double dayHigh;
  final double dayLow;
  final int volume;
  final double peRatio;
  final String marketCap;
  final double change;
  final double changePercent;
  final bool isActive;
  final DateTime lastUpdated;

  Share({
    required this.id,
    required this.companyId,
    required this.companySymbol,
    required this.companyName,
    required this.sector,
    required this.currentPrice,
    required this.previousClose,
    required this.dayHigh,
    required this.dayLow,
    required this.volume,
    required this.peRatio,
    required this.marketCap,
    required this.change,
    required this.changePercent,
    required this.isActive,
    required this.lastUpdated,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      companySymbol: json['company_symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      sector: json['sector'] ?? '',
      currentPrice: double.tryParse(json['current_price']?.toString() ?? '0') ?? 0,
      previousClose: double.tryParse(json['previous_close']?.toString() ?? '0') ?? 0,
      dayHigh: double.tryParse(json['day_high']?.toString() ?? '0') ?? 0,
      dayLow: double.tryParse(json['day_low']?.toString() ?? '0') ?? 0,
      volume: int.tryParse(json['volume']?.toString() ?? '0') ?? 0,
      peRatio: double.tryParse(json['pe_ratio']?.toString() ?? '0') ?? 0,
      marketCap: json['market_cap'] ?? '',
      change: double.tryParse(json['change']?.toString() ?? '0') ?? 0,
      changePercent: double.tryParse(json['change_percent']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'company_symbol': companySymbol,
      'company_name': companyName,
      'sector': sector,
      'current_price': currentPrice,
      'previous_close': previousClose,
      'day_high': dayHigh,
      'day_low': dayLow,
      'volume': volume,
      'pe_ratio': peRatio,
      'market_cap': marketCap,
      'change': change,
      'change_percent': changePercent,
      'is_active': isActive,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class ShareTransaction {
  final int id;
  final int userId;
  final int shareId;
  final String companySymbol;
  final String transactionType; // 'BUY' or 'SELL'
  final int quantity;
  final double pricePerShare;
  final double totalAmount;
  final DateTime transactionDate;
  final String status; // 'pending', 'completed', 'cancelled'

  ShareTransaction({
    required this.id,
    required this.userId,
    required this.shareId,
    required this.companySymbol,
    required this.transactionType,
    required this.quantity,
    required this.pricePerShare,
    required this.totalAmount,
    required this.transactionDate,
    required this.status,
  });

  factory ShareTransaction.fromJson(Map<String, dynamic> json) {
    return ShareTransaction(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      shareId: json['share_id'] ?? 0,
      companySymbol: json['company_symbol'] ?? '',
      transactionType: json['transaction_type'] ?? 'BUY',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      pricePerShare: double.tryParse(json['price_per_share']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'share_id': shareId,
      'company_symbol': companySymbol,
      'transaction_type': transactionType,
      'quantity': quantity,
      'price_per_share': pricePerShare,
      'total_amount': totalAmount,
      'transaction_date': transactionDate.toIso8601String(),
      'status': status,
    };
  }
}

class UserShareHolding {
  final int shareId;
  final String companySymbol;
  final String companyName;
  final int quantity;
  final double averagePrice;
  final double currentPrice;
  final double totalValue;
  final double profitLoss;

  UserShareHolding({
    required this.shareId,
    required this.companySymbol,
    required this.companyName,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.totalValue,
    required this.profitLoss,
  });

  factory UserShareHolding.fromJson(Map<String, dynamic> json) {
    return UserShareHolding(
      shareId: json['share_id'] ?? 0,
      companySymbol: json['company_symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      averagePrice: double.tryParse(json['average_price']?.toString() ?? '0') ?? 0,
      currentPrice: double.tryParse(json['current_price']?.toString() ?? '0') ?? 0,
      totalValue: double.tryParse(json['total_value']?.toString() ?? '0') ?? 0,
      profitLoss: double.tryParse(json['profit_loss']?.toString() ?? '0') ?? 0,
    );
  }
}