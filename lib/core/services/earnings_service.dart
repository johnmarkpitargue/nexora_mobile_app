import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/earning_record.dart';
import '../network/api_client.dart';
import 'rider_service.dart';

class EarningsService extends ChangeNotifier {
  static final EarningsService instance = EarningsService._();
  EarningsService._();

  final List<EarningTransaction> _transactions = [];
  List<EarningTransaction> get transactions => List.unmodifiable(_transactions);

  List<DayEarnings> _weeklyData = [];
  List<DayEarnings> get weeklyData => _weeklyData.isNotEmpty
      ? List.unmodifiable(_weeklyData)
      : _emptyWeekPlaceholder();

  List<DayEarnings>? _testMonthlyData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  // Earnings & Payout Wallet (strictly separate from COD cash collected)
  double _earningsBalance = 0.0;
  double get earningsBalance => _earningsBalance;

  double _availableForPayout = 0.0;
  double get availableForPayout => _availableForPayout;

  double _pendingPayoutAmount = 0.0;
  double get pendingPayoutAmount => _pendingPayoutAmount;

  double _totalPaidOut = 0.0;
  double get totalPaidOut => _totalPaidOut;

  double _onHoldAmount = 0.0;
  double get onHoldAmount => _onHoldAmount;

  double _totalEarnedAllTime = 0.0;
  double get totalEarnedAllTime => _totalEarnedAllTime;

  double _weeklyTotalPay = 0.0;
  double get weeklyTotalPay => _weeklyTotalPay;

  bool _hasFetchedRemote = false;
  bool get hasFetchedRemote => _hasFetchedRemote;

  double _todayPay = 0.0;
  double get todayPay => _todayPay;

  double _todayPickupPay = 0.0;
  double get todayPickupPay => _todayPickupPay;

  double _todayDeliveryPay = 0.0;
  double get todayDeliveryPay => _todayDeliveryPay;

  double _todayFailedDeliveryPay = 0.0;
  double get todayFailedDeliveryPay => _todayFailedDeliveryPay;

  int _todayPickupsCount = 0;
  int get todayPickupsCount => _todayPickupsCount;

  int _todayDeliveriesCount = 0;
  int get todayDeliveriesCount => _todayDeliveriesCount;

  // COD Cash Accountability Wallet (never combined with courier earnings)
  double _codHeldBalance = 0.0;
  double get codHeldBalance => _codHeldBalance;

  double _codPendingVerificationAmount = 0.0;
  double get codPendingVerificationAmount => _codPendingVerificationAmount;

  double _codAvailableForRemittance = 0.0;
  double get codAvailableForRemittance => _codAvailableForRemittance;

  double _codTotalCollectedLifetime = 0.0;
  double get codTotalCollectedLifetime => _codTotalCollectedLifetime;

  double _codTotalVerifiedRemitted = 0.0;
  double get codTotalVerifiedRemitted => _codTotalVerifiedRemitted;

  double _codTotalShortageFlagged = 0.0;
  double get codTotalShortageFlagged => _codTotalShortageFlagged;

  List<Map<String, dynamic>> _openCodCollections = [];
  List<Map<String, dynamic>> get openCodCollections =>
      List.unmodifiable(_openCodCollections);

  List<Map<String, dynamic>> _recentRemittances = [];
  List<Map<String, dynamic>> get recentRemittances =>
      List.unmodifiable(_recentRemittances);

  List<Map<String, dynamic>> _recentPayouts = [];
  List<Map<String, dynamic>> get recentPayouts =>
      List.unmodifiable(_recentPayouts);

  Map<String, dynamic>? _activePolicy;
  Map<String, dynamic>? get activePolicy => _activePolicy;

  List<DayEarnings> _emptyWeekPlaceholder() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List.generate(days.length, (i) {
      return DayEarnings(
        dayName: days[i],
        amount: 0.0,
        ordersCount: 0,
        hoursWorked: 0.0,
        tipsAmount: 0.0,
        dateLabel: days[i],
        isCurrent: i == days.length - 1,
      );
    });
  }

  List<DayEarnings> get todayData {
    final now = DateTime.now();
    final todayTxns = _transactions.where((t) =>
        t.amount > 0 &&
        t.timestamp.year == now.year &&
        t.timestamp.month == now.month &&
        t.timestamp.day == now.day);

    final buckets = <String, List<EarningTransaction>>{
      '08:00': [],
      '11:00': [],
      '14:00': [],
      '17:00': [],
    };
    for (final t in todayTxns) {
      final h = t.timestamp.hour;
      if (h < 11) {
        buckets['08:00']!.add(t);
      } else if (h < 14) {
        buckets['11:00']!.add(t);
      } else if (h < 17) {
        buckets['14:00']!.add(t);
      } else {
        buckets['17:00']!.add(t);
      }
    }

    const labels = {
      '08:00': 'Morning (00:00-11:00)',
      '11:00': 'Midday (11:00-14:00)',
      '14:00': 'Afternoon (14:00-17:00)',
      '17:00': 'Evening (17:00-24:00)',
    };

    final keys = buckets.keys.toList();
    return List.generate(keys.length, (idx) {
      final key = keys[idx];
      final list = buckets[key]!;
      return DayEarnings(
        dayName: key,
        amount: list.fold(0.0, (sum, item) => sum + item.amount),
        ordersCount: list.length,
        hoursWorked: 0.0,
        tipsAmount: 0.0,
        dateLabel: labels[key]!,
        isCurrent: idx == keys.length - 1,
      );
    });
  }

  List<DayEarnings> get monthlyData {
    if (_testMonthlyData != null) {
      return List.unmodifiable(_testMonthlyData!);
    }
    final weekSum = _weeklyData.fold(0.0, (s, d) => s + d.amount);
    final weekTrips = _weeklyData.fold(0, (s, d) => s + d.ordersCount);
    return [
      DayEarnings(
        dayName: 'W1',
        amount: 0.0,
        ordersCount: 0,
        hoursWorked: 0.0,
        tipsAmount: 0.0,
        dateLabel: 'Week 1',
      ),
      DayEarnings(
        dayName: 'W2',
        amount: 0.0,
        ordersCount: 0,
        hoursWorked: 0.0,
        tipsAmount: 0.0,
        dateLabel: 'Week 2',
      ),
      DayEarnings(
        dayName: 'W3',
        amount: 0.0,
        ordersCount: 0,
        hoursWorked: 0.0,
        tipsAmount: 0.0,
        dateLabel: 'Week 3',
      ),
      DayEarnings(
        dayName: 'W4',
        amount: weekSum,
        ordersCount: weekTrips,
        hoursWorked: 0.0,
        tipsAmount: 0.0,
        dateLabel: 'Current 7 Days',
        isCurrent: true,
      ),
    ];
  }

  @visibleForTesting
  void setTestChartData({
    List<DayEarnings>? weekly,
    List<DayEarnings>? monthly,
  }) {
    if (weekly != null) _weeklyData = List.of(weekly);
    _testMonthlyData = monthly != null ? List.of(monthly) : null;
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest({
    double codBalance = 0.0,
    double earningsBalance = 0.0,
    double availableForPayout = 0.0,
    List<Map<String, dynamic>>? openCollections,
    List<Map<String, dynamic>>? recentRemittances,
  }) {
    _transactions.clear();
    _weeklyData = [];
    _testMonthlyData = null;
    _codHeldBalance = codBalance;
    _codAvailableForRemittance = codBalance;
    _codPendingVerificationAmount = 0.0;
    _earningsBalance = earningsBalance;
    _availableForPayout = availableForPayout;
    _pendingPayoutAmount = 0.0;
    _totalPaidOut = 0.0;
    _openCodCollections = openCollections ?? [];
    _recentRemittances = recentRemittances ?? [];
    _recentPayouts = [];
    _lastError = null;
    notifyListeners();
  }

  void recordDeliveryEarnings({
    required String orderId,
    required double deliveryFee,
    required double tip,
  }) {
    final total = deliveryFee + tip;
    if (total <= 0) return;
    final txn = EarningTransaction(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Trip Pay - $orderId',
      subtitle: 'Credited upon server verification',
      amount: total,
      timestamp: DateTime.now(),
      type: TransactionType.deliveryFee,
      relatedOrderId: orderId,
    );
    _transactions.insert(0, txn);
    notifyListeners();
  }

  void _applyCodWalletPayload(Map<String, dynamic>? wallet) {
    if (wallet == null) return;
    _codHeldBalance =
        (wallet['cod_on_hand_balance'] as num?)?.toDouble() ?? _codHeldBalance;
    _codPendingVerificationAmount =
        (wallet['pending_verification_amount'] as num?)?.toDouble() ?? 0.0;
    _codAvailableForRemittance =
        (wallet['available_for_new_remittance'] as num?)?.toDouble() ??
            (_codHeldBalance - _codPendingVerificationAmount).clamp(0.0, double.infinity);
    _codTotalCollectedLifetime =
        (wallet['total_collected_lifetime'] as num?)?.toDouble() ?? 0.0;
    _codTotalVerifiedRemitted =
        (wallet['total_verified_remitted'] as num?)?.toDouble() ?? 0.0;
    _codTotalShortageFlagged =
        (wallet['total_shortage_flagged'] as num?)?.toDouble() ?? 0.0;

    final openList = wallet['open_collections'] as List<dynamic>?;
    if (openList != null) {
      _openCodCollections =
          openList.whereType<Map<String, dynamic>>().toList();
    }
  }

  Future<Map<String, dynamic>?> fetchEarningsRemote() async {
    if (!ApiClient.instance.isAuthenticated) return null;
    _isLoading = true;
    _lastError = null;
    try {
      final res = await ApiClient.instance.get(ApiConstants.riderEarnings);
      final data = res.data as Map<String, dynamic>;

      _earningsBalance =
          (data['earnings_balance'] as num?)?.toDouble() ?? 0.0;
      _availableForPayout =
          (data['available_for_payout'] as num?)?.toDouble() ?? _earningsBalance;
      _pendingPayoutAmount =
          (data['pending_payout_amount'] as num?)?.toDouble() ?? 0.0;
      _totalPaidOut = (data['total_paid_out'] as num?)?.toDouble() ?? 0.0;
      _onHoldAmount = (data['on_hold_amount'] as num?)?.toDouble() ?? 0.0;
      _totalEarnedAllTime =
          (data['total_earned_all_time'] as num?)?.toDouble() ?? 0.0;
      _weeklyTotalPay =
          (data['weekly_total_pay'] as num?)?.toDouble() ?? 0.0;

      final unremitted = (data['unremitted_cod_balance'] as num?)?.toDouble();
      if (unremitted != null) {
        _codHeldBalance = unremitted;
      }

      if (data['cod_wallet'] is Map<String, dynamic>) {
        _applyCodWalletPayload(data['cod_wallet'] as Map<String, dynamic>);
      }
      if (data['active_policy'] is Map<String, dynamic>) {
        _activePolicy = data['active_policy'] as Map<String, dynamic>;
      }

      final payoutsList = data['recent_payouts'] as List<dynamic>?;
      if (payoutsList != null) {
        _recentPayouts = payoutsList.whereType<Map<String, dynamic>>().toList();
      }

      final todaySummary = data['today_summary'] as Map<String, dynamic>?;
      final todayPay = (todaySummary?['total_pay'] as num?)?.toDouble() ?? 0.0;
      final todayPickups = (todaySummary?['pickups'] as num?)?.toInt() ?? 0;
      final todayDeliveries = (todaySummary?['deliveries'] as num?)?.toInt() ?? 0;
      final todayFailed = (todaySummary?['failed_deliveries'] as num?)?.toInt() ?? 0;
      final todayTrips = todayPickups + todayDeliveries + todayFailed;

      _todayPay = todayPay;
      _todayPickupsCount = todayPickups;
      _todayDeliveriesCount = todayDeliveries;
      _todayPickupPay = (todaySummary?['pickup_pay'] as num?)?.toDouble() ?? 0.0;
      _todayDeliveryPay = (todaySummary?['delivery_pay'] as num?)?.toDouble() ?? 0.0;
      _todayFailedDeliveryPay =
          (todaySummary?['failed_delivery_pay'] as num?)?.toDouble() ?? 0.0;
      _hasFetchedRemote = true;

      RiderService.instance.updateProfileFromApi(
        id: RiderService.instance.profile.id,
        name: RiderService.instance.profile.name,
        email: RiderService.instance.profile.email,
        phone: RiderService.instance.profile.phone,
        plateNumber: RiderService.instance.profile.plateNumber,
        vehicleType: RiderService.instance.profile.vehicleType,
        isOnline: RiderService.instance.profile.isOnline,
        rating: RiderService.instance.profile.rating,
        walletBalance: _availableForPayout,
        todayDeliveries: todayTrips,
        todayEarnings: todayPay,
      );

      final past7Days = data['past_7_days'] as List<dynamic>?;
      if (past7Days != null && past7Days.isNotEmpty) {
        final parsed = <DayEarnings>[];
        for (int i = 0; i < past7Days.length; i++) {
          final item = past7Days[i] as Map<String, dynamic>;
          parsed.add(DayEarnings(
            dayName: item['day']?.toString() ?? 'Day',
            amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
            ordersCount: (item['trips'] as num?)?.toInt() ?? 0,
            hoursWorked: 0.0,
            tipsAmount: 0.0,
            dateLabel: item['date']?.toString() ?? '',
            isCurrent: i == past7Days.length - 1,
          ));
        }
        _weeklyData = parsed;
      }

      final recentEarnings = data['recent_earnings'] as List<dynamic>?;
      if (recentEarnings != null) {
        _transactions.clear();
        for (final item in recentEarnings) {
          if (item is Map<String, dynamic>) {
            final typeStr = (item['type'] ?? '').toString();
            final orderNum = item['order_number']?.toString() ?? '';
            final desc = (item['description'] ?? '').toString();
            final status = (item['status'] ?? 'available').toString();

            _transactions.add(EarningTransaction(
              id: 'TXN-${item['id']}',
              title: desc.isNotEmpty
                  ? desc
                  : (typeStr == 'pickup'
                      ? 'Pickup Pay'
                      : (typeStr == 'failed_delivery'
                          ? 'Failed Attempt Pay'
                          : 'Delivery Pay')),
              subtitle: orderNum.isNotEmpty
                  ? 'Order #$orderNum • ${status.toUpperCase()}'
                  : status.toUpperCase(),
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
              timestamp: DateTime.tryParse(item['earned_at']?.toString() ?? '') ??
                  DateTime.now(),
              type: typeStr == 'bonus'
                  ? TransactionType.bonus
                  : TransactionType.deliveryFee,
              relatedOrderId: orderNum.isNotEmpty ? orderNum : null,
            ));
          }
        }
      }

      notifyListeners();
      return data;
    } on ApiException catch (e) {
      _lastError = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _lastError = 'Unable to load earnings summary.';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  Future<Map<String, dynamic>?> fetchCodCollectionsRemote() async {
    if (!ApiClient.instance.isAuthenticated) return null;
    try {
      final res =
          await ApiClient.instance.get(ApiConstants.riderCodCollections);
      final data = res.data as Map<String, dynamic>;
      _applyCodWalletPayload(data);
      final remits = data['recent_remittances'] as List<dynamic>?;
      if (remits != null) {
        _recentRemittances = remits.whereType<Map<String, dynamic>>().toList();
      }
      notifyListeners();
      return data;
    } on ApiException catch (e) {
      _lastError = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchPayoutsRemote() async {
    if (!ApiClient.instance.isAuthenticated) return null;
    try {
      final res = await ApiClient.instance.get(ApiConstants.riderPayouts);
      final data = res.data as Map<String, dynamic>;
      _availableForPayout =
          (data['available_for_payout'] as num?)?.toDouble() ?? _availableForPayout;
      _pendingPayoutAmount =
          (data['pending_payout_amount'] as num?)?.toDouble() ?? _pendingPayoutAmount;
      _totalPaidOut =
          (data['total_paid_out'] as num?)?.toDouble() ?? _totalPaidOut;
      final payouts = data['payouts'] as List<dynamic>?;
      if (payouts != null) {
        _recentPayouts = payouts.whereType<Map<String, dynamic>>().toList();
      }
      notifyListeners();
      return data;
    } on ApiException catch (e) {
      _lastError = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submit a genuine Rider-to-Logistics COD remittance.
  /// Never clears held COD cash locally — waits for Logistics verification.
  Future<Map<String, dynamic>?> submitRemittanceRemote({
    required double amount,
    String paymentMethod = 'physical_cash',
    String? externalReference,
    DateTime? transferDate,
    List<int>? orderIds,
    String? proofFilePath,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw ApiException(
        message: 'Remittance amount must be greater than ₱0.00.',
        statusCode: 422,
      );
    }

    if (paymentMethod != 'physical_cash') {
      if (externalReference == null || externalReference.trim().isEmpty) {
        throw ApiException(
          message:
              'External reference number is required for $paymentMethod transfers.',
          statusCode: 422,
        );
      }
      if (proofFilePath == null || proofFilePath.trim().isEmpty) {
        throw ApiException(
          message: 'Please attach a transaction receipt image for manual verification.',
          statusCode: 422,
        );
      }
    }

    if (!ApiClient.instance.isAuthenticated) {
      throw ApiException(
        message: 'Sign in required to submit a COD remittance.',
        statusCode: 401,
      );
    }

    final idempotencyKey =
        'remit_${DateTime.now().millisecondsSinceEpoch}_${amount.toStringAsFixed(2)}';
    final headers = {'Idempotency-Key': idempotencyKey};

    ApiResponse<dynamic> res;
    if (proofFilePath != null &&
        proofFilePath.trim().isNotEmpty &&
        File(proofFilePath).existsSync()) {
      final fields = <String, String>{
        'amount': amount.toStringAsFixed(2),
        'payment_method': paymentMethod,
        if (externalReference != null && externalReference.trim().isNotEmpty)
          'external_reference': externalReference.trim(),
        if (transferDate != null)
          'transfer_date': transferDate.toIso8601String(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      if (orderIds != null && orderIds.isNotEmpty) {
        for (int i = 0; i < orderIds.length; i++) {
          fields['order_ids[$i]'] = orderIds[i].toString();
        }
      }
      final file = await http.MultipartFile.fromPath('proof_file', proofFilePath);
      res = await ApiClient.instance.multipartPost(
        ApiConstants.remittance,
        fields: fields,
        files: {'proof_file': file},
        headers: headers,
      );
    } else {
      res = await ApiClient.instance.post(
        ApiConstants.remittance,
        body: {
          'amount': amount,
          'payment_method': paymentMethod,
          if (externalReference != null && externalReference.trim().isNotEmpty)
            'external_reference': externalReference.trim(),
          if (transferDate != null)
            'transfer_date': transferDate.toIso8601String(),
          if (orderIds != null && orderIds.isNotEmpty) 'order_ids': orderIds,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
        headers: headers,
      );
    }

    final payload = res.data as Map<String, dynamic>?;
    if (payload != null) {
      _recentRemittances.insert(0, payload);
      // Reflect pending verification honestly — DO NOT mark cash cleared yet!
      _codPendingVerificationAmount += amount;
      _codAvailableForRemittance = (_codHeldBalance - _codPendingVerificationAmount)
          .clamp(0.0, double.infinity);
    }

    await Future.wait([
      fetchEarningsRemote(),
      fetchCodCollectionsRemote(),
    ]);
    notifyListeners();
    return payload;
  }

  /// Submit a genuine Courier Payout Request. Status stays 'requested' until
  /// Logistics Finance manually processes and verifies the payout reference.
  Future<Map<String, dynamic>?> requestPayoutRemote({
    required double amount,
    required String payoutMethod,
    required String accountName,
    required String accountNumber,
    String? courierNotes,
  }) async {
    if (amount <= 0) {
      throw ApiException(
        message: 'Payout amount must be greater than zero.',
        statusCode: 422,
      );
    }
    if (accountName.trim().isEmpty || accountNumber.trim().isEmpty) {
      throw ApiException(
        message: 'Account holder name and account/mobile number are required.',
        statusCode: 422,
      );
    }
    if (!ApiClient.instance.isAuthenticated) {
      throw ApiException(
        message: 'Sign in required to submit a payout request.',
        statusCode: 401,
      );
    }

    final res = await ApiClient.instance.post(
      ApiConstants.riderPayouts,
      body: {
        'amount': amount,
        'payout_method': payoutMethod,
        'account_name': accountName.trim(),
        'account_number': accountNumber.trim(),
        if (courierNotes != null && courierNotes.trim().isNotEmpty)
          'courier_notes': courierNotes.trim(),
      },
    );

    final created = res.data as Map<String, dynamic>?;
    if (created != null) {
      _recentPayouts.insert(0, created);
      _pendingPayoutAmount += amount;
      _availableForPayout =
          (_availableForPayout - amount).clamp(0.0, double.infinity);
    }

    await Future.wait([
      fetchEarningsRemote(),
      fetchPayoutsRemote(),
    ]);
    notifyListeners();
    return created;
  }

  void clear() {
    _transactions.clear();
    _weeklyData = [];
    _testMonthlyData = null;
    _earningsBalance = 0.0;
    _availableForPayout = 0.0;
    _pendingPayoutAmount = 0.0;
    _totalPaidOut = 0.0;
    _onHoldAmount = 0.0;
    _totalEarnedAllTime = 0.0;
    _weeklyTotalPay = 0.0;
    _codHeldBalance = 0.0;
    _codPendingVerificationAmount = 0.0;
    _codAvailableForRemittance = 0.0;
    _codTotalCollectedLifetime = 0.0;
    _codTotalVerifiedRemitted = 0.0;
    _codTotalShortageFlagged = 0.0;
    _openCodCollections = [];
    _recentRemittances = [];
    _recentPayouts = [];
    _activePolicy = null;
    _lastError = null;
    notifyListeners();
  }
}
