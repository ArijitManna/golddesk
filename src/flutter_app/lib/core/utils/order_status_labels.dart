/// Role-aware UI labels for B2B order workflow. API status values stay unchanged.
String displayOrderStatus({
  required String businessType,
  required String status,
  String acceptanceStatus = 'Accepted',
  String? assignmentStatus,
}) {
  if (status == 'Cancelled') return 'Cancelled';
  if (status == 'Delivered' || status == 'Closed') return 'Done';

  if (businessType == 'Karigar') {
    if (assignmentStatus == 'PendingAcceptance') return 'New Work';
    return switch (status) {
      'Assigned' => 'Work Accepted',
      'InProgress' => 'Making',
      'Ready' => 'Work Ready',
      _ => formatOrderStatus(status),
    };
  }

  if (businessType == 'Showroom') {
    if (acceptanceStatus == 'Pending') return 'New';
    return switch (status) {
      'Pending' => 'Accepted',
      'Assigned' => 'With Shop',
      'InProgress' => 'Making',
      'Ready' => 'Work Ready',
      _ => formatOrderStatus(status),
    };
  }

  // Shop (default)
  if (acceptanceStatus == 'Pending') return 'New';
  return switch (status) {
    'Pending' => 'To Give Work',
    'Assigned' when assignmentStatus == 'PendingAcceptance' => 'Work Given',
    'Assigned' => 'Work Accepted',
    'InProgress' => 'Making',
    'Ready' => 'Work Ready',
    _ => formatOrderStatus(status),
  };
}

String displayAssignmentStatus({
  required String status,
  required bool isActive,
}) {
  if (!isActive) return status;
  return switch (status) {
    'PendingAcceptance' => 'Work Given',
    'Active' => 'Work Accepted',
    _ => status,
  };
}

String displayAcceptanceStatus(String status) => switch (status) {
  'Pending' => 'Awaiting Shop acceptance',
  'Accepted' => 'Accepted',
  'Rejected' => 'Rejected',
  _ => status,
};

/// Fallback / generic labels when role context is unavailable.
String formatOrderStatus(String status) {
  switch (status) {
    case 'Assigned':
    case 'assigned':
      return 'Send to Karigar';
    case 'InProgress':
    case 'inprogress':
      return 'In Progress';
    default:
      return status;
  }
}
