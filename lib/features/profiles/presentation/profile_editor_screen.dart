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
  bool get _canSave => _dirty && _draft.isValid && !_applying;

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
          title: Text(
            widget.session.isCreating
                ? strings.createProfileTitle
                : strings.editProfileTitle,
          ),
          actions: [
            TextButton(
              key: const Key('profile-editor-save-top'),
              onPressed: _canSave ? _apply : null,
              child: Text(strings.saveProfileAction),
            ),
          ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_draft.devices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(strings.noAssociatedDevices),
                    )
                  else
                    for (final mac in _draft.devices)
                      _AssignedDeviceTile(
                        device: _deviceFor(mac),
                        fallbackMac: mac,
                        enabled: !_applying,
                        onRemove: () => _removeDevice(mac),
                      ),
                  OutlinedButton.icon(
                    key: const Key('profile-editor-add-devices'),
                    onPressed: _applying ? null : _addDevices,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(strings.addDevicesAction),
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
              onPressed: _canSave ? _apply : null,
              icon: _applying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(strings.saveProfileAction),
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

  ProfileEditDevice? _deviceFor(String mac) => widget.session.devices
      .where((device) => device.details.mac == mac)
      .firstOrNull;

  void _removeDevice(String mac) =>
      _change(_draft.copyWith(devices: [..._draft.devices]..remove(mac)));

  Future<void> _addDevices() async {
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _DevicePickerSheet(
        devices: widget.session.devices
            .where((device) => !_draft.devices.contains(device.details.mac))
            .toList(growable: false),
        profileSection: _draft.section,
      ),
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    _change(_draft.copyWith(devices: [..._draft.devices, ...selected]));
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

class _AssignedDeviceTile extends StatelessWidget {
  const _AssignedDeviceTile({
    required this.device,
    required this.fallbackMac,
    required this.enabled,
    required this.onRemove,
  });

  final ProfileEditDevice? device;
  final String fallbackMac;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final details = device?.details;
    final mac = details?.mac ?? fallbackMac;
    return ListTile(
      key: Key('profile-editor-device-$mac'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.devices_rounded),
      title: Text(details?.name ?? strings.unnamedDevice),
      subtitle: Text([...?details?.addresses, mac].join(' · ')),
      trailing: IconButton(
        key: Key('profile-editor-remove-device-$mac'),
        tooltip: strings.removeDeviceAction,
        onPressed: enabled ? onRemove : null,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    );
  }
}

class _DevicePickerSheet extends StatefulWidget {
  const _DevicePickerSheet({
    required this.devices,
    required this.profileSection,
  });

  final List<ProfileEditDevice> devices;
  final String profileSection;

  @override
  State<_DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<_DevicePickerSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final selectable = widget.devices.where(
      (device) => !device.isAssignedElsewhere(widget.profileSection),
    );
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                strings.addDevicesTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: widget.devices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          strings.noDevicesAvailable,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final device in widget.devices)
                          CheckboxListTile(
                            key: Key(
                              'profile-device-option-${device.details.mac}',
                            ),
                            value: _selected.contains(device.details.mac),
                            onChanged:
                                device.isAssignedElsewhere(
                                  widget.profileSection,
                                )
                                ? null
                                : (checked) => setState(() {
                                    if (checked ?? false) {
                                      _selected.add(device.details.mac);
                                    } else {
                                      _selected.remove(device.details.mac);
                                    }
                                  }),
                            title: Text(
                              device.details.name ?? strings.unnamedDevice,
                            ),
                            subtitle: Text(
                              device.isAssignedElsewhere(widget.profileSection)
                                  ? strings.deviceAssignedToProfile(
                                      device.assignedProfileName ?? '',
                                    )
                                  : [
                                      ...device.details.addresses,
                                      device.details.mac,
                                    ].join(' · '),
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(strings.cancelAction),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('profile-device-picker-add'),
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.pop(context, _selected),
                      child: Text(strings.addDevicesAction),
                    ),
                  ),
                ],
              ),
            ),
            if (selectable.isEmpty && widget.devices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  strings.allDevicesAssigned,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
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
