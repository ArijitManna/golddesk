/// UI display labels for order statuses. API values stay unchanged.
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
