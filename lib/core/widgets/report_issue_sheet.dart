import 'package:flutter/material.dart';
import '../services/safety_report_service.dart';

Future<void> showSafetyReportSheet(
  BuildContext context, {
  required String defaultCategory,
  required String defaultTitle,
  String? subjectType,
  int? subjectId,
  int? reportedUserId,
  int? orderId,
  int? productId,
}) async {
  final categories = <String, String>{
    'fraud_scam': 'Fraud or suspected scam',
    'fake_misleading_product': 'Fake or misleading products',
    'counterfeit_product': 'Counterfeit products',
    'harassment_abuse': 'Harassment or abusive messages',
    'seller_misconduct': 'Seller misconduct',
    'fake_reviews': 'Fake reviews',
    'other_violation': 'Other policy violations',
  };

  String selectedCategory = categories.containsKey(defaultCategory)
      ? defaultCategory
      : categories.keys.first;
  final titleController = TextEditingController(text: defaultTitle);
  final descController = TextEditingController();
  bool submitting = false;
  String? errorText;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Report to Safety Center',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => selectedCategory = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue (min 10 chars)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (descController.text.trim().length < 10) {
                          setModalState(() => errorText = 'Please provide at least 10 characters.');
                          return;
                        }
                        setModalState(() {
                          submitting = true;
                          errorText = null;
                        });
                        try {
                          final item = await SafetyReportService.instance.submitReport(
                            category: selectedCategory,
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            subjectType: subjectType,
                            subjectId: subjectId,
                            reportedUserId: reportedUserId,
                            orderId: orderId,
                            productId: productId,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Report ${item.referenceNumber} submitted.')),
                          );
                        } catch (e) {
                          setModalState(() {
                            submitting = false;
                            errorText = e.toString();
                          });
                        }
                      },
                child: Text(submitting ? 'Submitting...' : 'Submit Report'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class MySafetyReportsScreen extends StatefulWidget {
  const MySafetyReportsScreen({super.key});

  @override
  State<MySafetyReportsScreen> createState() => _MySafetyReportsScreenState();
}

class _MySafetyReportsScreenState extends State<MySafetyReportsScreen> {
  late Future<List<SafetyReportItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = SafetyReportService.instance.fetchMyReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Safety Reports')),
      body: FutureBuilder<List<SafetyReportItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load reports: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No safety reports submitted yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = items[i];
              return Card(
                child: ListTile(
                  title: Text('${r.referenceNumber} • ${r.title}'),
                  subtitle: Text('${r.categoryLabel}\nStatus: ${r.status.toUpperCase()}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
