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
  });

  final String section;
  final String name;
  final ProfileState state;
  final int usedSeconds;
  final int allowanceSeconds;
  final int deviceCount;
  final bool enabled;

  double? get progress => allowanceSeconds == 0
      ? null
      : (usedSeconds / allowanceSeconds).clamp(0, 1);

  int? get remainingSeconds => allowanceSeconds == 0
      ? null
      : (allowanceSeconds - usedSeconds).clamp(0, allowanceSeconds);
}
