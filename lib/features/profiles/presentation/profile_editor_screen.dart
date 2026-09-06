import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/profile_details.dart';
import '../domain/profile_draft.dart';
import '../domain/profile_edit_session.dart';
import '../data/profile_editor_repository.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({
    required this.session,
    required this.onApply,
    super.key,
  });

  final ProfileEditSession session;
  final Future<void> Function(ProfileDraft draft) onApply;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final ProfileDraft _original;
  late ProfileDraft _draft;
  late final TextEditingController _nameController;
  late final TextEditingController _monThuController;
  late final TextEditingController _friSunController;
  bool _applying = false;
  ProfileEditFailureKind? _failure;

  bool get _dirty => !_draft.hasSameValues(_original);

  @override
  void initState() {
    super.initState();
    _original = widget.session.draft;
    _draft = _original;
    _nameController = TextEditingController(text: _draft.name);
    _monThuController = TextEditingController(
      text: _draft.monThuDailyMinutes.toString(),
    );
    _friSunController = TextEditingController(
      text: _draft.friSunDailyMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monThuController.dispose();
    _friSunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope(
      canPop: !_dirty || _applying,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_applying) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.editProfileTitle),
          bottom: _dirty
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(28),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      strings.unsavedChanges,
                      key: const Key('profile-editor-unsaved'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                )
              : null,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _EditorSection(
              title: strings.profileEditorProfileSection,
              child: Column(
                children: [
                  TextField(
                    key: const Key('profile-editor-name'),
                    controller: _nameController,
                    enabled: !_applying,
                    decoration: InputDecoration(
                      labelText: strings.profileName,
                      errorText:
                          _draft.issues.contains(ProfileDraftIssue.emptyName)
                          ? strings.requiredField
                          : _draft.issues.contains(
                              ProfileDraftIssue.nameTooLong,
                            )
                          ? strings.profileNameTooLong
                          : null,
                    ),
                    onChanged: (value) => _change(_draft.copyWith(name: value)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.profileEnabled),
                    value: _draft.enabled,
                    onChanged: _applying
                        ? null
                        : (value) => _change(_draft.copyWith(enabled: value)),
                  ),
                ],
              ),
            ),
            _EditorSection(
              title: strings.profileEditorDevicesSection,
              description: strings.profileEditorDevicesExplanation,
              child: widget.session.devices.isEmpty
                  ? Text(strings.noAssociatedDevices)
                  : Column(
                      children: [
                        for (final device in widget.session.devices)
                          CheckboxListTile(
                            key: Key('profile-editor-device-${device.mac}'),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(device.name ?? strings.unnamedDevice),
                            subtitle: Text(device.mac),
                            value: _draft.devices.contains(device.mac),
                            onChanged: _applying
                                ? null
                                : (selected) => _toggleDevice(
                                    device.mac,
                                    selected ?? false,
                                  ),
                          ),
                      ],
                    ),
            ),
            _EditorSection(
              title: strings.profileEditorAllowanceSection,
              description: strings.profileEditorAllowanceExplanation,
              child: Column(
                children: [
                  _AllowanceField(
                    key: const Key('profile-editor-mon-thu'),
                    label: strings.allowanceMondayThursday,
                    controller: _monThuController,
                    enabled: !_applying,
                    onChanged: (value) =>
                        _change(_draft.copyWith(monThuDailyMinutes: value)),
                  ),
                  const SizedBox(height: 12),
                  _AllowanceField(
                    key: const Key('profile-editor-fri-sun'),
                    label: strings.allowanceFridaySunday,
                    controller: _friSunController,
                    enabled: !_applying,
                    onChanged: (value) =>
                        _change(_draft.copyWith(friSunDailyMinutes: value)),
                  ),
                ],
              ),
            ),
            _EditorSection(
              title: strings.profileEditorBedtimeSection,
              description: strings.profileEditorBedtimeExplanation,
              child: Column(
                children: [
                  _BedtimeEditor(
                    label: strings.bedtimeSundayThursday,
                    window: _draft.sunThuBedtime,
                    enabled: !_applying,
                    onChanged: (window) =>
                        _change(_draft.copyWith(sunThuBedtime: window)),
                  ),
                  const Divider(height: 28),
                  _BedtimeEditor(
                    label: strings.bedtimeFridaySaturday,
                    window: _draft.friSatBedtime,
                    enabled: !_applying,
                    onChanged: (window) =>
                        _change(_draft.copyWith(friSatBedtime: window)),
                  ),
                ],
              ),
            ),
            _EditorSection(
              title: strings.profileEditorActivitySection,
              child: DropdownButtonFormField<int?>(
                key: const Key('profile-editor-activity'),
                initialValue: _knownThreshold(_draft.activityThresholdBytes),
                decoration: InputDecoration(
                  labelText: strings.activityDetection,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(strings.activityDefault),
                  ),
                  DropdownMenuItem(
                    value: 32768,
                    child: Text(strings.activitySensitive),
                  ),
                  DropdownMenuItem(
                    value: 131072,
                    child: Text(strings.activityStandard),
                  ),
                  DropdownMenuItem(
                    value: 262144,
                    child: Text(strings.activityLowSensitivity),
                  ),
                  if (_draft.activityThresholdBytes case final threshold?
                      when threshold != 32768 &&
                          threshold != 131072 &&
                          threshold != 262144)
                    DropdownMenuItem(
                      value: threshold,
                      child: Text(strings.activityCustom(threshold)),
                    ),
                ],
                onChanged: _applying
                    ? null
                    : (value) => _change(
                        _draft.copyWith(
                          activityThresholdBytes: value,
                          clearActivityThreshold: value == null,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            if (_failure case final failure?) ...[
              _ApplyError(
                key: const Key('profile-editor-apply-error'),
                message: _failureMessage(strings, failure),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              key: const Key('profile-editor-apply'),
              onPressed: _dirty && _draft.isValid && !_applying ? _apply : null,
              icon: _applying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _applying ? strings.applyingChanges : strings.applyChanges,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _knownThreshold(int? value) => value;

  void _change(ProfileDraft draft) => setState(() {
    _draft = draft;
    _failure = null;
  });

  void _toggleDevice(String mac, bool selected) {
    final devices = [..._draft.devices];
    if (selected) {
      if (!devices.contains(mac)) devices.add(mac);
    } else {
      devices.remove(mac);
    }
    _change(_draft.copyWith(devices: devices));
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await widget.onApply(_draft);
      if (mounted) Navigator.of(context).pop(_draft);
    } on ProfileEditException catch (error) {
      if (mounted) setState(() => _failure = error.kind);
    } on Object {
      if (mounted) {
        setState(() => _failure = ProfileEditFailureKind.unavailable);
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  String _failureMessage(
    AppLocalizations strings,
    ProfileEditFailureKind failure,
  ) => switch (failure) {
    ProfileEditFailureKind.conflict => strings.profileEditConflict,
    ProfileEditFailureKind.validation => strings.profileEditValidationError,
    ProfileEditFailureKind.apply => strings.profileEditApplyError,
    ProfileEditFailureKind.sessionExpired => strings.profileEditSessionExpired,
    ProfileEditFailureKind.unavailable => strings.profileEditUnavailable,
  };

  Future<void> _confirmDiscard() async {
    final strings = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.discardChangesTitle),
        content: Text(strings.discardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.discardChangesAction),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }
}

class _ApplyError extends StatelessWidget {
  const _ApplyError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (description case final value?) ...[
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );
}

class _AllowanceField extends StatelessWidget {
  const _AllowanceField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      helperText: AppLocalizations.of(context).allowanceMinutesHelp,
    ),
    onChanged: (value) => onChanged(int.tryParse(value) ?? -1),
  );
}

class _BedtimeEditor extends StatelessWidget {
  const _BedtimeEditor({
    required this.label,
    required this.window,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final BedtimeWindow window;
  final bool enabled;
  final ValueChanged<BedtimeWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: window.isEnabled,
          onChanged: enabled
              ? (value) => onChanged(
                  value
                      ? const BedtimeWindow(start: '21:30', end: '07:00')
                      : const BedtimeWindow(start: null, end: null),
                )
              : null,
        ),
        if (window.isEnabled)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: enabled
                      ? () => _pickTime(
                          context,
                          window.start!,
                          (value) => onChanged(
                            BedtimeWindow(start: value, end: window.end),
                          ),
                        )
                      : null,
                  child: Text(strings.bedtimeStarts(window.start!)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: enabled
                      ? () => _pickTime(
                          context,
                          window.end!,
                          (value) => onChanged(
                            BedtimeWindow(start: window.start, end: value),
                          ),
                        )
                      : null,
                  child: Text(strings.bedtimeEnds(window.end!)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    String value,
    ValueChanged<String> onPicked,
  ) async {
    final parts = value.split(':');
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (result != null) {
      onPicked(
        '${result.hour.toString().padLeft(2, '0')}:'
        '${result.minute.toString().padLeft(2, '0')}',
      );
    }
  }
}
