/// Dashboard workspace mode derived from the user's latest ITR payment state.
enum DashboardMode {
  /// No filings yet — welcome / start filing experience.
  none,

  /// Newest ITR has not completed payment — show pending payment only.
  prePayment,

  /// Focus ITR has successful payment — show live tracking and expert flow.
  postPayment,
}

/// Type of expert-requested action for Critical Actions UI and navigation.
enum DashboardActionType {
  documentRequired,
  informationRequired,
  clarificationRequired,
  general,
}

/// A pending expert or system action shown on the dashboard.
class DashboardActionItem {
  final int? id;
  final DashboardActionType type;
  final String title;
  final String message;
  final String requestedBy;
  final String? createdAt;

  const DashboardActionItem({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.requestedBy,
    this.createdAt,
  });

  factory DashboardActionItem.fromStatusUpdate({
    required int? id,
    required String? message,
    required String? status,
    required String? createdAt,
    required String expertName,
  }) {
    final text = (message ?? '').trim();
    return DashboardActionItem(
      id: id,
      type: inferActionType(text, status),
      title: actionTypeLabel(inferActionType(text, status)),
      message: text.isEmpty ? 'Please review this request from your tax expert.' : text,
      requestedBy: expertName,
      createdAt: createdAt,
    );
  }

  factory DashboardActionItem.fromStepConcern({
    required String stepTitle,
    required String? concernText,
    required String expertName,
  }) {
    final text = (concernText ?? stepTitle).trim();
    return DashboardActionItem(
      type: inferActionType(text, null),
      title: actionTypeLabel(inferActionType(text, null)),
      message: text.isEmpty ? 'Action required on $stepTitle.' : text,
      requestedBy: expertName,
    );
  }

  static DashboardActionType inferActionType(String message, String? status) {
    final combined = '${message.toLowerCase()} ${(status ?? '').toLowerCase()}';

    if (combined.contains('upload') ||
        combined.contains('document') ||
        combined.contains('form 16') ||
        combined.contains('form16') ||
        combined.contains('statement') ||
        combined.contains('slip')) {
      return DashboardActionType.documentRequired;
    }

    if (combined.contains('pan') ||
        combined.contains('address') ||
        combined.contains('aadhaar') ||
        combined.contains('aadhar') ||
        combined.contains('personal') ||
        combined.contains('information') ||
        combined.contains('mobile') ||
        combined.contains('email')) {
      return DashboardActionType.informationRequired;
    }

    if (combined.contains('clarif') ||
        combined.contains('confirm') ||
        combined.contains('mismatch') ||
        combined.contains('verify')) {
      return DashboardActionType.clarificationRequired;
    }

    return DashboardActionType.general;
  }

  static String actionTypeLabel(DashboardActionType type) {
    switch (type) {
      case DashboardActionType.documentRequired:
        return 'Document Required';
      case DashboardActionType.informationRequired:
        return 'Information Required';
      case DashboardActionType.clarificationRequired:
        return 'Clarification Required';
      case DashboardActionType.general:
        return 'Action Required';
    }
  }
}
