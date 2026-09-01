import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../connection/domain/connected_router.dart';
import '../data/fixture_profiles_repository.dart';
import '../domain/profile_summary.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({
    required this.router,
    required this.repository,
    this.onSessionExpired,
    super.key,
  });

  final ConnectedRouter router;
  final ProfilesRepository repository;
  final Future<void> Function()? onSessionExpired;

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen>
    with WidgetsBindingObserver {
  static const _freshnessWindow = Duration(seconds: 90);

  List<ProfileSummary>? _profiles;
  Object? _loadError;
  DateTime? _lastSuccessfulRefresh;
  String? _busyProfile;
  bool _loading = true;
  bool _refreshing = false;
  bool _connectionHealthy = false;
  bool _reloadAfterAction = false;
  bool _reloadAfterCurrent = false;
  Timer? _freshnessTimer;
  Future<void>? _refreshFuture;

  bool get _isFresh {
    final refreshed = _lastSuccessfulRefresh;
    return refreshed != null &&
        DateTime.now().difference(refreshed) < _freshnessWindow;
  }

  bool get _supportsWrites =>
      widget.router.canWrite &&
      widget.router.capabilities.features.contains('quick-actions');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _freshnessTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
    unawaited(_reload(showLoading: true));
  }

  @override
  void didUpdateWidget(covariant ProfilesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router.sessionToken != widget.router.sessionToken ||
        oldWidget.repository.runtimeType != widget.repository.runtimeType) {
      _profiles = null;
      _lastSuccessfulRefresh = null;
      _connectionHealthy = false;
      unawaited(_reload(showLoading: true, forceAfterCurrent: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_busyProfile != null) {
      _reloadAfterAction = true;
    } else {
      unawaited(_reload());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _freshnessTimer?.cancel();
    super.dispose();
  }

  Future<void> _reload({
    bool showLoading = false,
    bool userInitiated = false,
    bool forceAfterCurrent = false,
  }) async {
    if (_busyProfile != null) {
      _reloadAfterAction = true;
      return;
    }
    final currentRefresh = _refreshFuture;
    if (currentRefresh != null) {
      if (forceAfterCurrent) _reloadAfterCurrent = true;
      await currentRefresh;
      return;
    }

    final refresh = _performReload(
      showLoading: showLoading,
      userInitiated: userInitiated,
    );
    _refreshFuture = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
      if (_reloadAfterCurrent && mounted) {
        _reloadAfterCurrent = false;
        unawaited(_reload(showLoading: true));
      }
    }
  }

  Future<void> _performReload({
    required bool showLoading,
    required bool userInitiated,
  }) async {
    if (mounted) {
      setState(() {
        _refreshing = true;
        if (showLoading) _loading = true;
        _loadError = null;
      });
    }
    try {
      final profiles = await widget.repository.load(widget.router);
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _loading = false;
        _refreshing = false;
        _loadError = null;
        _connectionHealthy = true;
        _lastSuccessfulRefresh = DateTime.now();
      });
    } on ProfilesSessionExpiredException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _connectionHealthy = false;
      });
      await widget.onSessionExpired?.call();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _loadError = error;
        _connectionHealthy = false;
      });
      if (userInitiated && _profiles != null) {
        final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            key: const Key('profiles-refresh-failed'),
            content: Text(AppLocalizations.of(context).refreshProfilesError),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
            key: const Key('profiles-refresh-action'),
            tooltip: strings.refreshTooltip,
            onPressed: _busyProfile == null && !_refreshing
                ? () => _reload(userInitiated: true)
                : null,
            icon: _refreshing
                ? const SizedBox.square(
                    key: Key('profiles-refresh-progress'),
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
    final profiles = _profiles;
    if (_loading && profiles == null) {
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
    if (profiles == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44),
              const SizedBox(height: 12),
              Text(strings.loadProfilesError, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _reload(showLoading: true),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.retryAction),
              ),
            ],
          ),
        ),
      );
    }

    final dataIsFresh = _connectionHealthy && _loadError == null && _isFresh;
    final actionsEnabled = dataIsFresh && _busyProfile == null;
    return RefreshIndicator(
      onRefresh: () => _reload(userInitiated: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (widget.router.isPreview) ...[
            _Notice(label: strings.fixtureNotice, icon: Icons.science_outlined),
            const SizedBox(height: 12),
          ],
          if (!dataIsFresh) ...[
            _Notice(
              key: const Key('stale-profiles-notice'),
              label: strings.staleProfilesNotice,
              icon: Icons.sync_problem_rounded,
            ),
            const SizedBox(height: 12),
          ],
          if (profiles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(strings.noProfiles, textAlign: TextAlign.center),
            ),
          for (final profile in profiles) ...[
            _ProfileCard(
              profile: profile,
              showWriteControls: _supportsWrites,
              actionsEnabled: actionsEnabled,
              busy: _busyProfile == profile.section,
              onBlockedChanged: () => _changeBlocked(profile),
              onEnabledChanged: (enabled) => _changeEnabled(profile, enabled),
              onAddTime: () => _chooseExtraTime(profile),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _changeBlocked(ProfileSummary profile) async {
    final blocked = !profile.manualBlocked;
    if (blocked) {
      final confirmed = await _confirm(
        title: AppLocalizations.of(context).blockProfileTitle(profile.name),
        body: AppLocalizations.of(context).blockProfileBody,
        action: AppLocalizations.of(context).block,
      );
      if (!confirmed || !mounted) return;
    }
    final strings = AppLocalizations.of(context);
    await _runQuickAction(
      profile,
      () => widget.repository.setBlocked(
        widget.router,
        profile,
        blocked: blocked,
      ),
      successMessage: blocked
          ? strings.profileBlockedSuccess(profile.name)
          : strings.profileUnblockedSuccess(profile.name),
    );
  }

  Future<void> _changeEnabled(ProfileSummary profile, bool enabled) async {
    if (!enabled) {
      final confirmed = await _confirm(
        title: AppLocalizations.of(context).disableProfileTitle(profile.name),
        body: AppLocalizations.of(context).disableProfileBody,
        action: AppLocalizations.of(context).disableProfileAction,
      );
      if (!confirmed || !mounted) return;
    }
    final strings = AppLocalizations.of(context);
    await _runQuickAction(
      profile,
      () => widget.repository.setEnabled(
        widget.router,
        profile,
        enabled: enabled,
      ),
      successMessage: enabled
          ? strings.profileEnabledSuccess(profile.name)
          : strings.profileDisabledSuccess(profile.name),
    );
  }

  Future<void> _chooseExtraTime(ProfileSummary profile) async {
    final strings = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<ExtraTimeChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.addTimeTitle(profile.name),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(strings.addTimeExplanation),
                const SizedBox(height: 12),
                _ExtraTimeTile(
                  key: const Key('add-one-hour'),
                  label: strings.addOneHour,
                  onTap: () => Navigator.pop(context, ExtraTimeChoice.oneHour),
                ),
                _ExtraTimeTile(
                  key: const Key('add-four-hours'),
                  label: strings.addFourHours,
                  onTap: () =>
                      Navigator.pop(context, ExtraTimeChoice.fourHours),
                ),
                _ExtraTimeTile(
                  key: const Key('add-all-day'),
                  label: strings.addAllDay,
                  onTap: () => Navigator.pop(context, ExtraTimeChoice.allDay),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final choiceLabel = switch (choice) {
      ExtraTimeChoice.oneHour => strings.addOneHour,
      ExtraTimeChoice.fourHours => strings.addFourHours,
      ExtraTimeChoice.allDay => strings.addAllDay,
    };
    await _runQuickAction(
      profile,
      () => widget.repository.addTime(widget.router, profile, choice),
      successMessage: strings.profileTimeAddedSuccess(
        profile.name,
        choiceLabel,
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancelAction),
            ),
            FilledButton(
              key: const Key('confirm-quick-action'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _runQuickAction(
    ProfileSummary profile,
    Future<ProfileQuickActionResult> Function() operation, {
    required String successMessage,
  }) async {
    if (_busyProfile != null) return;
    setState(() {
      _busyProfile = profile.section;
    });
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    try {
      final result = await operation();
      if (!mounted) return;
      final refreshed = result.profiles;
      setState(() {
        if (refreshed != null) {
          _profiles = refreshed;
          _loadError = null;
          _connectionHealthy = true;
          _lastSuccessfulRefresh = DateTime.now();
        } else {
          _connectionHealthy = false;
        }
      });
      messenger.showSnackBar(
        SnackBar(
          key: Key(
            result.status == ProfileQuickActionStatus.confirmed
                ? 'quick-action-success'
                : 'quick-action-unknown',
          ),
          content: Text(
            result.status == ProfileQuickActionStatus.confirmed
                ? successMessage
                : AppLocalizations.of(context).quickActionUnknown,
          ),
        ),
      );
    } on ProfilesSessionExpiredException {
      if (!mounted) return;
      await widget.onSessionExpired?.call();
    } on ProfileQuickActionException {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          key: const Key('quick-action-failed'),
          content: Text(AppLocalizations.of(context).quickActionFailed),
        ),
      );
    } on Object {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          key: const Key('quick-action-failed'),
          content: Text(AppLocalizations.of(context).quickActionFailed),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyProfile = null;
        });
        if (_reloadAfterAction) {
          _reloadAfterAction = false;
          unawaited(_reload());
        }
      }
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.label, required this.icon, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.showWriteControls,
    required this.actionsEnabled,
    required this.busy,
    required this.onBlockedChanged,
    required this.onEnabledChanged,
    required this.onAddTime,
  });

  final ProfileSummary profile;
  final bool showWriteControls;
  final bool actionsEnabled;
  final bool busy;
  final VoidCallback onBlockedChanged;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onAddTime;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final blocked = profile.manualBlocked;
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
    final addTimeUnavailableMessage = switch (profile) {
      ProfileSummary(state: ProfileState.bedtime) =>
        strings.addTimeUnavailableBedtime,
      ProfileSummary(manualBlocked: true) => strings.addTimeUnavailableBlocked,
      ProfileSummary(allowanceSeconds: 0, allDay: false) =>
        strings.addTimeUnavailableUnlimited,
      _ => null,
    };
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
                if (showWriteControls)
                  Semantics(
                    key: Key('enabled-semantics-${profile.section}'),
                    label: profile.enabled
                        ? strings.disableProfileA11y(profileName)
                        : strings.enableProfileA11y(profileName),
                    toggled: profile.enabled,
                    enabled: actionsEnabled && !busy,
                    onTap: actionsEnabled && !busy
                        ? () => onEnabledChanged(!profile.enabled)
                        : null,
                    child: ExcludeSemantics(
                      child: Switch(
                        key: Key('enabled-switch-${profile.section}'),
                        value: profile.enabled,
                        onChanged: actionsEnabled && !busy
                            ? onEnabledChanged
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            if (busy) ...[
              const SizedBox(height: 10),
              Semantics(
                label: strings.profileActionInProgress(profileName),
                child: const LinearProgressIndicator(),
              ),
            ],
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
            if (showWriteControls && profile.enabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: Key('block-action-${profile.section}'),
                      onPressed: actionsEnabled && !busy
                          ? onBlockedChanged
                          : null,
                      icon: Icon(
                        blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                      ),
                      label: Text(blocked ? strings.unblock : strings.block),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: Key('add-time-${profile.section}'),
                      onPressed: actionsEnabled && !busy && profile.canAddTime
                          ? onAddTime
                          : null,
                      icon: const Icon(Icons.more_time_rounded),
                      label: Text(strings.addTime),
                    ),
                  ),
                ],
              ),
              if (addTimeUnavailableMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.more_time_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        addTimeUnavailableMessage,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
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

class _ExtraTimeTile extends StatelessWidget {
  const _ExtraTimeTile({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.more_time_rounded),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
