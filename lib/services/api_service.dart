import 'dart:convert';
import 'package:Getva/services/session_manager.dart';
import 'package:http/http.dart' as http;
import '../models/gold_rate.dart';

class ApiService {
  // For Android emulator: use 10.0.2.2 to connect to host machine's localhost
  // For iOS simulator: use localhost or 10.0.2.2
  // For real device: use your computer's IP address (run 'ipconfig' on Windows to get your IP)
  // For web browser testing: use localhost
  static String baseUrl = 'https://getva.in/api';

  static void setBaseUrl(String url) => baseUrl = url;
  static void resetBaseUrl() => baseUrl = 'https://getva.in/api';

  static Future<Map<String, dynamic>> updateGoldRates(List<GoldRate> rates) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gold_rates.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'update_rates',
          'rates': jsonEncode(rates
              .map((rate) => {
                    'gold_type': rate.goldType,
                    'rate_per_gram': rate.ratePerGram,
                  })
              .toList()),
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to sync gold rates: $e'};
    }
  }

  // User APIs
  static Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'login',
        'email_or_phone': emailOrPhone,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users.php?id=$userId'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateWallet(int userId, double balance) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users.php?id=$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'wallet_balance': balance}),
    );
    return jsonDecode(response.body);
  }

  // Purchase mystery box - deduct from wallet
  static Future<Map<String, dynamic>> purchaseMysteryBox({
    required int userId,
    required int boxId,
    required double boxPrice,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users.php?id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'purchase_box',
          'box_id': boxId,
          'box_price': boxPrice,
        }),
      );

      // Debug: print response status and body
      print('purchaseMysteryBox response status: ${response.statusCode}');
      print('purchaseMysteryBox response body: ${response.body}');

      // Try to parse the response
      final decoded = jsonDecode(response.body);
      return decoded;
    } catch (e) {
      // If parsing fails, return a map that will trigger error handling
      print('purchaseMysteryBox exception: $e');
      return {
        'success': false,
        'error': 'Failed to parse response: $e'
      };
    }
  }

  // Get user wallet balance
  static Future<double> getUserWalletBalance(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users.php?id=$userId'));
      final data = jsonDecode(response.body);
      return double.tryParse(data['wallet_balance']?.toString() ?? '0') ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Check if user has already purchased a specific box
  static Future<bool> hasUserPurchasedBox(int userId, int boxId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions.php?user_id=$userId&box_id=$boxId&type=purchase'),
      );

      // Debug: print response status and body
      print('hasUserPurchasedBox response status: ${response.statusCode}');
      print('hasUserPurchasedBox response body: ${response.body}');

      // Check if response is successful
      if (response.statusCode != 200) {
        print('hasUserPurchasedBox: Non-200 status code');
        return false;
      }

      final data = jsonDecode(response.body);

      // If there's any purchase transaction for this box, return true
      if (data is List && data.isNotEmpty) {
        print('hasUserPurchasedBox: Found ${data.length} purchase(s)');
        return true;
      }

      print('hasUserPurchasedBox: No purchases found');
      return false;
    } catch (e) {
      print('hasUserPurchasedBox exception: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> updateUserCredentials(int userId, {String? email, String? phone, String? password}) async {
    final Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (password != null && password.isNotEmpty) data['password'] = password;

    final response = await http.put(
      Uri.parse('$baseUrl/users.php?id=$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // Scratch Card APIs
  static Future<List<dynamic>> getScratchCards() async {
    final response = await http.get(Uri.parse('$baseUrl/scratch_cards.php'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getScratchCard(int cardId) async {
    final response = await http.get(Uri.parse('$baseUrl/scratch_cards.php?id=$cardId'));
    return jsonDecode(response.body);
  }

  // Save scratch history to database
  static Future<Map<String, dynamic>> saveScratchHistory({
    required int userId,
    required int mysteryBoxId,
    required int cardPosition,
    required bool isGift,
    required double rewardAmount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'save_scratch',
        'user_id': userId,
        'mystery_box_id': mysteryBoxId,
        'card_position': cardPosition,
        'is_gift': isGift,
        'reward_amount': rewardAmount,
      }),
    );
    return jsonDecode(response.body);
  }

  // Get scratch history for a user and mystery box
  static Future<List<Map<String, dynamic>>> getScratchHistory({
    required int userId,
    required int mysteryBoxId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'get_scratch_history',
        'user_id': userId,
        'mystery_box_id': mysteryBoxId,
      }),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['history'] ?? []);
    }
    return [];
  }

  // Transaction APIs
  static Future<List<dynamic>> getUserTransactions(int userId, {int limit = 50, int offset = 0}) async {
    final response = await http.get(Uri.parse('$baseUrl/transactions.php?user_id=$userId&limit=$limit&offset=$offset'));
    return jsonDecode(response.body);
  }

  // Get user profile data
  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users.php?id=$userId'));
    return jsonDecode(response.body);
  }

  // Update user profile (name, email, phone)
  static Future<Map<String, dynamic>> updateUserProfile(int userId, {String? name, String? email, String? phone}) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;

    final response = await http.put(
      Uri.parse('$baseUrl/users.php?id=$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // Update user password
  static Future<Map<String, dynamic>> updateUserPassword(int userId, String newPassword) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users.php?id=$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': newPassword}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transactionData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transactionData),
    );
    return jsonDecode(response.body);
  }

  // Settings APIs
  static Future<List<int>> getRupeeOptions() async {
    final response = await http.get(Uri.parse('$baseUrl/settings.php'));
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return List<int>.from(data['rupee_options']);
    }
    // Return default options if API fails
    return [10, 50, 100, 500, 1000, 2000];
  }

  // Get scratch card limit from settings
  static Future<int> getScratchCardLimit() async {
    final response = await http.get(Uri.parse('$baseUrl/settings.php'));
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return int.tryParse(data['scratch_card_limit']?.toString() ?? '5') ?? 5;
    }
    // Return default limit if API fails
    return 5;
  }

  // App Config APIs (banner, mystery boxes)
  static Future<Map<String, dynamic>> getAppConfig() async {
    final response = await http.get(Uri.parse('$baseUrl/settings.php'));
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return {
        'banner_image': data['banner_image'] ?? 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
        'mystery_boxes': data['mystery_boxes'] ?? [],
        'scratch_card_limit': int.tryParse(data['scratch_card_limit']?.toString() ?? '5') ?? 5,
      };
    }
    return {
      'banner_image': 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
      'mystery_boxes': [],
      'scratch_card_limit': 5,
    };
  }

  // Gold APIs
  static Future<List<GoldRate>> getGoldRates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gold_rates.php?action=rates'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => GoldRate.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('getGoldRates error: $e');
      return [];
    }
  }

  static Future<List<GoldRateHistory>> getGoldRateHistory({
    String goldType = '24K',
    String period = '3months',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gold_rates.php?action=history&gold_type=$goldType&period=$period'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => GoldRateHistory.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('getGoldRateHistory error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> purchaseGold({
    required int userId,
    required String goldType,
    required double grams,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gold_rates.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'purchase',
          'user_id': userId,
          'gold_type': goldType,
          'grams': grams,
          'amount': amount,
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('purchaseGold error: $e');
      return {'success': false, 'message': 'Failed to purchase gold: $e'};
    }
  }

  static Future<List<GoldWallet>> getUserGoldWallet(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gold_rates.php?action=user_wallet&user_id=$userId'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => GoldWallet.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('getUserGoldWallet error: $e');
      return [];
    }
  }

  static Future<List<GoldPurchase>> getUserGoldPurchases(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gold_rates.php?action=purchase_history&user_id=$userId'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => GoldPurchase.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('getUserGoldPurchases error: $e');
      return [];
    }
  }

  static Future<double> getWalletBalance() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) throw Exception('User not logged in');
    final response = await http.get(Uri.parse('$baseUrl/wallet_balance.php?user_id=$userId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Check if the response was successful before returning the balance
      if (data['success'] == true) {
        return (data['balance'] ?? 0.0).toDouble();
      } else {
        // If not successful, try to get balance from users.php as fallback
        return getUserWalletBalance(userId);
      }
    }
    throw Exception('Failed to load wallet balance');
  }

  static Future<double> getGoldWalletBalance() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) throw Exception('User not logged in');
    final response = await http.get(Uri.parse('$baseUrl/gold_wallet_balance.php?user_id=$userId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['gold_balance'] ?? 0.0;
    }
    throw Exception('Failed to load gold wallet balance');
  }

  static Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) throw Exception('User not logged in');
    final response = await http.get(Uri.parse('$baseUrl/recent_transactions.php?user_id=$userId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
    }
    throw Exception('Failed to load transactions');
  }

  // ======================
  // GETVA COIN APIs
  // ======================

  // Get Getva Coin settings
  static Future<Map<String, dynamic>> getGetvaCoinSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getva_coin.php?action=getva_coin_settings'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to get settings: $e'};
    }
  }

  // Get Getva Coin packages
  static Future<Map<String, dynamic>> getGetvaCoinPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getva_coin.php?action=getva_coin_packages'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to get packages: $e'};
    }
  }

  // Get Getva Coin wallet balance
  static Future<Map<String, dynamic>> getGetvaCoinWallet(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getva_coin.php?action=getva_coin_wallet&user_id=$userId'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to get wallet: $e'};
    }
  }

  // Get Getva Coin transactions
  static Future<Map<String, dynamic>> getGetvaCoinTransactions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getva_coin.php?action=getva_coin_transactions&user_id=$userId'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to get transactions: $e'};
    }
  }

  // Purchase Getva Coins
  static Future<Map<String, dynamic>> purchaseGetvaCoins({
    required int userId,
    required int packageId,
    required int coinAmount,
    required double price,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getva_coin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'purchase_getva_coins',
          'user_id': userId,
          'package_id': packageId,
          'coin_amount': coinAmount,
          'price': price,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to purchase coins: $e'};
    }
  }
}

