import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/auth_scaffold.dart';
import 'package:tax_client/core/common/widgets/core_text_field.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
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
        title: const Text(AppStrings.resetPassword),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: AppStrings.resetYourPassword,
              subtitle: AppStrings.enterEmailAndNewPassword,
              logoHeight: 120,
            ),
            const SizedBox(height: 32),
            AuthFormCard(
              child: Column(
                children: [
                  CoreTextField(
                    controller: _emailController,
                    label: AppStrings.emailLabel,
                    hintText: AppStrings.emailHint,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                    validator: FieldValidators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  CoreTextField(
                    controller: _passwordController,
                    label: AppStrings.newPassword,
                    hintText: AppStrings.enterNewPassword,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                  const SizedBox(height: 16),
                  CoreTextField(
                    controller: _confirmPasswordController,
                    label: AppStrings.confirmPassword,
                    hintText: AppStrings.reEnterNewPassword,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.pleaseConfirmYourPassword;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: AppStrings.resetPassword,
                    borderRadius: 16,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handleForgetPassword,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
