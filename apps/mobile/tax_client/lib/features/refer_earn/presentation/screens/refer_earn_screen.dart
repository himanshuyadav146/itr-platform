import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';

class ReferAndEarnScreen extends StatelessWidget {
  const ReferAndEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CoreScaffold(
      title: AppStrings.more,
      body: Center(child: Text('Refer & Earn Screen')),
    );
  }
}
