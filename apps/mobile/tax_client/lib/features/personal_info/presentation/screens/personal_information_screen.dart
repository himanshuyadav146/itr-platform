import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/core_text_field.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/constant/app_constants.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/core/utils/field_validators.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  final ItrPersonalDetailModel? itrData;

  const PersonalInformationScreen({super.key, this.itrData});

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedGender = AppConstants.defaultGender;
  String _selectedFinancialYear = AppConstants.defaultFinancialYear;
  String _selectedCountry = AppConstants.defaultCountry;

  Color get _fieldFillColor =>
      AppColors.surfaceVariantDark.withValues(alpha: 0.4);
  Color get _fieldBorderColor => AppColors.borderOnDark.withValues(alpha: 0.9);

  @override
  void initState() {
    super.initState();
    if (widget.itrData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateFieldsFromItrData(widget.itrData!);
      });
    }
  }

  void _populateFieldsFromItrData(ItrPersonalDetailModel itrData) {
    setState(() {
      _firstNameController.text = itrData.firstName;
      _middleNameController.text = itrData.middleName ?? '';
      _lastNameController.text = itrData.lastName;
      _phoneController.text = itrData.mobileNumber;
      _emailController.text = itrData.email;
      _panController.text = itrData.panNumber;
      _aadharController.text = itrData.aadharCardNumber;
      _addressController.text = itrData.address;
      _selectedGender =
          AppConstants.genderOptions.contains(itrData.gender.trim())
          ? itrData.gender.trim()
          : AppConstants.defaultGender;
      _selectedFinancialYear =
          AppConstants.financialYearOptions.contains(
            itrData.financialYear.trim(),
          )
          ? itrData.financialYear.trim()
          : AppConstants.defaultFinancialYear;
      _selectedCountry =
          AppConstants.countryOptions.contains(itrData.country.trim())
          ? itrData.country.trim()
          : AppConstants.defaultCountry;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _panController.dispose();
    _aadharController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final selectedPackage = ref.read(selectedPackageProvider);
      final journeyType = ref.read(journeyTypeProvider);

      ref
          .read(personalInfoViewModelProvider.notifier)
          .addPersonalDetails(
            panNumber: _panController.text.trim(),
            firstName: _firstNameController.text.trim(),
            middleName: _middleNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            mobileNumber: _phoneController.text.trim(),
            aadhaarCardNumber: _aadharController.text.trim(),
            gender: _selectedGender,
            financialYear: _selectedFinancialYear,
            address: _addressController.text.trim(),
            country: _selectedCountry,
            journeyType: journeyType.apiValue,
            packageId: selectedPackage?.id != null
                ? int.tryParse(selectedPackage!.id)
                : null,
          );
    }
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required Widget prefixIcon,
    required bool isLoading,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? minLines,
    TextInputAction? textInputAction,
  }) {
    final theme = Theme.of(context);

    return CoreTextField(
      controller: controller,
      label: label,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      textInputAction: textInputAction,
      fillColor: _fieldFillColor,
      enabledBorderColor: _fieldBorderColor,
      focusedBorderColor: AppColors.authMint,
      borderRadius: AppSpacing.radiusLg,
      textStyle: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.authHeading,
      ),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.authMutedSoft,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      onChanged: isLoading ? (_) {} : null,
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required Widget prefixIcon,
    required String selectedValue,
    required List<String> options,
    required bool isLoading,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final effectiveValue = options.contains(selectedValue)
        ? selectedValue
        : options.first;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      dropdownColor: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.authHeading),
      iconEnabledColor: AppColors.authMuted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: _fieldFillColor,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.authMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: _fieldBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: _fieldBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.authMint, width: 1.5),
        ),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: isLoading ? null : onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedPackage = ref.watch(selectedPackageProvider);
    final isLoading = ref.watch(
      personalInfoViewModelProvider.select(
        (state) => state is PersonalInfoLoading,
      ),
    );
    final isEditingExisting = widget.itrData != null;
    final packageName =
        selectedPackage?.name ??
        widget.itrData?.packageName ??
        'Package will be attached before submission';

    ref.listen<PersonalInfoState>(personalInfoViewModelProvider, (
      previous,
      next,
    ) {
      if (next is PersonalInfoSuccess) {
        ErrorHandler.showSuccess(context, next.message);
        GoRouter.of(context).push('/document_upload');
      } else if (next is PersonalInfoError) {
        ErrorHandler.showError(context, next.message);
      }
    });

    return CoreScaffold(
      includeAppBar: false,
      backgroundColor: AppColors.authBackground,
      useScrollView: true,
      centered: true,
      useResponsiveMaxWidth: true,
      responsiveBreakpoint: 600,
      maxContentWidth: 560,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: SizedBox(
          height: 56,
          child: PrimaryButton(
            text: 'SAVE & CONTINUE',
            onPressed: isLoading ? null : _handleSave,
            isLoading: isLoading,
            borderRadius: AppSpacing.radiusPill,
            foregroundColor: AppColors.authButtonText,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.authMint, AppColors.authMintDark],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334EDEA3),
                blurRadius: 20,
                spreadRadius: -6,
                offset: Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PersonalInfoHeader(
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            _PersonalInfoHeroCard(
              packageName: packageName,
              financialYear: _selectedFinancialYear,
              isEditingExisting: isEditingExisting,
            ),
            const SizedBox(height: AppSpacing.xl),
            _PersonalInfoSectionCard(
              title: 'Personal details',
              subtitle:
                  'Use your legal name exactly as it should appear on the return.',
              child: Column(
                children: [
                  _buildTextField(
                    context: context,
                    controller: _firstNameController,
                    label: AppStrings.firstName,
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    validator: FieldValidators.validateFirstName,
                    isLoading: isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    context: context,
                    controller: _middleNameController,
                    label: AppStrings.middleName,
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    isLoading: isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    context: context,
                    controller: _lastNameController,
                    label: AppStrings.lastName,
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    validator: FieldValidators.validateLastName,
                    isLoading: isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PersonalInfoSectionCard(
              title: 'Contact and identity',
              subtitle:
                  'These details help us validate your filing and keep updates in sync.',
              child: Column(
                children: [
                  _buildTextField(
                    context: context,
                    controller: _phoneController,
                    label: AppStrings.phoneNumber,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: FieldValidators.validatePhoneNumber,
                    isLoading: isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    context: context,
                    controller: _emailController,
                    label: AppStrings.emailIdLabel,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: FieldValidators.validateEmail,
                    isLoading: isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    context: context,
                    controller: _panController,
                    label: AppStrings.panNumber,
                    keyboardType: TextInputType.text,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    validator: FieldValidators.validatePAN,
                    isLoading: isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    context: context,
                    controller: _aadharController,
                    label: AppStrings.aadharNumber,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.credit_card_outlined),
                    validator: FieldValidators.validateAadhaar,
                    isLoading: isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PersonalInfoSectionCard(
              title: 'Filing preferences',
              subtitle:
                  'Choose the filing details that should be used for this return.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedPackage != null ||
                      widget.itrData?.packageName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.authMint.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: AppColors.authMint.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.authMint,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Selected package: $packageName',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.authHeading,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildDropdownField(
                    context: context,
                    label: AppStrings.gender,
                    prefixIcon: const Icon(Icons.wc_outlined),
                    selectedValue: _selectedGender,
                    options: AppConstants.genderOptions,
                    isLoading: isLoading,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDropdownField(
                    context: context,
                    label: AppStrings.financialYear,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    selectedValue: _selectedFinancialYear,
                    options: AppConstants.financialYearOptions,
                    isLoading: isLoading,
                    onChanged: (value) {
                      setState(() {
                        _selectedFinancialYear = value!;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDropdownField(
                    context: context,
                    label: AppStrings.country,
                    prefixIcon: const Icon(Icons.public_outlined),
                    selectedValue: _selectedCountry,
                    options: AppConstants.countryOptions,
                    isLoading: isLoading,
                    onChanged: (value) {
                      setState(() {
                        _selectedCountry = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PersonalInfoSectionCard(
              title: 'Address',
              subtitle:
                  'Enter the address you want associated with this filing.',
              child: _buildTextField(
                context: context,
                controller: _addressController,
                label: AppStrings.address,
                keyboardType: TextInputType.streetAddress,
                prefixIcon: const Icon(Icons.location_on_outlined),
                maxLines: 4,
                minLines: 3,
                validator: FieldValidators.validateAddress,
                isLoading: isLoading,
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'We use these details only for tax filing, compliance, and secure communication about your return.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.authMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalInfoHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _PersonalInfoHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariantDark,
            foregroundColor: AppColors.authHeading,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.personalInfo,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.authHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Complete your profile to continue the filing workflow.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.authMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonalInfoHeroCard extends StatelessWidget {
  final String packageName;
  final String financialYear;
  final bool isEditingExisting;

  const _PersonalInfoHeroCard({
    required this.packageName,
    required this.financialYear,
    required this.isEditingExisting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: AppColors.authCardSurface,
      border: Border.all(color: AppColors.authCardBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditingExisting
                ? 'Review and update your saved profile'
                : 'Tell us about the filer',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'We will use these details to prepare the return, validate identity, and carry the filing to the next step.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _PersonalInfoChip(
                icon: Icons.inventory_2_outlined,
                label: packageName,
                accent: AppColors.authMint,
              ),
              _PersonalInfoChip(
                icon: Icons.calendar_today_outlined,
                label: financialYear,
                accent: AppColors.authAmber,
              ),
              _PersonalInfoChip(
                icon: isEditingExisting
                    ? Icons.restore_page_outlined
                    : Icons.edit_note_outlined,
                label: isEditingExisting ? 'Existing record' : 'New filing',
                accent: AppColors.authHeading,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PersonalInfoSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: const Color(0x08FFFFFF),
      border: Border.all(color: AppColors.borderOnDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _PersonalInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _PersonalInfoChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
