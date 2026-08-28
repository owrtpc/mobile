import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/fixture_profiles_repository.dart';
import '../domain/profile_summary.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({
    required this.routerAddress,
    required this.canWrite,
    super.key,
  });

  final String routerAddress;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final profiles = const FixtureProfilesRepository().load();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.profilesTitle),
            Text(
              strings.connectedTo(routerAddress),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: strings.refreshTooltip,
            onPressed: () {},
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (canWrite)
            IconButton(
              tooltip: strings.addProfileTooltip,
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _PreviewNotice(label: strings.fixtureNotice),
          const SizedBox(height: 12),
          for (final profile in profiles) ...[
            _ProfileCard(profile: profile, canWrite: canWrite),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.science_outlined, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.canWrite});

  final ProfileSummary profile;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final blocked = profile.state == ProfileState.manuallyBlocked;
    final profileName = profile.nameKey == 'family'
        ? strings.familyProfile
        : strings.childrenProfile;
    final stateLabel = switch (profile.state) {
      ProfileState.allowed => strings.allowed,
      ProfileState.manuallyBlocked => strings.manuallyBlocked,
      ProfileState.bedtime => strings.bedtime,
      ProfileState.timeUsed => strings.timeUsed,
      ProfileState.disabled => strings.disabled,
    };
    final stateIcon = switch (profile.state) {
      ProfileState.allowed => Icons.check_circle_outline_rounded,
      ProfileState.manuallyBlocked => Icons.block_rounded,
      ProfileState.bedtime => Icons.bedtime_outlined,
      ProfileState.timeUsed => Icons.timer_off_outlined,
      ProfileState.disabled => Icons.pause_circle_outline_rounded,
    };
    final stateColor = blocked ? scheme.error : scheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(profileName.characters.first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    profileName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (canWrite) Switch(value: profile.enabled, onChanged: (_) {}),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(stateIcon, size: 20, color: stateColor),
                const SizedBox(width: 8),
                Text(
                  stateLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: stateColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              strings.usedOfAllowance(
                profile.usedMinutes == 80
                    ? strings.oneHourTwenty
                    : strings.thirtyMinutes,
                strings.twoHours,
              ),
            ),
            if (profile.progress case final progress?) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.remainingMinutes == null
                        ? strings.unlimitedToday
                        : strings.remaining(
                            profile.remainingMinutes == 40
                                ? strings.fortyMinutes
                                : strings.oneHourTwenty,
                          ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(strings.deviceCount(profile.deviceCount)),
              ],
            ),
            if (canWrite) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                      ),
                      label: Text(blocked ? strings.unblock : strings.block),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: blocked ? null : () {},
                      icon: const Icon(Icons.more_time_rounded),
                      label: Text(strings.addTime),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
