import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../connection/domain/connected_router.dart';
import '../data/fixture_profiles_repository.dart';
import '../domain/profile_summary.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({
    required this.router,
    required this.repository,
    this.enableWrites = false,
    super.key,
  });

  final ConnectedRouter router;
  final ProfilesRepository repository;
  final bool enableWrites;

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late Future<List<ProfileSummary>> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = widget.repository.load(widget.router);
  }

  @override
  void didUpdateWidget(covariant ProfilesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router.sessionToken != widget.router.sessionToken ||
        oldWidget.repository.runtimeType != widget.repository.runtimeType) {
      _profiles = widget.repository.load(widget.router);
    }
  }

  Future<void> _reload() async {
    final profiles = widget.repository.load(widget.router);
    setState(() {
      _profiles = profiles;
    });
    await profiles;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final canModify = widget.enableWrites && widget.router.canWrite;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.profilesTitle),
            Text(
              strings.connectedTo(widget.router.endpoint.displayAddress),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: strings.refreshTooltip,
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (canModify)
            IconButton(
              tooltip: strings.addProfileTooltip,
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: FutureBuilder<List<ProfileSummary>>(
        future: _profiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(strings.loadingProfiles),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      strings.loadProfilesError,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(strings.retryAction),
                    ),
                  ],
                ),
              ),
            );
          }
          final profiles = snapshot.data ?? const [];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (widget.router.isPreview) ...[
                  _PreviewNotice(label: strings.fixtureNotice),
                  const SizedBox(height: 12),
                ],
                if (profiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      strings.noProfiles,
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final profile in profiles) ...[
                  _ProfileCard(profile: profile, canWrite: canModify),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
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
    final profileName = profile.name;
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
                _duration(strings, profile.usedSeconds),
                profile.allowanceSeconds == 0
                    ? strings.unlimitedToday
                    : _duration(strings, profile.allowanceSeconds),
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
                    profile.remainingSeconds == null
                        ? strings.unlimitedToday
                        : strings.remaining(
                            _duration(strings, profile.remainingSeconds!),
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

  String _duration(AppLocalizations strings, int seconds) {
    final totalMinutes = seconds ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return strings.durationHoursMinutes(hours, minutes);
    }
    if (hours > 0) return strings.durationHours(hours);
    return strings.durationMinutes(minutes);
  }
}
