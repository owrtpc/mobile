import 'profile_summary.dart';

class ProfileDetails {
  const ProfileDetails({
    required this.summary,
    required this.devices,
    required this.monThuDailyMinutes,
    required this.friSunDailyMinutes,
    required this.sunThuBedtime,
    required this.friSatBedtime,
    required this.activityThresholdBytes,
  });

  final ProfileSummary summary;
  final List<ProfileDeviceDetails> devices;
  final int monThuDailyMinutes;
  final int friSunDailyMinutes;
  final BedtimeWindow sunThuBedtime;
  final BedtimeWindow friSatBedtime;
  final int? activityThresholdBytes;
}

class ProfileDeviceDetails {
  const ProfileDeviceDetails({
    required this.mac,
    required this.name,
    required this.addresses,
    required this.usedSeconds,
  });

  final String mac;
  final String? name;
  final List<String> addresses;
  final int? usedSeconds;
}

class BedtimeWindow {
  const BedtimeWindow({required this.start, required this.end});

  final String? start;
  final String? end;

  bool get isEnabled => start != null && end != null;
}
