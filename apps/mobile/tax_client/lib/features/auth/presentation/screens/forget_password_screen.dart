import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/app_logo.dart';
import 'package:tax_client/core/common/widgets/auth_scaffold.dart';
import 'package:tax_client/core/common/widgets/core_text_field.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/core/utils/field_validators.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_state.dart';

class ForgetPasswordScreen extends ConsumerStatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  ConsumerState<ForgetPasswordScreen> createState() =>
      _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends ConsumerState<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleForgetPassword() {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ErrorHandler.showError(context, AppStrings.passwordMismatch);
      return;
    }

    ref.read(authViewModelProvider.notifier).forgetPassword(
          _emailController.text,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      authViewModelProvider.select((state) => state is AuthLoading),
    );
    final textTheme = Theme.of(context).textTheme;

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next is AuthError) {
        ErrorHandler.showError(context, next.message);
      } else if (next is AuthInitial && previous is AuthLoading) {
        ErrorHandler.showSuccess(context, AppStrings.passwordResetSuccessful);
        context.pop();
      }
    });

    return AuthScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.center,
                  child: AppLogo(height: 84, width: 84),
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.resetYourPassword,
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.authHeading,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppStrings.enterEmailAndNewPassword,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.authMuted,
                        ),
                      ),
                      SizedBox(height: isCompact ? AppSpacing.xl : AppSpacing.xxxl),
                      AuthFieldGroup(
                        label: 'EMAIL ADDRESS',
                        child: CoreTextField(
                          controller: _emailController,
                          label: AppStrings.emailLabel,
                          hintText: AppStrings.emailHint,
                          keyboardType: TextInputType.emailAddress,
                          useInlineLabel: false,
                          fillColor: AppColors.surfaceVariantDark,
                          enabledBorderColor: AppColors.borderOnDark,
                          focusedBorderColor: AppColors.authMint,
                          borderRadius: AppSpacing.radiusMd,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 19,
                          ),
                          textStyle: textTheme.bodyLarge?.copyWith(
                            color: AppColors.authHeading,
                          ),
                          hintStyle: textTheme.bodyLarge?.copyWith(
                            color: AppColors.authMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.authMuted,
                          ),
                          validator: FieldValidators.validateEmail,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthFieldGroup(
                        label: 'NEW PASSWORD',
                        child: CoreTextField(
                          controller: _passwordController,
                          label: AppStrings.newPassword,
                          hintText: AppStrings.enterNewPassword,
                          obscureText: _obscurePassword,
                          useInlineLabel: false,
                          fillColor: AppColors.surfaceVariantDark,
                          enabledBorderColor: AppColors.borderOnDark,
                          focusedBorderColor: AppColors.authMint,
                          borderRadius: AppSpacing.radiusMd,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 19,
                          ),
                          textStyle: textTheme.bodyLarge?.copyWith(
                            color: AppColors.authHeading,
                          ),
                          hintStyle: textTheme.bodyLarge?.copyWith(
                            color: AppColors.authMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.authMuted,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.authMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.pleaseEnterAPassword;
                            }
                            if (value.length < 6) {
                              return AppStrings.passwordMustBeAtLeast6Characters;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthFieldGroup(
                        label: 'CONFIRM PASSWORD',
                        child: CoreTextField(
                          controller: _confirmPasswordController,
                          label: AppStrings.confirmPassword,
                          hintText: AppStrings.reEnterNewPassword,
                          obscureText: _obscureConfirmPassword,
                          useInlineLabel: false,
                          fillColor: AppColors.surfaceVariantDark,
                          enabledBorderColor: AppColors.borderOnDark,
                          focusedBorderColor: AppColors.authMint,
                          borderRadius: AppSpacing.radiusMd,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 19,
                          ),
                          textStyle: textTheme.bodyLarge?.copyWith(
                            color: AppColors.authHeading,
                          ),
                          hintStyle: textTheme.bodyLarge?.copyWith(
                            color: AppColors.authMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_reset_outlined,
                            color: AppColors.authMuted,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.authMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.pleaseConfirmYourPassword;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      PrimaryButton(
                        text: 'RESET PASSWORD',
                        borderRadius: AppSpacing.radiusPill,
                        isLoading: isLoading,
                        minHeight: 56,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.authMint, AppColors.authMintDark],
                        ),
                        foregroundColor: AppColors.authButtonText,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x334EDEA3),
                            blurRadius: 15,
                            spreadRadius: -4,
                            offset: Offset(0, 10),
                          ),
                        ],
                        textStyle: textTheme.labelLarge?.copyWith(
                          color: AppColors.authButtonText,
                          letterSpacing: 1.4,
                        ),
                        onPressed: isLoading ? null : _handleForgetPassword,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
