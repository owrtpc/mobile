class ProfileOrderEntry {
  const ProfileOrderEntry({required this.section, required this.name});

  final String section;
  final String name;
}

class ProfileOrderSession {
  ProfileOrderSession({
    required this.revision,
    required List<ProfileOrderEntry> profiles,
  }) : profiles = List.unmodifiable(profiles);

  final String revision;
  final List<ProfileOrderEntry> profiles;

  bool accepts(List<String> order) {
    final expected = profiles.map((profile) => profile.section).toSet();
    return order.length == profiles.length &&
        order.toSet().length == order.length &&
        order.every(expected.contains);
  }
}
