import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CoreScaffold(
      title: AppStrings.settings,
      body: Center(child: Text('Settings Screen')),
    );
  }
}
