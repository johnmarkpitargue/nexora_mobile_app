import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../models/earning_record.dart';
import 'rider_service.dart';

class EarningsService extends ChangeNotifier {
  static final EarningsService instance = EarningsService._();
  EarningsService._() {
    _initSampleTransactions();
  }

  final List<EarningTransaction> _transactions = [];

  List<EarningTransaction> get transactions => List.unmodifiable(_transactions);

  List<DayEarnings> _weeklyData = [];
  List<DayEarnings> get weeklyData =>
      _weeklyData.isNotEmpty ? List.unmodifiable(_weeklyData) : _fallbackWeeklyData;

  static const List<DayEarnings> _fallbackWeeklyData = [
    DayEarnings(
      dayName: 'Mon',
      amount: 1620.00,
      ordersCount: 6,
      hoursWorked: 4.2,
      tipsAmount: 70.0,
      dateLabel: 'Monday, Oct 12',
    ),
    DayEarnings(
      dayName: 'Tue',
      amount: 1410.00,
      ordersCount: 5,
      hoursWorked: 3.8,
      tipsAmount: 60.0,
      dateLabel: 'Tuesday, Oct 13',
    ),
    DayEarnings(
      dayName: 'Wed',
      amount: 1940.00,
      ordersCount: 8,
      hoursWorked: 5.0,
      tipsAmount: 90.0,
      dateLabel: 'Wednesday, Oct 14',
    ),
    DayEarnings(
      dayName: 'Thu',
      amount: 1510.00,
      ordersCount: 6,
      hoursWorked: 4.0,
      tipsAmount: 65.0,
      dateLabel: 'Thursday, Oct 15',
    ),
    DayEarnings(
      dayName: 'Fri',
      amount: 2150.00,
      ordersCount: 8,
      hoursWorked: 5.2,
      tipsAmount: 110.0,
      dateLabel: 'Friday, Oct 16',
    ),
    DayEarnings(
      dayName: 'Sat',
      amount: 2520.00,
      ordersCount: 10,
      hoursWorked: 5.8,
      tipsAmount: 105.0,
      dateLabel: 'Saturday, Oct 17',
    ),
    DayEarnings(
      dayName: 'Sun',
      amount: 1420.00,
      ordersCount: 5,
      hoursWorked: 4.5,
      tipsAmount: 60.0,
      dateLabel: 'Sunday, Oct 18 (Today)',
      isCurrent: true,
    ),
  ];

  final List<DayEarnings> todayData = const [
    DayEarnings(
      dayName: '08:00',
      amount: 320.00,
      ordersCount: 2,
      hoursWorked: 1.5,
      tipsAmount: 20.0,
      dateLabel: 'Morning Rush (08:00–11:00)',
    ),
    DayEarnings(
      dayName: '11:00',
      amount: 540.00,
      ordersCount: 3,
      hoursWorked: 1.8,
      tipsAmount: 40.0,
      dateLabel: 'Lunch Peak Rush (11:00–14:00)',
    ),
    DayEarnings(
      dayName: '14:00',
      amount: 280.00,
      ordersCount: 2,
      hoursWorked: 1.2,
      tipsAmount: 20.0,
      dateLabel: 'Afternoon Route (14:00–17:00)',
    ),
    DayEarnings(
      dayName: '17:00',
      amount: 280.00,
      ordersCount: 2,
      hoursWorked: 1.0,
      tipsAmount: 40.0,
      dateLabel: 'Dinner Surge (17:00–21:00)',
      isCurrent: true,
    ),
  ];

  final List<DayEarnings> monthlyData = const [
    DayEarnings(
      dayName: 'W1',
      amount: 11400.00,
      ordersCount: 46,
      hoursWorked: 31.0,
      tipsAmount: 520.0,
      dateLabel: 'Week 1 (Oct 01 - Oct 07)',
    ),
    DayEarnings(
      dayName: 'W2',
      amount: 12200.00,
      ordersCount: 48,
      hoursWorked: 32.5,
      tipsAmount: 560.0,
      dateLabel: 'Week 2 (Oct 08 - Oct 14)',
    ),
    DayEarnings(
      dayName: 'W3',
      amount: 12570.00,
      ordersCount: 48,
      hoursWorked: 32.5,
      tipsAmount: 560.0,
      dateLabel: 'Week 3 (Oct 15 - Oct 21)',
      isCurrent: true,
    ),
    DayEarnings(
      dayName: 'W4',
      amount: 9800.00,
      ordersCount: 38,
      hoursWorked: 26.0,
      tipsAmount: 440.0,
      dateLabel: 'Week 4 (Oct 22 - Oct 28)',
    ),
  ];

  void _initSampleTransactions() {
    final now = DateTime.now();
    _transactions.addAll([
      EarningTransaction(
        id: 'TXN-1085',
        title: 'Weekend Milestone Quest',
        subtitle: 'Completed 18 Peak-Hour Trips • #Q-402',
        amount: 400.00,
        timestamp: DateTime(now.year, now.month, now.day, 16, 45),
        type: TransactionType.bonus,
      ),
      EarningTransaction(
        id: 'TXN-1084',
        title: 'Trip Payout - NX-9104-ORD',
        subtitle: 'Delivery (₱145.00) + Tip (₱50.00)',
        amount: 195.00,
        timestamp: DateTime(now.year, now.month, now.day, 15, 19),
        type: TransactionType.deliveryFee,
        relatedOrderId: 'NX-9104-ORD',
      ),
      EarningTransaction(
        id: 'TXN-1082',
        title: 'Trip Payout - NX-8720-ORD',
        subtitle: 'Standard Express + Tip (₱30.00)',
        amount: 160.00,
        timestamp: DateTime(now.year, now.month, now.day, 13, 19),
        type: TransactionType.deliveryFee,
        relatedOrderId: 'NX-8720-ORD',
      ),
      EarningTransaction(
        id: 'TXN-1081',
        title: 'Trip Payout - NX-8641-ORD',
        subtitle: 'Standard Express + Tip (₱20.00)',
        amount: 170.00,
        timestamp: DateTime(now.year, now.month, now.day, 11, 19),
        type: TransactionType.deliveryFee,
        relatedOrderId: 'NX-8641-ORD',
      ),
      EarningTransaction(
        id: 'TXN-1075',
        title: 'Instant Cash-out to GCash',
        subtitle: 'Ref: GCASH-0918***0192',
        amount: -2500.00,
        timestamp: now.subtract(const Duration(days: 1)),
        type: TransactionType.cashOut,
      ),
    ]);
  }

  void recordDeliveryEarnings({
    required String orderId,
    required double deliveryFee,
    required double tip,
  }) {
    final total = deliveryFee + tip;
    final txn = EarningTransaction(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: 'Trip Payout - $orderId',
      subtitle: tip > 0
          ? 'Delivery (₱${deliveryFee.toStringAsFixed(2)}) + Tip (₱${tip.toStringAsFixed(2)})'
          : 'Standard Delivery Payout',
      amount: total,
      timestamp: DateTime.now(),
      type: TransactionType.deliveryFee,
      relatedOrderId: orderId,
    );

    _transactions.insert(0, txn);
    notifyListeners();
  }

  bool requestCashOut(double amount, String method, String accountNo) {
    if (amount <= 0 || amount > RiderService.instance.profile.walletBalance) {
      return false;
    }

    RiderService.instance.deductCashOut(amount);

    final txn = EarningTransaction(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: 'Cash Out to $method',
      subtitle: 'Ref: $accountNo',
      amount: -amount,
      timestamp: DateTime.now(),
      type: TransactionType.cashOut,
    );

    _transactions.insert(0, txn);
    notifyListeners();
    return true;
  }

  double _codHeldBalance = 0.0;
  double get codHeldBalance => _codHeldBalance;

  void remitCodCash({
    required double amount,
    required String method,
    String? referenceNumber,
    String? hubOfficer,
  }) {
    if (amount <= 0) return;
    _codHeldBalance = (_codHeldBalance - amount).clamp(0.0, double.infinity);

    final isEwallet = method.contains('GCash') || method.contains('Maya');
    final txn = EarningTransaction(
      id: 'REMIT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      title: 'COD Cash Remitted ($method)',
      subtitle: isEwallet
          ? 'Ref: ${referenceNumber ?? "NEX-EWALLET-OK"} • Instant Clear'
          : 'Hub Counter Voucher • Approved by ${hubOfficer ?? "Elena V. (Hub 4B)"}',
      amount: -amount,
      timestamp: DateTime.now(),
      type: TransactionType.cashOut,
    );
    _transactions.insert(0, txn);
    notifyListeners();
  }

  void resetCodBalanceForTest([double balance = 640.00]) {
    _codHeldBalance = balance;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchEarningsRemote() async {
    if (!ApiClient.instance.isAuthenticated) return null;
    try {
      final res = await ApiClient.instance.get(ApiConstants.riderEarnings);
      final data = res.data as Map<String, dynamic>;
      final unremitted = (data['unremitted_cod_balance'] as num?)?.toDouble();
      if (unremitted != null) {
        _codHeldBalance = unremitted;
      }

      final todaySummary = data['today_summary'] as Map<String, dynamic>?;
      final todayPay = (todaySummary?['total_pay'] as num?)?.toDouble() ?? 0.0;
      final todayTrips = ((todaySummary?['pickups'] as num?)?.toInt() ?? 0) +
          ((todaySummary?['deliveries'] as num?)?.toInt() ?? 0);

      final balance = (data['earnings_balance'] as num?)?.toDouble();
      if (balance != null) {
        RiderService.instance.updateProfileFromApi(
          id: RiderService.instance.profile.id,
          name: RiderService.instance.profile.name,
          email: RiderService.instance.profile.email,
          phone: RiderService.instance.profile.phone,
          plateNumber: RiderService.instance.profile.plateNumber,
          vehicleType: RiderService.instance.profile.vehicleType,
          isOnline: RiderService.instance.profile.isOnline,
          rating: RiderService.instance.profile.rating,
          walletBalance: balance,
          todayDeliveries: todayTrips,
          todayEarnings: todayPay,
        );
      }

      // Parse 7-day performance breakdown for weekly performance chart
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

      // Parse real transaction history from server
      final recentEarnings = data['recent_earnings'] as List<dynamic>?;
      if (recentEarnings != null) {
        _transactions.clear();
        for (final item in recentEarnings) {
          if (item is Map<String, dynamic>) {
            final typeStr = (item['type'] ?? '').toString();
            final isPickup = typeStr == 'pickup';
            final orderNum = item['order_number']?.toString() ?? '';
            final desc = (item['description'] ?? '').toString();

            _transactions.add(EarningTransaction(
              id: 'TXN-${item['id']}',
              title: desc.isNotEmpty ? desc : (isPickup ? 'Pickup Pay' : 'Delivery Pay'),
              subtitle: orderNum.isNotEmpty
                  ? 'Order #$orderNum'
                  : (isPickup ? 'Store Parcel Pickup' : 'Customer Delivery'),
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
              timestamp: DateTime.tryParse(item['earned_at']?.toString() ?? '') ?? DateTime.now(),
              type: TransactionType.deliveryFee,
              relatedOrderId: orderNum.isNotEmpty ? orderNum : null,
            ));
          }
        }
      }

      notifyListeners();
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<bool> submitRemittanceRemote({
    required double amount,
    String? notes,
  }) async {
    if (amount <= 0) return false;

    if (ApiClient.instance.isAuthenticated) {
      final idempotencyKey = 'remit_${DateTime.now().millisecondsSinceEpoch}';
      final res = await ApiClient.instance.post(
        ApiConstants.remittance,
        body: {
          'amount': amount,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        headers: {'Idempotency-Key': idempotencyKey},
      );
      remitCodCash(
        amount: amount,
        method: 'Mobile Remittance',
        referenceNumber: (res.data as Map<String, dynamic>?)?['remittance_number']?.toString(),
      );
      await fetchEarningsRemote();
      return true;
    }

    remitCodCash(amount: amount, method: 'Direct Hub');
    return true;
  }
}
