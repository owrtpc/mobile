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
  final List<ProfileEditDevice> devices;

  bool get isCreating => draft.section.isEmpty;
}

class ProfileEditDevice {
  const ProfileEditDevice({
    required this.details,
    required this.assignedSection,
    required this.assignedProfileName,
  });

  final ProfileDeviceDetails details;
  final String? assignedSection;
  final String? assignedProfileName;

  bool isAssignedElsewhere(String section) =>
      assignedSection != null && assignedSection != section;
}
