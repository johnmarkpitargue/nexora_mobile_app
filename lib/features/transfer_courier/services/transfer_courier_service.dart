import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/transfer_manifest_models.dart';

class TransferCourierService extends ChangeNotifier {
  static final TransferCourierService instance =
      TransferCourierService._internal();
  TransferCourierService._internal();

  bool _isLoading = false;
  bool _sessionExpired = false;
  String? _errorMessage;
  String _lastFilter = 'active';
  TransferCourierDashboardModel? _dashboard;
  List<TransferManifestModel> _manifests = [];
  List<TransferManifestItemModel> _inventory = [];
  Map<String, dynamic>? _profileData;

  // Transfer Courier Compensation & Payouts (strictly separated from Rider COD)
  double _earningsBalance = 0.0;
  double _availableForPayout = 0.0;
  double _pendingPayoutAmount = 0.0;
  double _totalPaidOut = 0.0;
  double _todayTotalPay = 0.0;
  int _todayTrips = 0;
  double _weeklyTotalPay = 0.0;
  List<Map<String, dynamic>> _recentEarnings = [];
  List<Map<String, dynamic>> _recentPayouts = [];
  Map<String, dynamic>? _activePolicy;

  bool get isLoading => _isLoading;
  bool get sessionExpired => _sessionExpired;
  String? get errorMessage => _errorMessage;
  TransferCourierDashboardModel? get dashboard => _dashboard;
  List<TransferManifestModel> get manifests => _manifests;
  List<TransferManifestItemModel> get inventory => _inventory;
  Map<String, dynamic>? get profileData => _profileData;

  double get earningsBalance => _earningsBalance;
  double get availableForPayout => _availableForPayout;
  double get pendingPayoutAmount => _pendingPayoutAmount;
  double get totalPaidOut => _totalPaidOut;
  double get todayTotalPay => _todayTotalPay;
  int get todayTrips => _todayTrips;
  double get weeklyTotalPay => _weeklyTotalPay;
  List<Map<String, dynamic>> get recentEarnings =>
      List.unmodifiable(_recentEarnings);
  List<Map<String, dynamic>> get recentPayouts =>
      List.unmodifiable(_recentPayouts);
  Map<String, dynamic>? get activePolicy => _activePolicy;

  String _formatApiError(ApiException e, String fallback) {
    if (e.statusCode == 401) {
      _sessionExpired = true;
      return 'Your session has expired. Please sign in again.';
    }
    if (e.statusCode == 403) {
      return e.message.isNotEmpty
          ? e.message
          : 'You are not authorized to perform this action.';
    }
    if (e.statusCode == 404) {
      return e.message.isNotEmpty ? e.message : 'Requested record was not found.';
    }
    if (e.statusCode == 409 || e.statusCode == 422) {
      return e.message.isNotEmpty ? e.message : fallback;
    }
    return e.message.isNotEmpty ? e.message : fallback;
  }

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res =
          await ApiClient.instance.get(ApiConstants.transferCourierDashboard);
      if (res.data is Map<String, dynamic>) {
        _dashboard = TransferCourierDashboardModel.fromJson(
            res.data as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      _errorMessage = _formatApiError(e, 'Failed to load transfer courier dashboard.');
    } catch (_) {
      _errorMessage = 'Failed to load transfer courier dashboard.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchManifests({String filter = 'all'}) async {
    _lastFilter = filter;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.get(
        ApiConstants.transferCourierManifests,
        queryParams: filter != 'all' ? {'status': filter} : null,
      );
      final list = res.data as List<dynamic>? ?? [];
      _manifests = list
          .whereType<Map<String, dynamic>>()
          .map(TransferManifestModel.fromJson)
          .toList();
    } on ApiException catch (e) {
      _errorMessage = _formatApiError(e, 'Failed to load assigned transfer manifests.');
    } catch (_) {
      _errorMessage = 'Failed to load assigned transfer manifests.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransferManifestModel> fetchManifestDetail(int manifestId) async {
    final res = await ApiClient.instance
        .get(ApiConstants.transferCourierManifestDetail(manifestId));
    return TransferManifestModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> fetchInventory({String query = ''}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.get(
        ApiConstants.transferCourierInventory,
        queryParams: query.trim().isNotEmpty ? {'q': query.trim()} : null,
      );
      final list = res.data as List<dynamic>? ?? [];
      _inventory = list
          .whereType<Map<String, dynamic>>()
          .map(TransferManifestItemModel.fromJson)
          .toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load parcel inventory.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> scanParcel(
      int manifestId, String trackingNumber) async {
    final res = await ApiClient.instance.post(
      ApiConstants.transferCourierManifestScan(manifestId),
      body: {'tracking_number': trackingNumber.trim()},
    );
    await Future.wait([
      fetchDashboard(),
      fetchManifests(filter: _lastFilter),
    ]);
    return {
      'message': res.message,
      'data': res.data,
    };
  }

  Future<TransferManifestModel> confirmDeparture(
      int manifestId, {String? vehiclePlateNumber}) async {
    final res = await ApiClient.instance.post(
      ApiConstants.transferCourierManifestDepart(manifestId),
      body: {
        if (vehiclePlateNumber != null && vehiclePlateNumber.trim().isNotEmpty)
          'vehicle_plate_number': vehiclePlateNumber.trim(),
      },
    );
    await Future.wait([
      fetchDashboard(),
      fetchManifests(filter: _lastFilter),
    ]);
    return TransferManifestModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TransferManifestModel> markArrived(int manifestId) async {
    final res = await ApiClient.instance.post(
      ApiConstants.transferCourierManifestArrive(manifestId),
    );
    await Future.wait([
      fetchDashboard(),
      fetchManifests(filter: _lastFilter),
    ]);
    return TransferManifestModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> reportIssue(
    int manifestId, {
    required String trackingNumber,
    required String issueType,
    required String notes,
  }) async {
    await ApiClient.instance.post(
      ApiConstants.transferCourierManifestReportIssue(manifestId),
      body: {
        'tracking_number': trackingNumber.trim(),
        'issue_type': issueType,
        'notes': notes.trim(),
      },
    );
    await Future.wait([
      fetchDashboard(),
      fetchManifests(filter: _lastFilter),
    ]);
  }

  Future<void> fetchProfile() async {
    try {
      final res =
          await ApiClient.instance.get(ApiConstants.transferCourierProfile);
      if (res.data is Map<String, dynamic>) {
        _profileData = res.data as Map<String, dynamic>;
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _sessionExpired = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> fetchEarnings() async {
    if (!ApiClient.instance.isAuthenticated) return null;
    try {
      final res =
          await ApiClient.instance.get(ApiConstants.transferCourierEarnings);
      final data = res.data as Map<String, dynamic>?;
      if (data == null) return null;

      _earningsBalance =
          (data['earnings_balance'] as num?)?.toDouble() ?? 0.0;
      _availableForPayout =
          (data['available_for_payout'] as num?)?.toDouble() ?? _earningsBalance;
      _pendingPayoutAmount =
          (data['pending_payout_amount'] as num?)?.toDouble() ?? 0.0;
      _totalPaidOut = (data['total_paid_out'] as num?)?.toDouble() ?? 0.0;
      _weeklyTotalPay =
          (data['weekly_total_pay'] as num?)?.toDouble() ?? 0.0;

      final today = data['today_summary'] as Map<String, dynamic>?;
      _todayTotalPay = (today?['total_pay'] as num?)?.toDouble() ?? 0.0;
      _todayTrips = (today?['transfer_trips'] as num?)?.toInt() ?? 0;

      if (data['active_policy'] is Map<String, dynamic>) {
        _activePolicy = data['active_policy'] as Map<String, dynamic>;
      }
      final earnings = data['recent_earnings'] as List<dynamic>?;
      if (earnings != null) {
        _recentEarnings = earnings.whereType<Map<String, dynamic>>().toList();
      }
      final payouts = data['recent_payouts'] as List<dynamic>?;
      if (payouts != null) {
        _recentPayouts = payouts.whereType<Map<String, dynamic>>().toList();
      }
      notifyListeners();
      return data;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _sessionExpired = true;
        notifyListeners();
      } else {
        _errorMessage = e.message;
        notifyListeners();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchPayouts() async {
    if (!ApiClient.instance.isAuthenticated) return null;
    try {
      final res =
          await ApiClient.instance.get(ApiConstants.transferCourierPayouts);
      final data = res.data as Map<String, dynamic>?;
      if (data == null) return null;

      _availableForPayout =
          (data['available_for_payout'] as num?)?.toDouble() ?? _availableForPayout;
      _pendingPayoutAmount =
          (data['pending_payout_amount'] as num?)?.toDouble() ?? _pendingPayoutAmount;
      _totalPaidOut = (data['total_paid_out'] as num?)?.toDouble() ?? _totalPaidOut;

      final payouts = data['payouts'] as List<dynamic>?;
      if (payouts != null) {
        _recentPayouts = payouts.whereType<Map<String, dynamic>>().toList();
      }
      notifyListeners();
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> requestPayout({
    required double amount,
    required String payoutMethod,
    required String accountName,
    required String accountNumber,
    String? courierNotes,
  }) async {
    final res = await ApiClient.instance.post(
      ApiConstants.transferCourierPayouts,
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
    await Future.wait([fetchEarnings(), fetchPayouts()]);
    notifyListeners();
    return created;
  }

  @visibleForTesting
  void setFinancialDataForTest({
    double earningsBalance = 0.0,
    double availableForPayout = 0.0,
    double pendingPayoutAmount = 0.0,
    double totalPaidOut = 0.0,
    double todayTotalPay = 0.0,
    int todayTrips = 0,
    List<Map<String, dynamic>>? recentEarnings,
    List<Map<String, dynamic>>? recentPayouts,
    Map<String, dynamic>? activePolicy,
  }) {
    _earningsBalance = earningsBalance;
    _availableForPayout = availableForPayout;
    _pendingPayoutAmount = pendingPayoutAmount;
    _totalPaidOut = totalPaidOut;
    _todayTotalPay = todayTotalPay;
    _todayTrips = todayTrips;
    if (recentEarnings != null) _recentEarnings = recentEarnings;
    if (recentPayouts != null) _recentPayouts = recentPayouts;
    if (activePolicy != null) _activePolicy = activePolicy;
    notifyListeners();
  }

  void clear() {
    _dashboard = null;
    _manifests = [];
    _inventory = [];
    _profileData = null;
    _earningsBalance = 0.0;
    _availableForPayout = 0.0;
    _pendingPayoutAmount = 0.0;
    _totalPaidOut = 0.0;
    _todayTotalPay = 0.0;
    _todayTrips = 0;
    _weeklyTotalPay = 0.0;
    _recentEarnings = [];
    _recentPayouts = [];
    _activePolicy = null;
    _errorMessage = null;
    _sessionExpired = false;
    notifyListeners();
  }
}
