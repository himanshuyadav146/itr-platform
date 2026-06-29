import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/core_text_field.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';

/// Shows an optional PDF password prompt for Form 16 uploads.
///
/// Returns `null` if dismissed (cancel), or the entered password (may be empty).
Future<String?> showForm16PasswordSheet(
  BuildContext context, {
  required String formLabel,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _Form16PasswordSheet(formLabel: formLabel),
  );
}

class _Form16PasswordSheet extends StatefulWidget {
  final String formLabel;

  const _Form16PasswordSheet({required this.formLabel});

  @override
  State<_Form16PasswordSheet> createState() => _Form16PasswordSheetState();
}

class _Form16PasswordSheetState extends State<_Form16PasswordSheet> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.authBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radius2xl),
          ),
          border: Border(
            top: BorderSide(color: AppColors.authCardBorder),
            left: BorderSide(color: AppColors.authCardBorder),
            right: BorderSide(color: AppColors.authCardBorder),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderOnDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.authAmber.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.authAmber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.form16PasswordTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.authHeading,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.formLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.authMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop<String?>(null),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariantDark,
                        foregroundColor: AppColors.authHeading,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.authMint.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.authMint.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    AppStrings.form16PasswordHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.authMuted,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.form16PasswordFieldLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.authMuted,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CoreTextField(
                  controller: _controller,
                  label: AppStrings.form16PasswordFieldLabel,
                  hintText: AppStrings.form16PasswordFieldHint,
                  obscureText: _obscure,
                  useInlineLabel: false,
                  textInputAction: TextInputAction.done,
                  fillColor: AppColors.surfaceVariantDark,
                  enabledBorderColor: AppColors.borderOnDark,
                  focusedBorderColor: AppColors.authMint,
                  borderRadius: AppSpacing.radiusMd,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  textStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.authHeading,
                  ),
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.authMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.vpn_key_outlined,
                    color: AppColors.authMuted,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.authMuted,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(''),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.authHeading,
                          side: const BorderSide(color: AppColors.borderOnDark),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                          ),
                        ),
                        child: Text(
                          AppStrings.form16PasswordSkip,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        text: AppStrings.form16PasswordContinue,
                        onPressed: () =>
                            Navigator.of(context).pop(_controller.text.trim()),
                        minHeight: 52,
                        borderRadius: AppSpacing.radiusPill,
                        foregroundColor: AppColors.authButtonText,
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        gradient: const LinearGradient(
                          colors: [AppColors.authMint, AppColors.authMintDark],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
