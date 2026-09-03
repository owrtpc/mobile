import '../../connection/domain/connected_router.dart';
import '../domain/profile_details.dart';
import 'fixture_profiles_repository.dart';

abstract interface class ProfileDetailsRepository {
  Future<ProfileDetails> load(ConnectedRouter router, String section);
}

class FixtureProfileDetailsRepository implements ProfileDetailsRepository {
  const FixtureProfileDetailsRepository();

  @override
  Future<ProfileDetails> load(ConnectedRouter router, String section) async =>
      ProfileDetails(
        summary: const FixtureProfilesRepository().profiles.firstWhere(
          (profile) => profile.section == section,
        ),
        devices: const [
          ProfileDeviceDetails(
            mac: 'AA:BB:CC:DD:EE:01',
            name: 'Tablet',
            addresses: ['192.168.1.42'],
            usedSeconds: 3000,
          ),
          ProfileDeviceDetails(
            mac: 'AA:BB:CC:DD:EE:02',
            name: 'Game console',
            addresses: ['192.168.1.43'],
            usedSeconds: 1800,
          ),
        ],
        monThuDailyMinutes: 120,
        friSunDailyMinutes: 240,
        sunThuBedtime: const BedtimeWindow(start: '21:30', end: '07:00'),
        friSatBedtime: const BedtimeWindow(start: '23:00', end: '09:00'),
        activityThresholdBytes: null,
      );
}
