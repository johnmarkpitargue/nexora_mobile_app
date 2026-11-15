class HubSummary {
  final int id;
  final String name;
  final String code;
  final String? cityName;
  final String? provinceName;

  const HubSummary({
    required this.id,
    required this.name,
    required this.code,
    this.cityName,
    this.provinceName,
  });

  factory HubSummary.fromJson(Map<String, dynamic> json) {
    return HubSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Unknown Hub',
      code: json['code']?.toString() ?? '',
      cityName: json['city_name']?.toString(),
      provinceName: json['province_name']?.toString(),
    );
  }
}

class TransferManifestItemModel {
  final int id;
  final int manifestId;
  final String? manifestNumber;
  final int orderId;
  final String trackingNumber;
  final String? originHubName;
  final String? destinationHubName;
  final String loadingStatus;
  final String? loadedAt;
  final String receivingStatus;
  final String? receivedAt;
  final String? issueNotes;

  const TransferManifestItemModel({
    required this.id,
    required this.manifestId,
    this.manifestNumber,
    required this.orderId,
    required this.trackingNumber,
    this.originHubName,
    this.destinationHubName,
    required this.loadingStatus,
    this.loadedAt,
    required this.receivingStatus,
    this.receivedAt,
    this.issueNotes,
  });

  bool get isLoaded => loadingStatus == 'loaded';
  bool get hasIssue =>
      loadingStatus == 'issue' ||
      receivingStatus == 'missing' ||
      receivingStatus == 'damaged' ||
      receivingStatus == 'discrepancy';

  factory TransferManifestItemModel.fromJson(Map<String, dynamic> json) {
    return TransferManifestItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      manifestId: (json['manifest_id'] as num?)?.toInt() ?? 0,
      manifestNumber: json['manifest_number']?.toString(),
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      trackingNumber: json['tracking_number']?.toString() ?? '',
      originHubName: json['origin_hub_name']?.toString(),
      destinationHubName: json['destination_hub_name']?.toString(),
      loadingStatus: json['loading_status']?.toString() ?? 'pending',
      loadedAt: json['loaded_at']?.toString(),
      receivingStatus: json['receiving_status']?.toString() ?? 'pending',
      receivedAt: json['received_at']?.toString(),
      issueNotes: json['issue_notes']?.toString(),
    );
  }
}

class TransferManifestModel {
  final int id;
  final String manifestNumber;
  final String status;
  final String transferType;
  final HubSummary? originHub;
  final HubSummary? destinationHub;
  final int totalParcels;
  final int loadedParcels;
  final String loadingProgress;
  final bool allLoaded;
  final String? vehiclePlateNumber;
  final String? dispatchedAt;
  final String? arrivedAt;
  final String? completedAt;
  final String? notes;
  final List<TransferManifestItemModel> items;

  const TransferManifestModel({
    required this.id,
    required this.manifestNumber,
    required this.status,
    required this.transferType,
    this.originHub,
    this.destinationHub,
    required this.totalParcels,
    required this.loadedParcels,
    required this.loadingProgress,
    required this.allLoaded,
    this.vehiclePlateNumber,
    this.dispatchedAt,
    this.arrivedAt,
    this.completedAt,
    this.notes,
    this.items = const [],
  });

  bool get canScanLoading =>
      status == 'draft' || status == 'loading' || status == 'ready_to_dispatch';
  bool get canConfirmDeparture =>
      (status == 'loading' || status == 'ready_to_dispatch') && allLoaded;
  bool get canMarkArrived =>
      (status == 'in_transit' || status == 'exception') && arrivedAt == null;
  bool get canReportIssue =>
      status == 'loading' ||
      status == 'ready_to_dispatch' ||
      status == 'in_transit' ||
      (status == 'exception' && arrivedAt == null);

  factory TransferManifestModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return TransferManifestModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      manifestNumber: json['manifest_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      transferType: json['transfer_type']?.toString() ?? 'internal',
      originHub: json['origin_hub'] is Map<String, dynamic>
          ? HubSummary.fromJson(json['origin_hub'] as Map<String, dynamic>)
          : null,
      destinationHub: json['destination_hub'] is Map<String, dynamic>
          ? HubSummary.fromJson(json['destination_hub'] as Map<String, dynamic>)
          : null,
      totalParcels: (json['total_parcels'] as num?)?.toInt() ?? 0,
      loadedParcels: (json['loaded_parcels'] as num?)?.toInt() ?? 0,
      loadingProgress: json['loading_progress']?.toString() ?? '',
      allLoaded: json['all_loaded'] == true,
      vehiclePlateNumber: json['vehicle_plate_number']?.toString(),
      dispatchedAt: json['dispatched_at']?.toString(),
      arrivedAt: json['arrived_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      notes: json['notes']?.toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(TransferManifestItemModel.fromJson)
          .toList(),
    );
  }
}

class TransferCourierDashboardModel {
  final String courierName;
  final String companyName;
  final HubSummary? assignedHub;
  final TransferManifestModel? activeManifest;
  final int totalAssignedParcels;
  final int totalLoadedParcels;
  final int completedTransfers;
  final int reportedExceptions;

  const TransferCourierDashboardModel({
    required this.courierName,
    required this.companyName,
    this.assignedHub,
    this.activeManifest,
    required this.totalAssignedParcels,
    required this.totalLoadedParcels,
    required this.completedTransfers,
    required this.reportedExceptions,
  });

  factory TransferCourierDashboardModel.fromJson(Map<String, dynamic> json) {
    final courier = json['courier'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return TransferCourierDashboardModel(
      courierName: courier['full_name']?.toString() ??
          courier['name']?.toString() ??
          'Transfer Courier',
      companyName: json['company_name']?.toString() ?? 'Logistics Partner',
      assignedHub: json['assigned_hub'] is Map<String, dynamic>
          ? HubSummary.fromJson(json['assigned_hub'] as Map<String, dynamic>)
          : null,
      activeManifest: json['active_manifest'] is Map<String, dynamic>
          ? TransferManifestModel.fromJson(
              json['active_manifest'] as Map<String, dynamic>)
          : null,
      totalAssignedParcels:
          (stats['total_assigned_parcels'] as num?)?.toInt() ?? 0,
      totalLoadedParcels:
          (stats['total_loaded_parcels'] as num?)?.toInt() ?? 0,
      completedTransfers:
          (stats['completed_transfers'] as num?)?.toInt() ?? 0,
      reportedExceptions:
          (stats['reported_exceptions'] as num?)?.toInt() ?? 0,
    );
  }
}
