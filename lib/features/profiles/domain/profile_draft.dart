import 'profile_details.dart';

enum ProfileDraftIssue {
  emptyName,
  nameTooLong,
  invalidAllowance,
  incompleteSunThuBedtime,
  incompleteFriSatBedtime,
  invalidActivityThreshold,
  invalidDevice,
  duplicateDevice,
}

class ProfileDraft {
  ProfileDraft({
    required this.section,
    required this.name,
    required this.enabled,
    required List<String> devices,
    required this.monThuDailyMinutes,
    required this.friSunDailyMinutes,
    required this.sunThuBedtime,
    required this.friSatBedtime,
    required this.activityThresholdBytes,
  }) : devices = List.unmodifiable(devices.map(canonicalMac));

  factory ProfileDraft.fromDetails(ProfileDetails details) => ProfileDraft(
    section: details.summary.section,
    name: details.summary.name,
    enabled: details.summary.enabled,
    devices: details.devices.map((device) => device.mac).toList(),
    monThuDailyMinutes: details.monThuDailyMinutes,
    friSunDailyMinutes: details.friSunDailyMinutes,
    sunThuBedtime: details.sunThuBedtime,
    friSatBedtime: details.friSatBedtime,
    activityThresholdBytes: details.activityThresholdBytes,
  );

  final String section;
  final String name;
  final bool enabled;
  final List<String> devices;
  final int monThuDailyMinutes;
  final int friSunDailyMinutes;
  final BedtimeWindow sunThuBedtime;
  final BedtimeWindow friSatBedtime;
  final int? activityThresholdBytes;

  Set<ProfileDraftIssue> get issues {
    final result = <ProfileDraftIssue>{};
    if (name.trim().isEmpty) result.add(ProfileDraftIssue.emptyName);
    if (name.trim().length > 80) result.add(ProfileDraftIssue.nameTooLong);
    if (monThuDailyMinutes < 0 ||
        monThuDailyMinutes > 2147483647 ||
        friSunDailyMinutes < 0 ||
        friSunDailyMinutes > 2147483647) {
      result.add(ProfileDraftIssue.invalidAllowance);
    }
    if (!_isCompleteTimeWindow(sunThuBedtime)) {
      result.add(ProfileDraftIssue.incompleteSunThuBedtime);
    }
    if (!_isCompleteTimeWindow(friSatBedtime)) {
      result.add(ProfileDraftIssue.incompleteFriSatBedtime);
    }
    final threshold = activityThresholdBytes;
    if (threshold != null && (threshold <= 0 || threshold > 2147483647)) {
      result.add(ProfileDraftIssue.invalidActivityThreshold);
    }
    final uniqueDevices = <String>{};
    for (final device in devices) {
      if (!_macPattern.hasMatch(device)) {
        result.add(ProfileDraftIssue.invalidDevice);
      } else if (!uniqueDevices.add(device)) {
        result.add(ProfileDraftIssue.duplicateDevice);
      }
    }
    return result;
  }

  bool get isValid => issues.isEmpty;

  ProfileDraft copyWith({
    String? name,
    bool? enabled,
    List<String>? devices,
    int? monThuDailyMinutes,
    int? friSunDailyMinutes,
    BedtimeWindow? sunThuBedtime,
    BedtimeWindow? friSatBedtime,
    int? activityThresholdBytes,
    bool clearActivityThreshold = false,
  }) => ProfileDraft(
    section: section,
    name: name ?? this.name,
    enabled: enabled ?? this.enabled,
    devices: devices ?? this.devices,
    monThuDailyMinutes: monThuDailyMinutes ?? this.monThuDailyMinutes,
    friSunDailyMinutes: friSunDailyMinutes ?? this.friSunDailyMinutes,
    sunThuBedtime: sunThuBedtime ?? this.sunThuBedtime,
    friSatBedtime: friSatBedtime ?? this.friSatBedtime,
    activityThresholdBytes: clearActivityThreshold
        ? null
        : activityThresholdBytes ?? this.activityThresholdBytes,
  );

  bool hasSameValues(ProfileDraft other) =>
      section == other.section &&
      name == other.name &&
      enabled == other.enabled &&
      _sameList(devices, other.devices) &&
      monThuDailyMinutes == other.monThuDailyMinutes &&
      friSunDailyMinutes == other.friSunDailyMinutes &&
      sunThuBedtime.start == other.sunThuBedtime.start &&
      sunThuBedtime.end == other.sunThuBedtime.end &&
      friSatBedtime.start == other.friSatBedtime.start &&
      friSatBedtime.end == other.friSatBedtime.end &&
      activityThresholdBytes == other.activityThresholdBytes;

  static String canonicalMac(String value) => value.trim().toUpperCase();

  static bool _isCompleteTimeWindow(BedtimeWindow window) {
    if (window.start == null && window.end == null) return true;
    return _timePattern.hasMatch(window.start ?? '') &&
        _timePattern.hasMatch(window.end ?? '');
  }

  static bool _sameList(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  static final _macPattern = RegExp(r'^[0-9A-F]{2}(?::[0-9A-F]{2}){5}$');
  static final _timePattern = RegExp(r'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$');
}
