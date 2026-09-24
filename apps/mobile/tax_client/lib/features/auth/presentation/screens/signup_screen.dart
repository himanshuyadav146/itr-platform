import 'package:flutter/gestures.dart';
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
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/services/analytics/analytics_service.dart';
import 'package:tax_client/core/utils/web_content_navigation.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_state.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isTermsAccepted = false;
  bool _isFormValid = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _mobileController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _nameController.text.trim().isNotEmpty &&
          _mobileController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          _isTermsAccepted;
    });
  }

  void _openPolicyPage({required String path, required String title}) {
    openWebContent(context, path: path, title: title);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final textTheme = Theme.of(context).textTheme;

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next is AuthRegistered) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
        context.go('/login');
      } else if (next is AuthAuthenticated) {
        context.go('/');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    return AuthScaffold(
      maxContentWidth: 576,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                      AppStrings.signupHeader,
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.authHeading,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.signupSubtitle,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.authMuted,
                      ),
                    ),
                    SizedBox(
                      height: isCompact ? AppSpacing.xl : AppSpacing.xxxl,
                    ),
                    AuthFieldGroup(
                      label: 'FULL NAME',
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: AppColors.authMuted,
                        letterSpacing: 2,
                      ),
                      child: CoreTextField(
                        controller: _nameController,
                        label: AppStrings.nameLabel,
                        hintText: AppStrings.nameHint,
                        useInlineLabel: false,
                        fillColor: AppColors.surfaceVariantDark,
                        enabledBorderColor: AppColors.borderOnDark,
                        focusedBorderColor: AppColors.authMint,
                        borderRadius: 16,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        textStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authHeading,
                        ),
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.authMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthFieldGroup(
                      label: 'MOBILE',
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: AppColors.authMuted,
                        letterSpacing: 2,
                      ),
                      child: CoreTextField(
                        controller: _mobileController,
                        label: AppStrings.mobileLabel,
                        hintText: AppStrings.mobileHint,
                        keyboardType: TextInputType.phone,
                        useInlineLabel: false,
                        fillColor: AppColors.surfaceVariantDark,
                        enabledBorderColor: AppColors.borderOnDark,
                        focusedBorderColor: AppColors.authMint,
                        borderRadius: 16,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        textStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authHeading,
                        ),
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: AppColors.authMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthFieldGroup(
                      label: 'EMAIL IDENTIFIER',
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: AppColors.authMuted,
                        letterSpacing: 2,
                      ),
                      child: CoreTextField(
                        controller: _emailController,
                        label: AppStrings.emailIdLabel,
                        hintText: AppStrings.emailHint,
                        keyboardType: TextInputType.emailAddress,
                        useInlineLabel: false,
                        fillColor: AppColors.surfaceVariantDark,
                        enabledBorderColor: AppColors.borderOnDark,
                        focusedBorderColor: AppColors.authMint,
                        borderRadius: 16,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        textStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authHeading,
                        ),
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.alternate_email_rounded,
                          color: AppColors.authMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthFieldGroup(
                      label: 'PASSWORD',
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: AppColors.authMuted,
                        letterSpacing: 2,
                      ),
                      child: CoreTextField(
                        controller: _passwordController,
                        label: AppStrings.passwordLabel,
                        hintText: AppStrings.passwordHint,
                        obscureText: !_isPasswordVisible,
                        useInlineLabel: false,
                        fillColor: AppColors.surfaceVariantDark,
                        enabledBorderColor: AppColors.borderOnDark,
                        focusedBorderColor: AppColors.authMint,
                        borderRadius: 16,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        textStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authHeading,
                        ),
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.authMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.authMuted,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthFieldGroup(
                      label: 'CONFIRM PASSWORD',
                      labelStyle: textTheme.labelSmall?.copyWith(
                        color: AppColors.authMuted,
                        letterSpacing: 2,
                      ),
                      child: CoreTextField(
                        controller: _confirmPasswordController,
                        label: AppStrings.passwordReenterLabel,
                        hintText: AppStrings.passwordHint,
                        obscureText: !_isConfirmPasswordVisible,
                        useInlineLabel: false,
                        fillColor: AppColors.surfaceVariantDark,
                        enabledBorderColor: AppColors.borderOnDark,
                        focusedBorderColor: AppColors.authMint,
                        borderRadius: 16,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        textStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authHeading,
                        ),
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: AppColors.authMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                          color: AppColors.authMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.authMuted,
                          ),
                          onPressed: () => setState(
                            () => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      onTap: () {
                        setState(() {
                          _isTermsAccepted = !_isTermsAccepted;
                          _validateForm();
                        });
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _isTermsAccepted
                                  ? AppColors.authMint.withValues(alpha: 0.18)
                                  : AppColors.authCheckboxFill,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.sm,
                              ),
                              border: Border.all(
                                color: _isTermsAccepted
                                    ? AppColors.authMint
                                    : AppColors.borderOnDark,
                              ),
                            ),
                            child: _isTermsAccepted
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: AppColors.authMint,
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.authMuted,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.authMint,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.authMint
                                          .withValues(alpha: 0.2),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _openPolicyPage(
                                        path: ApiConstants.itrTermsAndConditions,
                                        title: 'Terms and Conditions',
                                      ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.authMint,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.authMint
                                          .withValues(alpha: 0.2),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _openPolicyPage(
                                        path: ApiConstants.itrPrivacyPolicy,
                                        title: 'Privacy Policy',
                                      ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryButton(
                      text: 'CREATE ACCOUNT',
                      borderRadius: 16,
                      isLoading: authState is AuthLoading,
                      minHeight: 60,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.authMint, AppColors.authMintDark],
                      ),
                      foregroundColor: AppColors.authButtonText,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D4EDEA3),
                          blurRadius: 40,
                          spreadRadius: -10,
                          offset: Offset(0, 20),
                        ),
                      ],
                      textStyle: textTheme.titleMedium?.copyWith(
                        color: AppColors.authButtonText,
                        fontWeight: FontWeight.w800,
                      ),
                      onPressed: (authState is AuthLoading || !_isFormValid)
                          ? null
                          : () {
                              if (_passwordController.text.trim() !=
                                  _confirmPasswordController.text.trim()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(AppStrings.passwordMismatch),
                                  ),
                                );
                                return;
                              }
                              AnalyticsService.logCtaClick(
                                ctaName:
                                    AnalyticsService.ctaSignupCreateAccount,
                                screenName: 'signup',
                              );
                              ref
                                  .read(authViewModelProvider.notifier)
                                  .register(
                                    _nameController.text.trim(),
                                    _mobileController.text.trim(),
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                            },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        children: [
                          Text(
                            AppStrings.alreadyHaveAccount,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.authMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              AnalyticsService.logCtaClick(
                                ctaName: AnalyticsService.ctaSignupGoToLogin,
                                screenName: 'signup',
                              );
                              context.go('/login');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.authHeading,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              AppStrings.loginAction,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.authHeading,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
