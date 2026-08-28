import '../domain/profile_summary.dart';

class FixtureProfilesRepository {
  const FixtureProfilesRepository();

  List<ProfileSummary> load() => const [
    ProfileSummary(
      nameKey: 'family',
      state: ProfileState.allowed,
      usedMinutes: 80,
      allowanceMinutes: 120,
      deviceCount: 3,
      enabled: true,
    ),
    ProfileSummary(
      nameKey: 'children',
      state: ProfileState.manuallyBlocked,
      usedMinutes: 30,
      allowanceMinutes: 120,
      deviceCount: 2,
      enabled: true,
    ),
  ];
}
