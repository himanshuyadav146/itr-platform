enum TaxRegime { newRegime, oldRegime }

enum TaxAgeGroup { below60, seniorCitizen, superSeniorCitizen }

enum TaxFinancialYear { fy2023_24, fy2024_25, fy2025_26 }

extension TaxRegimeX on TaxRegime {
  String get label => this == TaxRegime.newRegime ? 'New Regime' : 'Old Regime';

  TaxRegime get alternative =>
      this == TaxRegime.newRegime ? TaxRegime.oldRegime : TaxRegime.newRegime;
}

extension TaxAgeGroupX on TaxAgeGroup {
  String get label {
    switch (this) {
      case TaxAgeGroup.below60:
        return 'Below 60';
      case TaxAgeGroup.seniorCitizen:
        return '60-79 Years';
      case TaxAgeGroup.superSeniorCitizen:
        return '80+ Years';
    }
  }
}

extension TaxFinancialYearX on TaxFinancialYear {
  String get label {
    switch (this) {
      case TaxFinancialYear.fy2023_24:
        return '2023-24';
      case TaxFinancialYear.fy2024_25:
        return '2024-25';
      case TaxFinancialYear.fy2025_26:
        return '2025-26';
    }
  }
}

class TaxCalculatorInput {
  final TaxFinancialYear financialYear;
  final TaxRegime regime;
  final TaxAgeGroup ageGroup;
  final double annualIncome;
  final double deductions;
  final bool isSalaried;
  final bool isResident;

  const TaxCalculatorInput({
    required this.financialYear,
    required this.regime,
    required this.ageGroup,
    required this.annualIncome,
    required this.deductions,
    this.isSalaried = true,
    this.isResident = true,
  });

  TaxCalculatorInput copyWith({
    TaxFinancialYear? financialYear,
    TaxRegime? regime,
    TaxAgeGroup? ageGroup,
    double? annualIncome,
    double? deductions,
    bool? isSalaried,
    bool? isResident,
  }) {
    return TaxCalculatorInput(
      financialYear: financialYear ?? this.financialYear,
      regime: regime ?? this.regime,
      ageGroup: ageGroup ?? this.ageGroup,
      annualIncome: annualIncome ?? this.annualIncome,
      deductions: deductions ?? this.deductions,
      isSalaried: isSalaried ?? this.isSalaried,
      isResident: isResident ?? this.isResident,
    );
  }
}

class TaxCalculationResult {
  final TaxFinancialYear financialYear;
  final TaxRegime regime;
  final TaxAgeGroup ageGroup;
  final double annualIncome;
  final double standardDeduction;
  final double deductionsConsidered;
  final double taxableIncome;
  final double taxBeforeRebate;
  final double rebate;
  final double taxAfterRebate;
  final double cess;
  final double totalTax;
  final double netIncomeAfterTax;
  final bool marginalReliefApplied;
  final String note;

  const TaxCalculationResult({
    required this.financialYear,
    required this.regime,
    required this.ageGroup,
    required this.annualIncome,
    required this.standardDeduction,
    required this.deductionsConsidered,
    required this.taxableIncome,
    required this.taxBeforeRebate,
    required this.rebate,
    required this.taxAfterRebate,
    required this.cess,
    required this.totalTax,
    required this.netIncomeAfterTax,
    required this.marginalReliefApplied,
    required this.note,
  });
}
