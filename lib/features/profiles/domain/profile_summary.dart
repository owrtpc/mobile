enum ProfileState { allowed, manuallyBlocked, bedtime, timeUsed, disabled }

class ProfileSummary {
  const ProfileSummary({
    required this.nameKey,
    required this.state,
    required this.usedMinutes,
    required this.allowanceMinutes,
    required this.deviceCount,
    required this.enabled,
  });

  final String nameKey;
  final ProfileState state;
  final int usedMinutes;
  final int allowanceMinutes;
  final int deviceCount;
  final bool enabled;

  double? get progress => allowanceMinutes == 0
      ? null
      : (usedMinutes / allowanceMinutes).clamp(0, 1);

  int? get remainingMinutes => allowanceMinutes == 0
      ? null
      : (allowanceMinutes - usedMinutes).clamp(0, allowanceMinutes);
}
