import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class AppCategory {
  final String id;
  final String name;
  final String type; // income | expense | saving
  final String icon;

  const AppCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
  });

  factory AppCategory.fromMap(Map<String, dynamic> m) => AppCategory(
        id: m['id']?.toString() ?? '',
        name: m['name'] ?? '',
        type: m['type'] ?? 'expense',
        icon: m['icon'] ?? '💰',
      );
}

class AppTransaction {
  final String id;
  final String type; // income | expense | saving
  final String description;
  final double amount;
  final String? categoryId;
  final DateTime date;
  final bool autoRenewal;

  const AppTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    this.categoryId,
    required this.date,
    this.autoRenewal = false,
  });

  factory AppTransaction.fromMap(Map<String, dynamic> m) => AppTransaction(
        id: m['id']?.toString() ?? '',
        type: m['type'] ?? 'expense',
        description: m['description'] ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        // Database uses camelCase: categoryId
        categoryId: m['categoryId']?.toString(),
        date: m['date'] != null
            ? DateTime.tryParse(m['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        // Database uses camelCase: autoRenewal
        autoRenewal: m['autoRenewal'] == true,
      );
}

class AppGoal {
  final String id;
  final String name;
  final String type; // income | expense_limit | saving
  final double targetAmount;
  final String? categoryId;
  final String? period; // mensile | totale
  final double manualAmount;

  const AppGoal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.categoryId,
    this.period,
    this.manualAmount = 0,
  });

  factory AppGoal.fromMap(Map<String, dynamic> m) => AppGoal(
        id: m['id']?.toString() ?? '',
        name: m['name'] ?? '',
        type: m['type'] ?? 'saving',
        // Database uses camelCase: targetAmount
        targetAmount: (m['targetAmount'] as num?)?.toDouble() ?? 0,
        // Database uses camelCase: categoryId
        categoryId: m['categoryId']?.toString(),
        period: m['period']?.toString(),
        // Database uses camelCase: manualAmount
        manualAmount: (m['manualAmount'] as num?)?.toDouble() ?? 0,
      );
}

class AppSubscription {
  final String id;
  final String name;
  final double cost;
  final String? categoryId;
  final int expiryDay;
  final DateTime? lastRenewal;
  final DateTime? lastAutoRenewal;
  final String? logo;

  const AppSubscription({
    required this.id,
    required this.name,
    required this.cost,
    this.categoryId,
    required this.expiryDay,
    this.lastRenewal,
    this.lastAutoRenewal,
    this.logo,
  });

  factory AppSubscription.fromMap(Map<String, dynamic> m) => AppSubscription(
        id: m['id']?.toString() ?? '',
        name: m['name'] ?? '',
        cost: (m['cost'] as num?)?.toDouble() ?? 0,
        categoryId: m['categoryId']?.toString(),
        expiryDay: (m['expiryDay'] as num?)?.toInt() ?? 1,
        lastRenewal: m['lastRenewal'] != null
            ? DateTime.tryParse(m['lastRenewal'].toString())
            : null,
        lastAutoRenewal: m['lastAutoRenewal'] != null
            ? DateTime.tryParse(m['lastAutoRenewal'].toString())
            : null,
        logo: m['logo']?.toString(),
      );
}

// ─── Default categories ───────────────────────────────────────────────────────

final List<Map<String, String>> _defaultCategories = [
  {'name': 'Stipendio', 'type': 'income', 'icon': '💼'},
  {'name': 'Regalo', 'type': 'income', 'icon': '🎁'},
  {'name': 'Spesa', 'type': 'expense', 'icon': '🛒'},
  {'name': 'Utenze', 'type': 'expense', 'icon': '💡'},
  {'name': 'Trasporti', 'type': 'expense', 'icon': '🚗'},
  {'name': 'Intrattenimento', 'type': 'expense', 'icon': '🎮'},
  {'name': 'Casa', 'type': 'expense', 'icon': '🏠'},
  {'name': 'Salute', 'type': 'expense', 'icon': '🏥'},
  {'name': 'Risparmi', 'type': 'saving', 'icon': '🏦'},
];

// ─── Provider ────────────────────────────────────────────────────────────────

class DataProvider extends ChangeNotifier {
  List<AppCategory> _categories = [];
  List<AppTransaction> _transactions = [];
  List<AppGoal> _goals = [];
  List<AppSubscription> _subscriptions = [];
  bool _loading = false;
  String? _userId;

  List<AppCategory> get categories => _categories;
  List<AppTransaction> get transactions => _transactions;
  List<AppGoal> get goals => _goals;
  List<AppSubscription> get subscriptions => _subscriptions;
  bool get loading => _loading;

  // ── Computed totals ─────────────────────────────────────────────────────────

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);

  double get totalSavings => _transactions
      .where((t) => t.type == 'saving')
      .fold(0, (s, t) => s + t.amount);

  double get netWorth => totalIncome - totalExpenses - totalSavings;

  double get currentMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'income' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0, (s, t) => s + t.amount);
  }

  double get currentMonthExpenses {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0, (s, t) => s + t.amount);
  }

  double get currentMonthSavings {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'saving' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0, (s, t) => s + t.amount);
  }

  double get totalSubscriptionCost =>
      _subscriptions.fold(0, (s, sub) => s + sub.cost);

  // ── Monthly aggregates (January → current month) ─────────────────────────────

  List<Map<String, dynamic>> get monthlyData {
    final now = DateTime.now();
    return List.generate(now.month, (i) {
      final month = DateTime(now.year, i + 1);
      final income = _transactions
          .where((t) =>
              t.type == 'income' &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold<double>(0, (s, t) => s + t.amount);
      final expenses = _transactions
          .where((t) =>
              t.type == 'expense' &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold<double>(0, (s, t) => s + t.amount);
      final savings = _transactions
          .where((t) =>
              t.type == 'saving' &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold<double>(0, (s, t) => s + t.amount);
      return {
        'month': month,
        'income': income,
        'expenses': expenses,
        'savings': savings,
      };
    });
  }

  // ── Init / Load ─────────────────────────────────────────────────────────────

  Future<void> loadAll(String userId) async {
    _userId = userId;
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        SupabaseConfig.client.from('categories').select().eq('userId', userId),
        SupabaseConfig.client
            .from('transactions')
            .select()
            .eq('userId', userId)
            .order('date', ascending: false),
        SupabaseConfig.client.from('goals').select().eq('userId', userId),
        SupabaseConfig.client
            .from('subscriptions')
            .select()
            .eq('userId', userId),
      ]);

      _categories = (results[0] as List)
          .map((e) => AppCategory.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _transactions = (results[1] as List)
          .map((e) => AppTransaction.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _goals = (results[2] as List)
          .map((e) => AppGoal.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final rawSubs = results[3] as List;
      if (rawSubs.isNotEmpty) debugPrint('[DataProvider] raw subscription keys: ${rawSubs.first.keys.toList()}');
      _subscriptions = rawSubs
          .map((e) => AppSubscription.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (_categories.isEmpty) await _seedDefaultCategories(userId);
      await _processAutoRenewals(userId);
    } catch (e) {
      debugPrint('DataProvider loadAll error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  void clear() {
    _categories = [];
    _transactions = [];
    _goals = [];
    _subscriptions = [];
    _userId = null;
    notifyListeners();
  }

  // ── Auto-renewal logic ───────────────────────────────────────────────────────

  Future<void> _processAutoRenewals(String userId) async {
    final now = DateTime.now();
    for (final sub in _subscriptions) {
      final expected = DateTime(now.year, now.month, sub.expiryDay);
      if (now.day >= sub.expiryDay) {
        final alreadyRenewed = sub.lastAutoRenewal != null &&
            sub.lastAutoRenewal!.year == now.year &&
            sub.lastAutoRenewal!.month == now.month;
        if (!alreadyRenewed) {
          final duplicate = _transactions.any((t) =>
              t.autoRenewal &&
              t.categoryId == sub.categoryId &&
              t.date.year == now.year &&
              t.date.month == now.month);
          if (!duplicate) {
            await _insertAutoRenewalTransaction(
              userId: userId,
              sub: sub,
              date: expected,
            );
            await SupabaseConfig.client.from('subscriptions').update({
              'lastAutoRenewal': expected.toIso8601String().split('T').first
            }).eq('id', sub.id);
          }
        }
      }
    }
  }

  Future<void> _insertAutoRenewalTransaction({
    required String userId,
    required AppSubscription sub,
    required DateTime date,
  }) async {
    final data = await SupabaseConfig.client
        .from('transactions')
        .insert({
          'userId': userId,
          'type': 'expense',
          'description': sub.name,
          'amount': sub.cost,
          'categoryId': sub.categoryId,
          'date': date.toIso8601String().split('T').first,
          'autoRenewal': true,
        })
        .select()
        .single();
    _transactions.insert(
        0, AppTransaction.fromMap(Map<String, dynamic>.from(data)));
  }

  Future<void> _seedDefaultCategories(String userId) async {
    for (final cat in _defaultCategories) {
      final data = await SupabaseConfig.client
          .from('categories')
          .insert({
            'userId': userId,
            ...cat,
          })
          .select()
          .single();
      _categories.add(AppCategory.fromMap(Map<String, dynamic>.from(data)));
    }
  }

  // ── Category CRUD ───────────────────────────────────────────────────────────

  Future<void> addCategory({
    required String name,
    required String type,
    required String icon,
  }) async {
    final data = await SupabaseConfig.client
        .from('categories')
        .insert({
          'userId': _userId,
          'name': name,
          'type': type,
          'icon': icon,
        })
        .select()
        .single();
    _categories.add(AppCategory.fromMap(Map<String, dynamic>.from(data)));
    notifyListeners();
  }

  Future<void> updateCategory(
      String id, String name, String type, String icon) async {
    await SupabaseConfig.client.from('categories').update({
      'name': name,
      'type': type,
      'icon': icon,
    }).eq('id', id);
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _categories[idx] =
          AppCategory(id: id, name: name, type: type, icon: icon);
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    await SupabaseConfig.client.from('categories').delete().eq('id', id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  AppCategory? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Transaction CRUD ─────────────────────────────────────────────────────────

  Future<void> addTransaction({
    required String type,
    required String description,
    required double amount,
    String? categoryId,
    required DateTime date,
  }) async {
    final data = await SupabaseConfig.client
        .from('transactions')
        .insert({
          'userId': _userId,
          'type': type,
          'description': description,
          'amount': amount,
          'categoryId': categoryId,
          'date': date.toIso8601String().split('T').first,
          'autoRenewal': false,
        })
        .select()
        .single();
    _transactions.insert(
        0, AppTransaction.fromMap(Map<String, dynamic>.from(data)));
    notifyListeners();
  }

  Future<void> updateTransaction(
    String id, {
    required String type,
    required String description,
    required double amount,
    String? categoryId,
    required DateTime date,
  }) async {
    await SupabaseConfig.client.from('transactions').update({
      'type': type,
      'description': description,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String().split('T').first,
    }).eq('id', id);
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _transactions[idx] = AppTransaction(
        id: id,
        type: type,
        description: description,
        amount: amount,
        categoryId: categoryId,
        date: date,
        autoRenewal: _transactions[idx].autoRenewal,
      );
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await SupabaseConfig.client.from('transactions').delete().eq('id', id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ── Goal CRUD ────────────────────────────────────────────────────────────────

  Future<void> addGoal({
    required String name,
    required String type,
    required double targetAmount,
    String? categoryId,
    String? period,
  }) async {
    final data = await SupabaseConfig.client
        .from('goals')
        .insert({
          'userId': _userId,
          'name': name,
          'type': type,
          'targetAmount': targetAmount,
          'categoryId': categoryId,
          'period': period,
          'manualAmount': 0,
        })
        .select()
        .single();
    _goals.add(AppGoal.fromMap(Map<String, dynamic>.from(data)));
    notifyListeners();
  }

  Future<void> updateGoal(
    String id, {
    required String name,
    required String type,
    required double targetAmount,
    String? categoryId,
    String? period,
  }) async {
    await SupabaseConfig.client.from('goals').update({
      'name': name,
      'type': type,
      'targetAmount': targetAmount,
      'categoryId': categoryId,
      'period': period,
    }).eq('id', id);
    final idx = _goals.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _goals[idx] = AppGoal(
        id: id,
        name: name,
        type: type,
        targetAmount: targetAmount,
        categoryId: categoryId,
        period: period,
        manualAmount: _goals[idx].manualAmount,
      );
      notifyListeners();
    }
  }

  Future<void> contributeToGoal(String id, double amount) async {
    final idx = _goals.indexWhere((g) => g.id == id);
    if (idx == -1) return;
    final newAmount = _goals[idx].manualAmount + amount;
    await SupabaseConfig.client
        .from('goals')
        .update({'manualAmount': newAmount}).eq('id', id);
    _goals[idx] = AppGoal(
      id: id,
      name: _goals[idx].name,
      type: _goals[idx].type,
      targetAmount: _goals[idx].targetAmount,
      categoryId: _goals[idx].categoryId,
      period: _goals[idx].period,
      manualAmount: newAmount,
    );
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    await SupabaseConfig.client.from('goals').delete().eq('id', id);
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  double computeGoalProgress(AppGoal goal) {
    double current = goal.manualAmount;

    if (goal.categoryId != null) {
      final now = DateTime.now();
      final isMonthly = goal.period == 'mensile';
      final relevant = _transactions.where((t) {
        if (t.categoryId != goal.categoryId) return false;
        if (isMonthly) {
          return t.date.year == now.year && t.date.month == now.month;
        }
        return true;
      });

      if (goal.type == 'income') {
        current += relevant
            .where((t) => t.type == 'income')
            .fold<double>(0, (s, t) => s + t.amount);
      } else if (goal.type == 'expense_limit') {
        current += relevant
            .where((t) => t.type == 'expense')
            .fold<double>(0, (s, t) => s + t.amount);
      } else {
        // saving
        current += relevant
            .where((t) => t.type == 'saving')
            .fold<double>(0, (s, t) => s + t.amount);
      }
    }

    if (goal.targetAmount == 0) return 1;
    return (current / goal.targetAmount).clamp(0, 1);
  }

  // ── Subscription CRUD ────────────────────────────────────────────────────────

  Future<String> uploadSubscriptionLogo(
      List<int> fileBytes, String fileName) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final path = '$_userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await SupabaseConfig.client.storage
        .from('subscriptions')
        .uploadBinary(path, Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(upsert: true));
    return SupabaseConfig.client.storage
        .from('subscriptions')
        .getPublicUrl(path);
  }

  Future<void> addSubscription({
    required String name,
    required double cost,
    String? categoryId,
    required int expiryDay,
    String? logo,
    DateTime? lastRenewal,
  }) async {
    final data = await SupabaseConfig.client
        .from('subscriptions')
        .insert({
          'userId': _userId,
          'name': name,
          'cost': cost,
          'categoryId': categoryId,
          'expiryDay': expiryDay,
          if (logo != null) 'logo': logo,
          if (lastRenewal != null) 'lastRenewal': lastRenewal.toIso8601String(),
        })
        .select()
        .single();
    _subscriptions
        .add(AppSubscription.fromMap(Map<String, dynamic>.from(data)));
    notifyListeners();
  }

  Future<void> updateSubscription(
    String id, {
    required String name,
    required double cost,
    String? categoryId,
    required int expiryDay,
    String? logo,
    DateTime? lastRenewal,
  }) async {
    await SupabaseConfig.client.from('subscriptions').update({
      'name': name,
      'cost': cost,
      'categoryId': categoryId,
      'expiryDay': expiryDay,
      'logo': logo,
      if (lastRenewal != null) 'lastRenewal': lastRenewal.toIso8601String(),
    }).eq('id', id);
    final idx = _subscriptions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _subscriptions[idx] = AppSubscription(
        id: id,
        name: name,
        cost: cost,
        categoryId: categoryId,
        expiryDay: expiryDay,
        lastRenewal: lastRenewal ?? _subscriptions[idx].lastRenewal,
        lastAutoRenewal: _subscriptions[idx].lastAutoRenewal,
        logo: logo,
      );
      notifyListeners();
    }
  }

  Future<void> deleteSubscription(String id) async {
    await SupabaseConfig.client.from('subscriptions').delete().eq('id', id);
    _subscriptions.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
