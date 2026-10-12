import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/responsive_grid.dart';
import 'package:tax_client/core/common/widgets/core_text_field.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/tax_calculator/domain/entities/tax_calculator_models.dart';
import 'package:tax_client/features/tax_calculator/presentation/providers/tax_calculator_provider.dart';

class TaxCalculatorScreen extends ConsumerStatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  ConsumerState<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends ConsumerState<TaxCalculatorScreen> {
  late final TextEditingController _annualIncomeController;
  late final TextEditingController _deductionsController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(taxCalculatorProvider);
    _annualIncomeController = TextEditingController(text: state.annualIncomeText);
    _deductionsController = TextEditingController(text: state.deductionsText);
  }

  @override
  void dispose() {
    _annualIncomeController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(taxCalculatorProvider);
    final notifier = ref.read(taxCalculatorProvider.notifier);
    final result = state.result;
    final alternate = state.alternateResult;

    return CoreScaffold(
      title: 'Income Tax Calculator',
      showBackButton: true,
      centered: true,
      useResponsiveMaxWidth: true,
      maxContentWidth: 560,
      useScrollView: true,
      backgroundColor: AppColors.authBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalculatorHeroCard(
            title: 'Estimate your tax before filing.',
            subtitle:
                'Built for resident individuals. Includes standard deduction and 4% cess, but excludes surcharge and special-rate income.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _CalculatorSectionTitle(
            title: 'Calculator Inputs',
            subtitle: 'Use current slabs and compare regimes instantly.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<TaxFinancialYear>(
                  value: state.input.financialYear,
                  dropdownColor: AppColors.brandNavyLight,
                  decoration: _fieldDecoration(
                    theme,
                    label: 'Financial Year',
                  ),
                  items: TaxFinancialYear.values
                      .map(
                        (year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    notifier.updateFinancialYear(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _SegmentedTaxSelector<TaxRegime>(
                  label: 'Tax Regime',
                  value: state.input.regime,
                  options: TaxRegime.values,
                  optionLabel: (value) => value.label,
                  onChanged: notifier.updateRegime,
                ),
                const SizedBox(height: AppSpacing.md),
                _SegmentedTaxSelector<TaxAgeGroup>(
                  label: 'Age Group',
                  value: state.input.ageGroup,
                  options: TaxAgeGroup.values,
                  optionLabel: (value) => value.label,
                  onChanged: notifier.updateAgeGroup,
                ),
                const SizedBox(height: AppSpacing.md),
                CoreTextField(
                  controller: _annualIncomeController,
                  label: 'Gross Annual Income',
                  hintText: 'e.g. 1200000',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: notifier.updateAnnualIncome,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  fillColor: AppColors.surfaceVariantDark.withValues(alpha: 0.55),
                  enabledBorderColor: AppColors.borderOnDark,
                  focusedBorderColor: AppColors.authMint,
                  textStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.authHeading,
                  ),
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.authPlaceholder,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CoreTextField(
                  controller: _deductionsController,
                  label: 'Eligible Deductions / Exemptions',
                  hintText: state.input.regime == TaxRegime.oldRegime
                      ? '80C + 80D + HRA + home loan, etc.'
                      : 'Ignored in the new regime estimate',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: notifier.updateDeductions,
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  fillColor: AppColors.surfaceVariantDark.withValues(alpha: 0.55),
                  enabledBorderColor: AppColors.borderOnDark,
                  focusedBorderColor: AppColors.authMint,
                  textStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.authHeading,
                  ),
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.authPlaceholder,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.input.regime == TaxRegime.oldRegime
                      ? 'Old regime uses your deduction input plus standard deduction for salaried individuals.'
                      : 'New regime ignores most deductions here and applies only the standard deduction for salaried individuals.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.authMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  text: 'CALCULATE TAX',
                  onPressed: state.canCalculate ? notifier.calculate : null,
                  minHeight: 56,
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.authMint.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (result != null) ...[
            _CalculatorSectionTitle(
              title: 'Estimated Tax',
              subtitle: 'Based on ${result.regime.label} for FY ${result.financialYear.label}.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _ResultSummaryCard(result: result),
            const SizedBox(height: AppSpacing.lg),
            ResponsiveWrapGrid(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              phoneColumns: 2,
              tabletColumns: 2,
              wideColumns: 4,
              children: [
                _BreakdownTile(
                  label: 'Taxable Income',
                  value: _formatCurrency(result.taxableIncome),
                  accent: AppColors.authMint,
                ),
                _BreakdownTile(
                  label: 'Tax Before Rebate',
                  value: _formatCurrency(result.taxBeforeRebate),
                  accent: AppColors.authHeading,
                ),
                _BreakdownTile(
                  label: 'Rebate / Relief',
                  value: _formatCurrency(result.rebate),
                  accent: AppColors.authAmber,
                ),
                _BreakdownTile(
                  label: 'Cess (4%)',
                  value: _formatCurrency(result.cess),
                  accent: AppColors.authMintDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _NoteCard(note: result.note),
            if (alternate != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _CalculatorSectionTitle(
                title: 'Regime Comparison',
                subtitle: _comparisonLine(result, alternate),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ComparisonCard(
                primary: result,
                alternate: alternate,
              ),
            ],
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(ThemeData theme, {required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.authMuted,
      ),
      filled: true,
      fillColor: AppColors.surfaceVariantDark.withValues(alpha: 0.55),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide(color: AppColors.borderOnDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide(color: AppColors.authMint),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    );
  }

  String _comparisonLine(
    TaxCalculationResult current,
    TaxCalculationResult alternate,
  ) {
    final savings = (alternate.totalTax - current.totalTax).abs();
    final better = current.totalTax <= alternate.totalTax ? current : alternate;
    final worse = identical(better, current) ? alternate : current;

    if (savings < 1) {
      return 'Both regimes are nearly identical for these inputs.';
    }

    return '${better.regime.label} saves ${_formatCurrency(savings)} versus ${worse.regime.label}.';
  }
}

class _CalculatorHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CalculatorHeroCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.authCardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CalculatorSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
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
          ),
        ),
      ],
    );
  }
}

class _SegmentedTaxSelector<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onChanged;

  const _SegmentedTaxSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.authMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((option) {
            final isSelected = option == value;
            return ChoiceChip(
              label: Text(optionLabel(option)),
              selected: isSelected,
              onSelected: (_) => onChanged(option),
              selectedColor: AppColors.authMint.withValues(alpha: 0.18),
              backgroundColor: AppColors.surfaceVariantDark.withValues(alpha: 0.55),
              side: BorderSide(
                color: isSelected ? AppColors.authMint : AppColors.borderOnDark,
              ),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.authHeading : AppColors.authMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.borderOnDark),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            spreadRadius: -8,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  final TaxCalculationResult result;

  const _ResultSummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated annual tax',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _formatCurrency(result.totalTax),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Net income after tax: ${_formatCurrency(result.netIncomeAfterTax)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authMint,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Monthly equivalent tax: ${_formatCurrency(result.totalTax / 12)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _BreakdownTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.authMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final TaxCalculationResult primary;
  final TaxCalculationResult alternate;

  const _ComparisonCard({
    required this.primary,
    required this.alternate,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          _ComparisonRow(result: primary, highlight: true),
          const SizedBox(height: AppSpacing.md),
          _ComparisonRow(result: alternate),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final TaxCalculationResult result;
  final bool highlight;

  const _ComparisonRow({
    required this.result,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.authMint.withValues(alpha: 0.10)
            : AppColors.surfaceVariantDark.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result.regime.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatCurrency(result.totalTax),
            style: theme.textTheme.titleMedium?.copyWith(
              color: highlight ? AppColors.authMint : AppColors.authHeading,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.authAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.authAmber.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        note,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.authMuted,
          height: 1.45,
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  return formatter.format(value);
}
