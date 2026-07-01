import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigates to the in-app WebView for a site path (e.g. `/about-us`).
void openWebContent(
  BuildContext context, {
  required String path,
  required String title,
}) {
  context.push(
    Uri(
      path: '/web',
      queryParameters: {
        'path': path,
        'title': title,
      },
    ).toString(),
  );
}
