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
    OrderReassigned = 7
}
