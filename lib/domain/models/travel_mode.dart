class TravelMode {
  const TravelMode({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.folderPath,
    required this.createdAt,
    this.notificationEndingSoonHours = 24,
  });

  final String id;
  final String name;
  final int startDate;
  final int endDate;
  final int? startTime;
  final int? endTime;
  final String folderPath;
  final int createdAt;
  final int notificationEndingSoonHours;

  bool isActive([int? currentTime]) {
    final now = currentTime ?? DateTime.now().millisecondsSinceEpoch;
    return now >= getStartDateTime() && now <= getEndDateTime();
  }

  int getStartDateTime() {
    if (startTime != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(startDate);
      final hours = startTime! ~/ (60 * 60 * 1000);
      final minutes = (startTime! % (60 * 60 * 1000)) ~/ (60 * 1000);
      return DateTime(
        date.year,
        date.month,
        date.day,
        hours,
        minutes,
      ).millisecondsSinceEpoch;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(startDate);
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  }

  int getEndDateTime() {
    if (endTime != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(endDate);
      final hours = endTime! ~/ (60 * 60 * 1000);
      final minutes = (endTime! % (60 * 60 * 1000)) ~/ (60 * 1000);
      return DateTime(
        date.year,
        date.month,
        date.day,
        hours,
        minutes,
        59,
        999,
      ).millisecondsSinceEpoch;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(endDate);
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
  }

  bool isMediaInTravelPeriod(int? mediaDateTaken, int mediaDateAdded) {
    final mediaDate = mediaDateTaken ?? mediaDateAdded;
    return mediaDate >= getStartDateTime() && mediaDate <= getEndDateTime();
  }

  TravelMode copyWith({
    String? name,
    int? startDate,
    int? endDate,
    int? startTime,
    int? endTime,
    String? folderPath,
    int? notificationEndingSoonHours,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) {
    return TravelMode(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      folderPath: folderPath ?? this.folderPath,
      createdAt: createdAt,
      notificationEndingSoonHours:
          notificationEndingSoonHours ?? this.notificationEndingSoonHours,
    );
  }
}

enum TravelModeStatus { active, upcoming, completed }

TravelModeStatus travelModeStatus(TravelMode mode, [int? nowMs]) {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  if (now < mode.getStartDateTime()) return TravelModeStatus.upcoming;
  if (now <= mode.getEndDateTime()) return TravelModeStatus.active;
  return TravelModeStatus.completed;
}
