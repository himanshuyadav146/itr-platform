import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/features/tax_calculator/domain/entities/tax_calculator_models.dart';
import 'package:tax_client/features/tax_calculator/domain/usecases/calculate_income_tax.dart';

final taxCalculatorProvider =
    StateNotifierProvider<TaxCalculatorNotifier, TaxCalculatorState>((ref) {
  return TaxCalculatorNotifier(ref.read(calculateIncomeTaxProvider));
});

class TaxCalculatorState {
  final TaxCalculatorInput input;
  final String annualIncomeText;
  final String deductionsText;
  final TaxCalculationResult? result;
  final TaxCalculationResult? alternateResult;

  const TaxCalculatorState({
    required this.input,
    required this.annualIncomeText,
    required this.deductionsText,
    this.result,
    this.alternateResult,
  });

  factory TaxCalculatorState.initial() {
    const input = TaxCalculatorInput(
      financialYear: TaxFinancialYear.fy2025_26,
      regime: TaxRegime.newRegime,
      ageGroup: TaxAgeGroup.below60,
      annualIncome: 0,
      deductions: 0,
    );

    return const TaxCalculatorState(
      input: input,
      annualIncomeText: '',
      deductionsText: '',
    );
  }

  TaxCalculatorState copyWith({
    TaxCalculatorInput? input,
    String? annualIncomeText,
    String? deductionsText,
    TaxCalculationResult? result,
    TaxCalculationResult? alternateResult,
    bool clearResult = false,
  }) {
    return TaxCalculatorState(
      input: input ?? this.input,
      annualIncomeText: annualIncomeText ?? this.annualIncomeText,
      deductionsText: deductionsText ?? this.deductionsText,
      result: clearResult ? null : (result ?? this.result),
      alternateResult:
          clearResult ? null : (alternateResult ?? this.alternateResult),
    );
  }

  bool get canCalculate => input.annualIncome > 0;
}

class TaxCalculatorNotifier extends StateNotifier<TaxCalculatorState> {
  final CalculateIncomeTax _calculateIncomeTax;

  TaxCalculatorNotifier(this._calculateIncomeTax)
      : super(TaxCalculatorState.initial());

  void updateFinancialYear(TaxFinancialYear year) {
    state = state.copyWith(
      input: state.input.copyWith(financialYear: year),
      clearResult: true,
    );
  }

  void updateRegime(TaxRegime regime) {
    state = state.copyWith(
      input: state.input.copyWith(regime: regime),
      clearResult: true,
    );
  }

  void updateAgeGroup(TaxAgeGroup ageGroup) {
    state = state.copyWith(
      input: state.input.copyWith(ageGroup: ageGroup),
      clearResult: true,
    );
  }

  void updateAnnualIncome(String value) {
    state = state.copyWith(
      annualIncomeText: value,
      input: state.input.copyWith(annualIncome: _parseCurrency(value)),
      clearResult: true,
    );
  }

  void updateDeductions(String value) {
    state = state.copyWith(
      deductionsText: value,
      input: state.input.copyWith(deductions: _parseCurrency(value)),
      clearResult: true,
    );
  }

  void calculate() {
    if (!state.canCalculate) {
      state = state.copyWith(clearResult: true);
      return;
    }

    final result = _calculateIncomeTax(state.input);
    final alternate = _calculateIncomeTax(
      state.input.copyWith(regime: state.input.regime.alternative),
    );

    state = state.copyWith(
      result: result,
      alternateResult: alternate,
    );
  }

  double _parseCurrency(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return 0;
    }

    return double.tryParse(normalized) ?? 0;
  }
}
