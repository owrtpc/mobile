import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';

Future<void> openSupportLink(BuildContext context, String url) async {
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {
    // External platform errors can contain private data; show only fixed copy.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).openLinkError)),
  );
}

void showPrivacyInformation(BuildContext context) {
  final strings = AppLocalizations.of(context);
  showSupportSheet(
    context,
    title: strings.privacyTitle,
    children: [
      Text(strings.privacyData),
      const SizedBox(height: 16),
      Text(strings.privacyStorage),
      const SizedBox(height: 16),
      Text(strings.privacyRemoval),
      const SizedBox(height: 16),
      Text(strings.privacySharing),
      const SizedBox(height: 16),
      Text(strings.privacyContact),
      TextButton(
        onPressed: () => openSupportLink(
          context,
          'https://github.com/owrtpc/mobile/blob/main/docs/PRIVACY.md',
        ),
        child: Text(strings.privacyOnline),
      ),
    ],
  );
}

void showConnectionHelp(BuildContext context) {
  final strings = AppLocalizations.of(context);
  showSupportSheet(
    context,
    title: strings.supportTitle,
    children: [
      Text(strings.supportConnection),
      const SizedBox(height: 16),
      Text(strings.supportCertificate),
      const SizedBox(height: 16),
      Text(strings.supportRecovery),
      const SizedBox(height: 16),
      Text(strings.supportReporting),
      Wrap(
        spacing: 4,
        children: [
          TextButton(
            onPressed: () => openSupportLink(
              context,
              'https://github.com/owrtpc/core/blob/main/docs/MOBILE_SETUP.md',
            ),
            child: Text(strings.setupGuide),
          ),
          TextButton(
            onPressed: () => openSupportLink(
              context,
              'https://github.com/owrtpc/mobile/issues',
            ),
            child: Text(strings.reportProblem),
          ),
          TextButton(
            onPressed: () => openSupportLink(
              context,
              'https://github.com/owrtpc/mobile/security/policy',
            ),
            child: Text(strings.securityReporting),
          ),
        ],
      ),
    ],
  );
}

void showSupportSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24, end: 8),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: children,
            ),
          ),
        ],
      ),
    ),
  );
}
