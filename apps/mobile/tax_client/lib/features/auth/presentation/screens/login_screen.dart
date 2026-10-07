import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_client/core/common/widgets/app_logo.dart';
import 'package:tax_client/core/common/widgets/auth_scaffold.dart';
import 'package:tax_client/core/common/widgets/core_text_field.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/services/analytics/analytics_service.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isFormValid = false;
  bool _isPasswordVisible = false;
  bool _rememberSession = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _emailController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final textTheme = Theme.of(context).textTheme;

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setBool('logged_in', true),
        );
        context.go('/');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    return AuthScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AuthBrandLockup(),
                    SizedBox(height: isCompact ? AppSpacing.lg : AppSpacing.xl),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Welcome',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.authHeading,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                        textAlign: TextAlign.center,
                        AppStrings.loginSubtitle,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.authMuted,
                        ),
                      ),
                    SizedBox(height: isCompact ? AppSpacing.xl : AppSpacing.xxxl),
                    AuthFieldHeader(
                      label: 'EMAIL ADDRESS',
                      labelStyle: textTheme.labelMedium?.copyWith(
                        color: AppColors.authMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CoreTextField(
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
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthFieldHeader(
                      label: 'PASSWORD',
                      labelStyle: textTheme.labelMedium?.copyWith(
                        color: AppColors.authMuted,
                        letterSpacing: 1.2,
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          AnalyticsService.logCtaClick(
                            ctaName: AnalyticsService.ctaLoginForgotPassword,
                            screenName: 'login',
                          );
                          context.push('/forgot-password');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.authAmber,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.forgotPassword,
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.authAmber,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CoreTextField(
                      controller: _passwordController,
                      label: AppStrings.passwordLabel,
                      hintText: AppStrings.passwordHint,
                      obscureText: !_isPasswordVisible,
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
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.authMuted,
                        ),
                        onPressed: () {
                          setState(() => _isPasswordVisible = !_isPasswordVisible);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      onTap: () {
                        setState(() => _rememberSession = !_rememberSession);
                      },
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _rememberSession
                                  ? AppColors.authMint.withValues(alpha: 0.18)
                                  : AppColors.authCheckboxFill,
                              borderRadius: BorderRadius.circular(AppSpacing.xs),
                              border: Border.all(
                                color: _rememberSession
                                    ? AppColors.authMint
                                    : AppColors.authCheckboxBorder,
                              ),
                            ),
                            child: _rememberSession
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: AppColors.authMint,
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Remember this session',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.authMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      text: 'AUTHENTICATE',
                      borderRadius: AppSpacing.radiusPill,
                      isLoading: authState is AuthLoading,
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
                      onPressed: (authState is AuthLoading || !_isFormValid)
                          ? null
                          : () {
                              AnalyticsService.logCtaClick(
                                ctaName: AnalyticsService.ctaLoginAuthenticate,
                                screenName: 'login',
                              );
                              ref.read(authViewModelProvider.notifier).login(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                            },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      height: 1,
                      color: AppColors.authCheckboxBorder.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        children: [
                          Text(
                            AppStrings.signupPrompt,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.authMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () {
                              AnalyticsService.logCtaClick(
                                ctaName: AnalyticsService.ctaLoginGoToSignup,
                                screenName: 'login',
                              );
                              context.push('/register');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.authMint,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              AppStrings.signupAction,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.authMint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthTrustBadge(
                    icon: Icons.shield_outlined,
                    label: 'AES-256 ENABLED',
                  ),
                  SizedBox(width: AppSpacing.lg),
                  AuthTrustBadge(
                    icon: Icons.verified_user_outlined,
                    label: 'TRUSTED PLATFORM',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuthBrandLockup extends StatelessWidget {
  const _AuthBrandLockup();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.center,
      child: AppLogo(
        height: 76,
        width: 76,
      ),
    );
  }
}

