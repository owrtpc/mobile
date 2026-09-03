import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../connection/domain/connected_router.dart';
import '../data/fixture_profiles_repository.dart';
import '../data/profile_details_repository.dart';
import '../domain/profile_details.dart';
import '../domain/profile_summary.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({
    required this.profile,
    required this.repository,
    required this.routerProvider,
    this.onSessionExpired,
    super.key,
  });

  final ProfileSummary profile;
  final ProfileDetailsRepository repository;
  final ConnectedRouter Function() routerProvider;
  final Future<void> Function()? onSessionExpired;

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  ProfileDetails? _details;
  Object? _error;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool recoverSession = true}) async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final details = await widget.repository.load(
        widget.routerProvider(),
        widget.profile.section,
      );
      if (!mounted) return;
      setState(() {
        _details = details;
        _loading = false;
        _refreshing = false;
      });
    } on ProfilesSessionExpiredException {
      if (recoverSession && widget.onSessionExpired != null) {
        await widget.onSessionExpired!.call();
        if (!mounted) return;
        setState(() => _refreshing = false);
        await _load(recoverSession: false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = const ProfilesSessionExpiredException();
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        actions: [
          IconButton(
            key: const Key('profile-details-refresh'),
            tooltip: strings.refreshProfileDetailsTooltip,
            onPressed: _refreshing ? null : _load,
            icon: _refreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(strings),
    );
  }

  Widget _buildBody(AppLocalizations strings) {
    final details = _details;
    if (_loading && details == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(strings.loadingProfileDetails),
          ],
        ),
      );
    }
    if (details == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44),
              const SizedBox(height: 12),
              Text(
                strings.loadProfileDetailsError,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _refreshing ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.retryAction),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (_error != null) ...[
            _DetailsNotice(label: strings.profileDetailsRefreshError),
            const SizedBox(height: 12),
          ],
          _TodayCard(details: details),
          const SizedBox(height: 20),
          _SectionTitle(
            title: strings.associatedDevices,
            trailing: strings.deviceCount(details.devices.length),
          ),
          const SizedBox(height: 8),
          if (details.devices.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(strings.noAssociatedDevices),
              ),
            )
          else
            for (final device in details.devices) _DeviceCard(device: device),
          const SizedBox(height: 20),
          _SectionTitle(title: strings.profileSchedule),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _SettingRow(
                    label: strings.allowanceMondayThursday,
                    value: _allowance(strings, details.monThuDailyMinutes),
                  ),
                  const Divider(height: 28),
                  _SettingRow(
                    label: strings.allowanceFridaySunday,
                    value: _allowance(strings, details.friSunDailyMinutes),
                  ),
                  const Divider(height: 28),
                  _SettingRow(
                    label: strings.bedtimeSundayThursday,
                    value: _bedtime(strings, details.sunThuBedtime),
                  ),
                  const Divider(height: 28),
                  _SettingRow(
                    label: strings.bedtimeFridaySaturday,
                    value: _bedtime(strings, details.friSatBedtime),
                  ),
                  if (details.activityThresholdBytes case final threshold?) ...[
                    const Divider(height: 28),
                    _SettingRow(
                      label: strings.activityThreshold,
                      value: strings.activityThresholdBytes(threshold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _allowance(AppLocalizations strings, int minutes) =>
      minutes == 0 ? strings.unlimited : _duration(strings, minutes * 60);

  String _bedtime(AppLocalizations strings, BedtimeWindow window) =>
      window.isEnabled
      ? '${window.start}–${window.end}'
      : strings.notConfigured;
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.details});

  final ProfileDetails details;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final summary = details.summary;
    final scheme = Theme.of(context).colorScheme;
    final stateLabel = switch (summary.state) {
      ProfileState.allowed => strings.allowed,
      ProfileState.manuallyBlocked => strings.manuallyBlocked,
      ProfileState.bedtime => strings.bedtime,
      ProfileState.timeUsed => strings.timeUsed,
      ProfileState.disabled => strings.disabled,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.today, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  stateLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              strings.usedOfAllowance(
                _duration(strings, summary.usedSeconds),
                summary.allowanceSeconds == 0
                    ? strings.unlimitedToday
                    : _duration(strings, summary.allowanceSeconds),
              ),
            ),
            if (summary.progress case final progress?) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              summary.remainingSeconds == null
                  ? strings.unlimitedToday
                  : strings.remaining(
                      _duration(strings, summary.remainingSeconds!),
                    ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final ProfileDeviceDetails device;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final name = device.name ?? strings.unnamedDevice;
    return Card(
      key: Key('profile-device-${device.mac}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(child: Icon(Icons.devices_rounded)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  if (device.addresses.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(device.addresses.join(' · ')),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    device.mac,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  device.usedSeconds == null
                      ? strings.usageUnavailable
                      : _duration(strings, device.usedSeconds!),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  strings.usedToday,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (trailing case final value?) Text(value),
    ],
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 16),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _DetailsNotice extends StatelessWidget {
  const _DetailsNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.sync_problem_rounded),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
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
