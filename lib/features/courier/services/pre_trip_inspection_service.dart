import 'package:flutter/foundation.dart';
import 'courier_service.dart';
import '../../../core/services/rider_service.dart';

class PreTripChecklistItem {
  final String id;
  final String title;
  final String description;
  final String iconName;

  const PreTripChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
  });
}

class PreTripInspectionService extends ChangeNotifier {
  static final PreTripInspectionService instance = PreTripInspectionService._();
  PreTripInspectionService._();

  static const List<PreTripChecklistItem> checklistItems = [
    PreTripChecklistItem(
      id: 'tires',
      title: 'Tires',
      description: 'Tire pressure, tread wear depth, and no punctures or cuts',
      iconName: 'tire',
    ),
    PreTripChecklistItem(
      id: 'lights',
      title: 'Lights',
      description: 'Headlights, brake lights, signal indicators, and hazard flashers',
      iconName: 'light',
    ),
    PreTripChecklistItem(
      id: 'brakes',
      title: 'Brakes',
      description: 'Front & rear brake responsiveness, lever firmness, and fluid levels',
      iconName: 'brake',
    ),
    PreTripChecklistItem(
      id: 'fuel',
      title: 'Fuel',
      description: 'Adequate fuel level for shift operations or battery charge level',
      iconName: 'fuel',
    ),
    PreTripChecklistItem(
      id: 'cargo_lock',
      title: 'Cargo door lock',
      description: 'Cargo box/compartment latch integrity, weather seal, and security lock',
      iconName: 'lock',
    ),
  ];

  final Map<String, bool?> _answers = {};
  final Map<String, String> _notes = {};

  DateTime? _lastPassedTime;
  String? _lastFlaggedItem;
  String? _lastFlaggedNote;

  Map<String, bool?> get answers => Map.unmodifiable(_answers);
  Map<String, String> get notes => Map.unmodifiable(_notes);
  DateTime? get lastPassedTime => _lastPassedTime;
  String? get lastFlaggedItem => _lastFlaggedItem;
  String? get lastFlaggedNote => _lastFlaggedNote;

  bool? getAnswer(String id) => _answers[id];
  String getNote(String id) => _notes[id] ?? '';

  void setAnswer(String id, bool? value) {
    _answers[id] = value;
    notifyListeners();
  }

  void setNote(String id, String note) {
    _notes[id] = note;
    notifyListeners();
  }

  void reset() {
    _answers.clear();
    _notes.clear();
    notifyListeners();
  }

  /// Validates and submits the pre-trip checklist according to COU-SHIFT-001, COU-SHIFT-002, and COU-SHIFT-003
  PreTripSubmissionResult submitChecklist({
    required String riderId,
    required String location,
  }) {
    // 1. COU-SHIFT-003: Check if all 5 items are answered
    for (final item in checklistItems) {
      if (_answers[item.id] == null) {
        return PreTripSubmissionResult(
          success: false,
          errorMessage: 'Checklist incomplete: Please answer every inspection item before proceeding. (${item.title} is unanswered)',
          stayOffDuty: true,
        );
      }
    }

    // 2. COU-SHIFT-002: Check if any item is marked Not OK
    for (final item in checklistItems) {
      if (_answers[item.id] == false) {
        final note = (_notes[item.id] ?? '').trim();
        // Step 1: A note is required
        if (note.isEmpty) {
          return PreTripSubmissionResult(
            success: false,
            errorMessage: 'A note is required explaining why ${item.title} is Not OK.',
            stayOffDuty: true,
          );
        }

        // Step 2: Courier stays Off Duty and cannot be assigned; Logistics 1 is notified
        _lastFlaggedItem = item.title;
        _lastFlaggedNote = note;

        CourierService.instance.recordPreTripInspectionFailed(
          riderId: riderId,
          flaggedItem: item.title,
          note: note,
        );

        notifyListeners();

        return PreTripSubmissionResult(
          success: false,
          isSafetyGrounded: true,
          flaggedItem: item.title,
          flaggedNote: note,
          errorMessage: 'Vehicle Inspection Failed: ${item.title} marked Not OK ($note). Courier stays Off Duty. Logistics dispatch has been notified.',
          stayOffDuty: true,
        );
      }
    }

    // 3. COU-SHIFT-001: All 5 items OK
    final now = DateTime.now();
    _lastPassedTime = now;
    _lastFlaggedItem = null;
    _lastFlaggedNote = null;

    // Transition courier to On Duty
    RiderService.instance.setOnlineStatus(true);

    // Notify Logistics 1 with location and checklist time
    CourierService.instance.recordPreTripInspectionPassed(
      riderId: riderId,
      location: location,
      timestamp: now,
    );

    notifyListeners();

    return PreTripSubmissionResult(
      success: true,
      stayOffDuty: false,
      timestamp: now,
      location: location,
    );
  }
}

class PreTripSubmissionResult {
  final bool success;
  final bool stayOffDuty;
  final bool isSafetyGrounded;
  final String? flaggedItem;
  final String? flaggedNote;
  final String? errorMessage;
  final DateTime? timestamp;
  final String? location;

  const PreTripSubmissionResult({
    required this.success,
    this.stayOffDuty = false,
    this.isSafetyGrounded = false,
    this.flaggedItem,
    this.flaggedNote,
    this.errorMessage,
    this.timestamp,
    this.location,
  });
}
