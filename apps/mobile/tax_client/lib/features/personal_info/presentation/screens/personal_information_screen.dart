import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_text_field.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/constant/app_constants.dart';
import 'package:tax_client/core/utils/field_validators.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Populate fields from passed ITR data if available
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
      // Only set dropdown values if they exist in options; otherwise keep defaults
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
      // Get selected package if available
      final selectedPackage = ref.read(selectedPackageProvider);

      // Get selected journey type
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
            journeyType: journeyType.apiValue, // Use the apiValue getter
            packageId: selectedPackage?.id != null
                ? int.tryParse(selectedPackage!.id)
                : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Optimize: Use select to watch only loading state
    final isLoading = ref.watch(
      personalInfoViewModelProvider.select(
        (state) => state is PersonalInfoLoading,
      ),
    );

    // Listen to state changes for navigation and feedback
    ref.listen<PersonalInfoState>(personalInfoViewModelProvider, (
      previous,
      next,
    ) {
      if (next is PersonalInfoSuccess) {
        ErrorHandler.showSuccess(context, next.message);
        // Navigate to document upload on success
        GoRouter.of(context).push('/document_upload');
      } else if (next is PersonalInfoError) {
        ErrorHandler.showError(context, next.message);
      }
    });

    return CoreScaffold(
      title: AppStrings.personalInfo,
      // Sticky bottom Save button
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: SizedBox(
          height: 56,
          child: PrimaryButton(
            text: AppStrings.save,
            onPressed: isLoading ? () {} : _handleSave,
            isLoading: isLoading,
          ),
        ),
      ),
      useScrollView: true,
      useResponsiveMaxWidth: true,
      responsiveBreakpoint: 600,
      maxContentWidth: 480,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.enterDetails,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            CoreTextField(
              controller: _firstNameController,
              label: AppStrings.firstName,
              keyboardType: TextInputType.name,
              prefixIcon: const Icon(Icons.person_outline),
              validator: FieldValidators.validateFirstName,
            ),
            const SizedBox(height: 16),

            CoreTextField(
              controller: _middleNameController,
              label: AppStrings.middleName,
              keyboardType: TextInputType.name,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),

            CoreTextField(
              controller: _lastNameController,
              label: AppStrings.lastName,
              keyboardType: TextInputType.name,
              prefixIcon: const Icon(Icons.person_outline),
              validator: FieldValidators.validateLastName,
            ),
            const SizedBox(height: 16),

            CoreTextField(
              controller: _phoneController,
              label: AppStrings.phoneNumber,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: FieldValidators.validatePhoneNumber,
            ),
            const SizedBox(height: 16),

            CoreTextField(
              controller: _emailController,
              label: AppStrings.emailIdLabel,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: FieldValidators.validateEmail,
            ),
            const SizedBox(height: 16),

            CoreTextField(
              controller: _panController,
              label: AppStrings.panNumber,
              keyboardType: TextInputType.text,
              prefixIcon: const Icon(Icons.badge_outlined),
              validator: FieldValidators.validatePAN,
            ),
            const SizedBox(height: 16),

            CoreTextField(
              controller: _aadharController,
              label: AppStrings.aadharNumber,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.credit_card_outlined),
              validator: FieldValidators.validateAadhaar,
            ),
            const SizedBox(height: 16),

            // Gender Dropdown (ensure value is always in the options list)
            DropdownButtonFormField<String>(
              value: AppConstants.genderOptions.contains(_selectedGender)
                  ? _selectedGender
                  : AppConstants.defaultGender,
              decoration: InputDecoration(
                labelText: AppStrings.gender,
                prefixIcon: const Icon(Icons.wc_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: AppConstants.genderOptions.map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
            ),
            const SizedBox(height: 16),

            // Financial Year Dropdown (ensure value is always in the options list)
            DropdownButtonFormField<String>(
              value:
                  AppConstants.financialYearOptions.contains(
                    _selectedFinancialYear,
                  )
                  ? _selectedFinancialYear
                  : AppConstants.defaultFinancialYear,
              decoration: InputDecoration(
                labelText: AppStrings.financialYear,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: AppConstants.financialYearOptions.map((year) {
                return DropdownMenuItem(value: year, child: Text(year));
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedFinancialYear = value!;
                      });
                    },
            ),
            const SizedBox(height: 16),

            // Country Dropdown (ensure value is always in the options list)
            DropdownButtonFormField<String>(
              value: AppConstants.countryOptions.contains(_selectedCountry)
                  ? _selectedCountry
                  : AppConstants.defaultCountry,
              decoration: InputDecoration(
                labelText: AppStrings.country,
                prefixIcon: const Icon(Icons.public_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: AppConstants.countryOptions.map((country) {
                return DropdownMenuItem(value: country, child: Text(country));
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCountry = value!;
                      });
                    },
            ),
            const SizedBox(height: 16),

            CoreTextField(
              controller: _addressController,
              label: AppStrings.address,
              keyboardType: TextInputType.streetAddress,
              prefixIcon: const Icon(Icons.location_on_outlined),
              maxLines: 3,
              validator: FieldValidators.validateAddress,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
