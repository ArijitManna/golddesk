namespace GoldDesk.Domain.Enums;

public enum NotificationType
{
    AssignmentCreated = 0,
    DueSoon3Days = 1,
    DueSoon2Days = 2,
    DueSoon1Day = 3,
    DueToday = 4,
    Overdue = 5,
    StatusChangedToReady = 6,
    OrderReassigned = 7,
    CommentAdded = 8,
    ConnectionRequested = 9,
    ConnectionAccepted = 10,
    OrderAccepted = 11,
    OrderRejected = 12,
    WorkAccepted = 13,
    WorkStarted = 14,
    OrderDelivered = 15,
    RegistrationRequested = 16
}
