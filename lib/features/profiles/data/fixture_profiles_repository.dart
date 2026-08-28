import '../../connection/domain/connected_router.dart';
import '../domain/profile_summary.dart';

abstract interface class ProfilesRepository {
  Future<List<ProfileSummary>> load(ConnectedRouter router);
}

class FixtureProfilesRepository implements ProfilesRepository {
  const FixtureProfilesRepository();

  @override
  Future<List<ProfileSummary>> load(ConnectedRouter router) async => const [
    ProfileSummary(
      section: 'family',
      name: 'Family',
      state: ProfileState.allowed,
      usedSeconds: 4800,
      allowanceSeconds: 7200,
      deviceCount: 3,
      enabled: true,
    ),
    ProfileSummary(
      section: 'children',
      name: 'Children',
      state: ProfileState.manuallyBlocked,
      usedSeconds: 1800,
      allowanceSeconds: 7200,
      deviceCount: 2,
      enabled: true,
    ),
  ];
}
