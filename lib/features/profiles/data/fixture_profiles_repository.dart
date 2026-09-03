import '../../connection/domain/connected_router.dart';
import '../domain/profile_summary.dart';

abstract interface class ProfilesRepository {
  Future<List<ProfileSummary>> load(ConnectedRouter router);

  Future<ProfileQuickActionResult> setBlocked(
    ConnectedRouter router,
    ProfileSummary profile, {
    required bool blocked,
  });

  Future<ProfileQuickActionResult> setEnabled(
    ConnectedRouter router,
    ProfileSummary profile, {
    required bool enabled,
  });

  Future<ProfileQuickActionResult> addTime(
    ConnectedRouter router,
    ProfileSummary profile,
    ExtraTimeChoice choice,
  );
}

class ProfilesSessionExpiredException implements Exception {
  const ProfilesSessionExpiredException();
}

enum ExtraTimeChoice { oneHour, fourHours, allDay }

enum ProfileQuickActionStatus { confirmed, outcomeUnknown }

class ProfileQuickActionResult {
  const ProfileQuickActionResult({
    required this.status,
    required this.profiles,
  });

  final ProfileQuickActionStatus status;
  final List<ProfileSummary>? profiles;
}

class ProfileQuickActionException implements Exception {
  const ProfileQuickActionException();
}

class FixtureProfilesRepository implements ProfilesRepository {
  const FixtureProfilesRepository();

  List<ProfileSummary> get profiles => const [
    ProfileSummary(
      section: 'family',
      name: 'Family',
      state: ProfileState.allowed,
      usedSeconds: 4800,
      allowanceSeconds: 7200,
      deviceCount: 3,
      enabled: true,
      manualBlocked: false,
      bonusSeconds: 0,
      allDay: false,
    ),
    ProfileSummary(
      section: 'children',
      name: 'Children',
      state: ProfileState.manuallyBlocked,
      usedSeconds: 1800,
      allowanceSeconds: 7200,
      deviceCount: 2,
      enabled: true,
      manualBlocked: true,
      bonusSeconds: 0,
      allDay: false,
    ),
  ];

  @override
  Future<List<ProfileSummary>> load(ConnectedRouter router) async => profiles;

  @override
  Future<ProfileQuickActionResult> addTime(
    ConnectedRouter router,
    ProfileSummary profile,
    ExtraTimeChoice choice,
  ) => throw const ProfileQuickActionException();

  @override
  Future<ProfileQuickActionResult> setBlocked(
    ConnectedRouter router,
    ProfileSummary profile, {
    required bool blocked,
  }) => throw const ProfileQuickActionException();

  @override
  Future<ProfileQuickActionResult> setEnabled(
    ConnectedRouter router,
    ProfileSummary profile, {
    required bool enabled,
  }) => throw const ProfileQuickActionException();
}
