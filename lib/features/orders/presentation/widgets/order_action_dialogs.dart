import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/order_service.dart';

class OrderReturnEvidenceFile {
  final Uint8List bytes;
  final String name;

  const OrderReturnEvidenceFile({
    required this.bytes,
    required this.name,
  });
}

class OrderActionDialogs {
  OrderActionDialogs._();

  static const List<String> cancelReasons = [
    'Changed mind / No longer needed',
    'Need to change shipping address',
    'Found cheaper alternative',
    'Duplicate order placed',
    'Other',
  ];

  static const List<String> returnReasons = [
    'Item damaged or defective upon arrival',
    'Wrong item received',
    'Item not as described / Missing parts',
    'Counterfeit or unauthentic item',
  ];

  /// Opens the web-aligned pre-shipping cancellation reason modal,
  /// sends `POST /buyer/orders/{serverId}/cancel` FIRST, and only updates UI
  /// on a confirmed 2xx server response. Returns updated order or null.
  static Future<OrderItemModel?> showCancelOrderDialog(
    BuildContext context,
    OrderItemModel order,
  ) async {
    String selectedReason = cancelReasons.first;
    final customController = TextEditingController();
    String? errorMessage;
    bool isSubmitting = false;

    final result = await showDialog<OrderItemModel?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> submit() async {
              final reason = selectedReason == 'Other'
                  ? (customController.text.trim().isNotEmpty
                      ? customController.text.trim()
                      : 'Other')
                  : selectedReason;

              if (reason.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Please select or enter a cancellation reason.';
                });
                return;
              }

              setDialogState(() {
                isSubmitting = true;
                errorMessage = null;
              });

              try {
                final updated = await OrderService.instance.cancelOrderRemote(
                  order.serverId,
                  reason: reason,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx, updated);
                }
              } on ApiException catch (e) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = e.message;
                  });
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = 'Unable to cancel order right now.';
                  });
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Cancel Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.orderId} will be cancelled and inventory will be restored immediately.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Reason for cancellation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: cancelReasons
                          .map(
                            (r) => DropdownMenuItem<String>(
                              value: r,
                              child: Text(r, style: const TextStyle(fontSize: 12.5)),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                setDialogState(() => selectedReason = val);
                              }
                            },
                    ),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customController,
                        enabled: !isSubmitting,
                        maxLength: 255,
                        decoration: InputDecoration(
                          hintText: 'Specify reason...',
                          hintStyle: const TextStyle(fontSize: 12.5),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx, null),
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm Cancellation'),
                ),
              ],
            );
          },
        );
      },
    );

    customController.dispose();

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${result.orderId} cancelled.'),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    }
    return result;
  }

  /// Opens confirmation dialog and calls `POST /buyer/orders/{serverId}/confirm-receipt`
  /// FIRST. Shows exact server error if refused.
  static Future<OrderItemModel?> showConfirmReceiptDialog(
    BuildContext context,
    OrderItemModel order,
  ) async {
    String? errorMessage;
    bool isSubmitting = false;

    final result = await showDialog<OrderItemModel?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> submit() async {
              setDialogState(() {
                isSubmitting = true;
                errorMessage = null;
              });

              try {
                final updated =
                    await OrderService.instance.confirmReceiptRemote(
                  order.serverId,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx, updated);
                }
              } on ApiException catch (e) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = e.message;
                  });
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = 'Unable to confirm receipt right now.';
                  });
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Confirm Order Received?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Have you received all items in good condition? Confirming will mark the order Completed.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx, null),
                  child: const Text(
                    'Not Yet',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Yes, Received'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order confirmed as received!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
    return result;
  }

  /// Opens the 7-day Return / Refund modal (`reason`, `details` min 10 chars,
  /// `1..5` evidence media files -> `POST /buyer/orders/{serverId}/return`).
  static Future<OrderItemModel?> showReturnRequestDialog(
    BuildContext context,
    OrderItemModel order,
  ) async {
    String selectedReason = returnReasons.first;
    final detailsController = TextEditingController();
    final evidenceFiles = <OrderReturnEvidenceFile>[];
    String? errorMessage;
    bool isSubmitting = false;

    final result = await showDialog<OrderItemModel?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickMedia() async {
              if (evidenceFiles.length >= 5) return;
              try {
                final picker = ImagePicker();
                final picked = await picker.pickMultiImage(
                  limit: 5 - evidenceFiles.length,
                  maxWidth: 1400,
                  maxHeight: 1400,
                  imageQuality: 85,
                );
                if (picked.isEmpty) return;
                for (final f in picked.take(5 - evidenceFiles.length)) {
                  final bytes = await f.readAsBytes();
                  evidenceFiles.add(
                    OrderReturnEvidenceFile(
                      bytes: bytes,
                      name: f.name,
                    ),
                  );
                }
                if (dialogCtx.mounted) {
                  setDialogState(() => errorMessage = null);
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    errorMessage = 'Could not select media: $e';
                  });
                }
              }
            }

            Future<void> submit() async {
              final details = detailsController.text.trim();
              if (details.length < 10) {
                setDialogState(() {
                  errorMessage =
                      'Please provide at least 10 characters describing the issue.';
                });
                return;
              }
              if (evidenceFiles.isEmpty) {
                setDialogState(() {
                  errorMessage =
                      'Please attach at least 1 photo as return evidence.';
                });
                return;
              }

              setDialogState(() {
                isSubmitting = true;
                errorMessage = null;
              });

              try {
                final multipartFiles = evidenceFiles
                    .map(
                      (f) => http.MultipartFile.fromBytes(
                        'media[]',
                        f.bytes,
                        filename: f.name,
                      ),
                    )
                    .toList();

                final updated = await OrderService.instance.submitReturnRemote(
                  order.serverId,
                  reason: selectedReason,
                  details: details,
                  mediaFiles: multipartFiles,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx, updated);
                }
              } on ApiException catch (e) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = e.message;
                  });
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = 'Unable to submit return request right now.';
                  });
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'File Return / Refund Request',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permitted within 7 days of delivery. Requires 1–5 proof photos or videos.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Return Reason',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: returnReasons
                          .map(
                            (r) => DropdownMenuItem<String>(
                              value: r,
                              child: Text(r, style: const TextStyle(fontSize: 12)),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (v) {
                              if (v != null) {
                                setDialogState(() => selectedReason = v);
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Description & Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: detailsController,
                      enabled: !isSubmitting,
                      maxLines: 3,
                      maxLength: 1500,
                      decoration: InputDecoration(
                        hintText:
                            'Describe the issue in detail (min 10 characters)...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Evidence (${evidenceFiles.length}/5)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              isSubmitting || evidenceFiles.length >= 5
                                  ? null
                                  : pickMedia,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                          label: const Text('Add Proof', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    if (evidenceFiles.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(evidenceFiles.length, (i) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  evidenceFiles[i].bytes,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: InkWell(
                                  onTap: isSubmitting
                                      ? null
                                      : () => setDialogState(
                                          () => evidenceFiles.removeAt(i),
                                        ),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.black87,
                                    child: Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Return Request'),
                ),
              ],
            );
          },
        );
      },
    );

    detailsController.dispose();

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return / refund request submitted!'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    }
    return result;
  }
}

