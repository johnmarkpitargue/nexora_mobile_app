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

  bool get isLoading => _isLoading;
  bool get sessionExpired => _sessionExpired;
  String? get errorMessage => _errorMessage;
  TransferCourierDashboardModel? get dashboard => _dashboard;
  List<TransferManifestModel> get manifests => _manifests;
  List<TransferManifestItemModel> get inventory => _inventory;
  Map<String, dynamic>? get profileData => _profileData;

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

  void clear() {
    _dashboard = null;
    _manifests = [];
    _inventory = [];
    _profileData = null;
    _errorMessage = null;
    _sessionExpired = false;
    notifyListeners();
  }
}
