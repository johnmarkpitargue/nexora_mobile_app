import '../constants/api_constants.dart';
import '../network/api_client.dart';

class SafetyReportItem {
  final int id;
  final String referenceNumber;
  final String category;
  final String categoryLabel;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? resolutionSummary;
  final String? createdAt;

  const SafetyReportItem({
    required this.id,
    required this.referenceNumber,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.resolutionSummary,
    this.createdAt,
  });

  factory SafetyReportItem.fromJson(Map<String, dynamic> json) {
    return SafetyReportItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      referenceNumber: (json['reference_number'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      categoryLabel: (json['category_label'] ?? json['category'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'new').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      resolutionSummary: json['resolution_summary']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class SafetyReportService {
  static final SafetyReportService instance = SafetyReportService._();
  SafetyReportService._();

  Future<SafetyReportItem> submitReport({
    required String category,
    required String title,
    required String description,
    String? subjectType,
    int? subjectId,
    int? reportedUserId,
    int? orderId,
    int? productId,
  }) async {
    final res = await ApiClient.instance.post(
      ApiConstants.safetyReports,
      body: {
        'category': category,
        'title': title,
        'description': description,
        if (subjectType != null) 'subject_type': subjectType,
        if (subjectId != null) 'subject_id': subjectId,
        if (reportedUserId != null) 'reported_user_id': reportedUserId,
        if (orderId != null) 'order_id': orderId,
        if (productId != null) 'product_id': productId,
      },
    );
    return SafetyReportItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SafetyReportItem>> fetchMyReports() async {
    final res = await ApiClient.instance.get(ApiConstants.safetyReports);
    final list = res.data as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(SafetyReportItem.fromJson)
        .toList();
  }
}
