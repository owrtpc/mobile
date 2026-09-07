import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/profile_editor_repository.dart';
import '../domain/profile_order_session.dart';

class ProfileOrderScreen extends StatefulWidget {
  const ProfileOrderScreen({
    required this.session,
    required this.onApply,
    super.key,
  });

  final ProfileOrderSession session;
  final Future<void> Function(List<String>) onApply;

  @override
  State<ProfileOrderScreen> createState() => _ProfileOrderScreenState();
}

class _ProfileOrderScreenState extends State<ProfileOrderScreen> {
  late final _original = widget.session.profiles
      .map((profile) => profile.section)
      .toList();
  late final _order = [..._original];
  bool _applying = false;
  bool _allowPop = false;
  bool _confirmingDiscard = false;
  ProfileEditFailureKind? _failure;

  bool get _dirty => !listEquals(_original, _order);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope(
      canPop: _allowPop || (!_dirty && !_applying),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_applying) _discard();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.orderProfilesTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(strings.orderProfilesExplanation),
            const SizedBox(height: 12),
            if (_dirty)
              Semantics(liveRegion: true, child: Text(strings.unsavedChanges)),
            for (var index = 0; index < _order.length; index++)
              Card(
                key: Key('profile-order-${_order[index]}'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          strings.profileOrderPosition(
                            widget.session.profiles
                                .firstWhere(
                                  (profile) => profile.section == _order[index],
                                )
                                .name,
                            index + 1,
                            _order.length,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            key: Key('profile-order-up-${_order[index]}'),
                            onPressed:
                                !_applying && _failure == null && index > 0
                                ? () => _move(index, index - 1)
                                : null,
                            icon: const Icon(Icons.arrow_upward_rounded),
                            label: Text(strings.moveProfileUp),
                          ),
                          TextButton.icon(
                            key: Key('profile-order-down-${_order[index]}'),
                            onPressed:
                                !_applying &&
                                    _failure == null &&
                                    index < _order.length - 1
                                ? () => _move(index, index + 1)
                                : null,
                            icon: const Icon(Icons.arrow_downward_rounded),
                            label: Text(strings.moveProfileDown),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (_failure != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _failure == ProfileEditFailureKind.conflict
                      ? strings.profileOrderConflict
                      : strings.profileOrderUnconfirmed,
                ),
              ),
            if (_applying)
              Semantics(liveRegion: true, child: Text(strings.applyingChanges)),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('profile-order-apply'),
              onPressed: _dirty && !_applying && _failure == null
                  ? _apply
                  : null,
              icon: _applying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(strings.applyChanges),
            ),
          ],
        ),
      ),
    );
  }

  void _move(int from, int to) => setState(() {
    final section = _order.removeAt(from);
    _order.insert(to, section);
  });

  Future<void> _apply() async {
    if (_applying || _failure != null || !_dirty) return;
    setState(() => _applying = true);
    try {
      await widget.onApply(List.unmodifiable(_order));
      if (mounted) await _close(true);
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

  Future<void> _close(bool applied) async {
    setState(() => _allowPop = true);
    // Let PopScope observe the updated value before popping the route.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(applied);
  }

  Future<void> _discard() async {
    if (_confirmingDiscard) return;
    _confirmingDiscard = true;
    final strings = AppLocalizations.of(context);
    final discard = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(strings.discardChangesTitle),
        content: Text(strings.discardProfileOrderBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.discardChangesAction),
          ),
        ],
      ),
    );
    _confirmingDiscard = false;
    if (mounted && discard == true) await _close(false);
  }
}
