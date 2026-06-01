import 'package:flutter/material.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens marketing/support pages in the external browser safely.
class ExternalLinkLauncher {
  ExternalLinkLauncher._();

  static const String _publicSiteHost = 'https://allindiaitr.in';

  static Uri pageUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_publicSiteHost$normalizedPath');
  }

  static Future<void> openPage(BuildContext context, String path) async {
    final uri = pageUri(path);

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (context.mounted) {
          ErrorHandler.showError(
            context,
            'Unable to open link. Please try again.',
          );
        }
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ErrorHandler.showError(
          context,
          'Unable to open link. Please try again.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        ErrorHandler.showError(
          context,
          'Unable to open link. Please try again.',
        );
      }
    }
  }
}
