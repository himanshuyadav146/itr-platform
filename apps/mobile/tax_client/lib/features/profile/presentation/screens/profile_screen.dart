import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CoreScaffold(
      title: AppStrings.profile,
      body: Center(child: Text('Profile Screen')),
    );
  }
}
