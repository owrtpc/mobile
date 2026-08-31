enum ProfileState { allowed, manuallyBlocked, bedtime, timeUsed, disabled }

class ProfileSummary {
  const ProfileSummary({
    required this.section,
    required this.name,
    required this.state,
    required this.usedSeconds,
    required this.allowanceSeconds,
    required this.deviceCount,
    required this.enabled,
    required this.manualBlocked,
    required this.bonusSeconds,
    required this.allDay,
  });

  final String section;
  final String name;
  final ProfileState state;
  final int usedSeconds;
  final int allowanceSeconds;
  final int deviceCount;
  final bool enabled;
  final bool manualBlocked;
  final int bonusSeconds;
  final bool allDay;

  double? get progress => allowanceSeconds == 0
      ? null
      : (usedSeconds / allowanceSeconds).clamp(0, 1);

  int? get remainingSeconds => allowanceSeconds == 0
      ? null
      : (allowanceSeconds - usedSeconds).clamp(0, allowanceSeconds);

  bool get canAddTime =>
      enabled &&
      !manualBlocked &&
      state != ProfileState.bedtime &&
      (allowanceSeconds != 0 || allDay);
}
