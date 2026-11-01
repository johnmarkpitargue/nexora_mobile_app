import 'package:flutter/material.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/services/rider_service.dart';
import '../services/pre_trip_inspection_service.dart';

class PreTripInspectionSheet extends StatefulWidget {
  final String location;
  final VoidCallback onPassed;
  final void Function(String flaggedItem, String note) onFailed;

  const PreTripInspectionSheet({
    super.key,
    this.location = 'HUB-QC',
    required this.onPassed,
    required this.onFailed,
  });

  static Future<bool?> show(
    BuildContext context, {
    String location = 'HUB-QC',
    VoidCallback? onPassed,
    void Function(String flaggedItem, String note)? onFailed,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PreTripInspectionSheet(
        location: location,
        onPassed: () {
          onPassed?.call();
          Navigator.pop(ctx, true);
        },
        onFailed: (item, note) {
          onFailed?.call(item, note);
          Navigator.pop(ctx, false);
        },
      ),
    );
  }

  @override
  State<PreTripInspectionSheet> createState() => _PreTripInspectionSheetState();
}

class _PreTripInspectionSheetState extends State<PreTripInspectionSheet> {
  final PreTripInspectionService _service = PreTripInspectionService.instance;
  final Map<String, TextEditingController> _noteControllers = {};
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _service.reset();
    for (final item in PreTripInspectionService.checklistItems) {
      _noteControllers[item.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _noteControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  IconData _getItemIcon(String iconName) {
    switch (iconName) {
      case 'tire':
        return Icons.radio_button_checked_rounded;
      case 'light':
        return Icons.highlight_rounded;
      case 'brake':
        return Icons.disc_full_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'lock':
        return Icons.lock_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  void _submit() {
    final profile = RiderService.instance.profile;
    for (final item in PreTripInspectionService.checklistItems) {
      final text = _noteControllers[item.id]?.text.trim() ?? '';
      _service.setNote(item.id, text);
    }

    final result = _service.submitChecklist(
      riderId: profile.id,
      location: widget.location,
    );

    if (!result.success) {
      setState(() {
        _validationError = result.errorMessage;
      });

      if (result.isSafetyGrounded) {
        widget.onFailed(
          result.flaggedItem ?? 'Vehicle Inspection',
          result.flaggedNote ?? '',
        );
      }
      return;
    }

    setState(() {
      _validationError = null;
    });
    widget.onPassed();
  }

  @override
  Widget build(BuildContext context) {
    final profile = RiderService.instance.profile;
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: EdgeInsets.only(bottom: keyboardBottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF00D2FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pre-Trip Vehicle Inspection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.location,
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${profile.vehicleModel} • ${profile.plateNumber}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF1E293B)),

          // Error validation message banner if any
          if (_validationError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: const TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Scrollable Checklist items
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: PreTripInspectionService.checklistItems.map((item) {
                  final answer = _service.getAnswer(item.id);
                  final isNotOk = answer == false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: answer == true
                            ? RiderTheme.onlineGreen.withValues(alpha: 0.5)
                            : (answer == false
                                ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                : const Color(0xFF334155)),
                        width: answer != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: answer == true
                                    ? RiderTheme.onlineGreen.withValues(alpha: 0.15)
                                    : (answer == false
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                        : Colors.white.withValues(alpha: 0.05)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getItemIcon(item.iconName),
                                size: 18,
                                color: answer == true
                                    ? RiderTheme.onlineGreen
                                    : (answer == false ? const Color(0xFFEF4444) : Colors.white70),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Segmented choice chips (OK / Not OK)
                            Row(
                              children: [
                                _buildChoiceButton(
                                  label: 'OK',
                                  isSelected: answer == true,
                                  activeColor: RiderTheme.onlineGreen,
                                  onTap: () {
                                    setState(() {
                                      _service.setAnswer(item.id, true);
                                      _validationError = null;
                                    });
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildChoiceButton(
                                  label: 'Not OK',
                                  isSelected: answer == false,
                                  activeColor: const Color(0xFFEF4444),
                                  onTap: () {
                                    setState(() {
                                      _service.setAnswer(item.id, false);
                                      _validationError = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Required Note input when Not OK is selected
                        if (isNotOk) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFF59E0B)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Incident Note (Required for Not OK):',
                                      style: TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                TextField(
                                  controller: _noteControllers[item.id],
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  onChanged: (_) {
                                    if (_validationError != null) {
                                      setState(() => _validationError = null);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'e.g. ${item.title == 'Brakes' ? 'Brake pedal feels soft, needs checking' : 'Describe the inspection issue...'}',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(
                top: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submit,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Submit Checklist & Go On Duty',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
