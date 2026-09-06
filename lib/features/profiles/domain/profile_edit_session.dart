import 'profile_details.dart';
import 'profile_draft.dart';

class ProfileEditSession {
  const ProfileEditSession({
    required this.revision,
    required this.draft,
    required this.devices,
  });

  final String revision;
  final ProfileDraft draft;
  final List<ProfileDeviceDetails> devices;
}
