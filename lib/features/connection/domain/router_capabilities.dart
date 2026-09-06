class RouterCapabilities {
  const RouterCapabilities({
    required this.api,
    required this.major,
    required this.minor,
    required this.backendVersion,
    required this.features,
    required this.routerDate,
    required this.routerTimezone,
  });

  static const supportedApi = 'owrtpc-mobile';
  static const supportedMajor = 1;

  final String api;
  final int major;
  final int minor;
  final String backendVersion;
  final Set<String> features;
  final String routerDate;
  final String routerTimezone;

  bool get isCompatible => api == supportedApi && major == supportedMajor;
  bool get supportsSchedulePeriods => features.contains('schedule-periods');
  bool get supportsProfileEditTransaction =>
      features.contains('profile-edit-transaction');
  bool get supportsProfileCreateTransaction =>
      features.contains('profile-create-transaction');

  factory RouterCapabilities.fromJson(Map<String, Object?> json) {
    final api = json['api'];
    final major = json['major'];
    final minor = json['minor'];
    final backendVersion = json['backend_version'];
    final rawFeatures = json['features'];
    final routerDate = json['router_date'];
    final routerTimezone = json['router_timezone'];
    if (api is! String ||
        major is! num ||
        major != major.toInt() ||
        major < 0 ||
        minor is! num ||
        minor != minor.toInt() ||
        minor < 0 ||
        backendVersion is! String ||
        rawFeatures is! List<Object?> ||
        rawFeatures.any((feature) => feature is! String) ||
        routerDate is! String ||
        !_isIsoDate(routerDate) ||
        routerTimezone is! String ||
        routerTimezone.isEmpty) {
      throw const FormatException('invalid capabilities');
    }
    return RouterCapabilities(
      api: api,
      major: major.toInt(),
      minor: minor.toInt(),
      backendVersion: backendVersion,
      features: rawFeatures.cast<String>().toSet(),
      routerDate: routerDate,
      routerTimezone: routerTimezone,
    );
  }

  static bool _isIsoDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime.utc(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }
}
