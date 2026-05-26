import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/features/tax_calculator/domain/entities/tax_calculator_models.dart';

final calculateIncomeTaxProvider = Provider<CalculateIncomeTax>((ref) {
  return const CalculateIncomeTax();
});

class CalculateIncomeTax {
  const CalculateIncomeTax();

  TaxCalculationResult call(TaxCalculatorInput input) {
    final rules = _resolveRules(input.financialYear, input.regime, input.ageGroup);
    final standardDeduction = input.isSalaried ? rules.standardDeduction : 0.0;
    final deductions = input.regime == TaxRegime.oldRegime ? input.deductions : 0.0;
    final taxableIncome =
        math.max(0.0, input.annualIncome - standardDeduction - deductions);

    final taxBeforeRebate = _calculateSlabTax(taxableIncome, rules.slabs);
    var rebate = 0.0;
    var marginalReliefApplied = false;

    if (input.isResident) {
      if (taxableIncome <= rules.rebateThreshold) {
        rebate = math.min(taxBeforeRebate, rules.rebateLimit).toDouble();
      } else if (rules.allowsMarginalRelief) {
        final excessIncome = taxableIncome - rules.rebateThreshold;
        if (taxBeforeRebate > excessIncome) {
          rebate =
              math.min(taxBeforeRebate - excessIncome, taxBeforeRebate).toDouble();
          marginalReliefApplied = rebate > 0;
        }
      }
    }

    final taxAfterRebate = math.max(0.0, taxBeforeRebate - rebate);
    final cess = taxAfterRebate * 0.04;
    final totalTax = taxAfterRebate + cess;

    return TaxCalculationResult(
      financialYear: input.financialYear,
      regime: input.regime,
      ageGroup: input.ageGroup,
      annualIncome: input.annualIncome,
      standardDeduction: standardDeduction,
      deductionsConsidered: deductions,
      taxableIncome: taxableIncome,
      taxBeforeRebate: taxBeforeRebate,
      rebate: rebate,
      taxAfterRebate: taxAfterRebate,
      cess: cess,
      totalTax: totalTax,
      netIncomeAfterTax: math.max(0.0, input.annualIncome - totalTax),
      marginalReliefApplied: marginalReliefApplied,
      note: _buildNote(input, rules, marginalReliefApplied),
    );
  }

  double _calculateSlabTax(double taxableIncome, List<_TaxSlab> slabs) {
    var totalTax = 0.0;

    for (final slab in slabs) {
      if (taxableIncome <= slab.start) {
        continue;
      }

      final upper = slab.end ?? taxableIncome;
      final taxablePortion = math.min(taxableIncome, upper) - slab.start;
      if (taxablePortion > 0) {
        totalTax += taxablePortion * slab.rate;
      }
    }

    return totalTax;
  }

  _TaxRuleSet _resolveRules(
    TaxFinancialYear year,
    TaxRegime regime,
    TaxAgeGroup ageGroup,
  ) {
    if (regime == TaxRegime.newRegime) {
      switch (year) {
        case TaxFinancialYear.fy2023_24:
          return const _TaxRuleSet(
            standardDeduction: 50000,
            rebateThreshold: 700000,
            rebateLimit: 25000,
            allowsMarginalRelief: true,
            slabs: [
              _TaxSlab(start: 0, end: 300000, rate: 0),
              _TaxSlab(start: 300000, end: 600000, rate: 0.05),
              _TaxSlab(start: 600000, end: 900000, rate: 0.10),
              _TaxSlab(start: 900000, end: 1200000, rate: 0.15),
              _TaxSlab(start: 1200000, end: 1500000, rate: 0.20),
              _TaxSlab(start: 1500000, end: null, rate: 0.30),
            ],
          );
        case TaxFinancialYear.fy2024_25:
          return const _TaxRuleSet(
            standardDeduction: 75000,
            rebateThreshold: 700000,
            rebateLimit: 25000,
            allowsMarginalRelief: true,
            slabs: [
              _TaxSlab(start: 0, end: 300000, rate: 0),
              _TaxSlab(start: 300000, end: 700000, rate: 0.05),
              _TaxSlab(start: 700000, end: 1000000, rate: 0.10),
              _TaxSlab(start: 1000000, end: 1200000, rate: 0.15),
              _TaxSlab(start: 1200000, end: 1500000, rate: 0.20),
              _TaxSlab(start: 1500000, end: null, rate: 0.30),
            ],
          );
        case TaxFinancialYear.fy2025_26:
          return const _TaxRuleSet(
            standardDeduction: 75000,
            rebateThreshold: 1200000,
            rebateLimit: 60000,
            allowsMarginalRelief: true,
            slabs: [
              _TaxSlab(start: 0, end: 400000, rate: 0),
              _TaxSlab(start: 400000, end: 800000, rate: 0.05),
              _TaxSlab(start: 800000, end: 1200000, rate: 0.10),
              _TaxSlab(start: 1200000, end: 1600000, rate: 0.15),
              _TaxSlab(start: 1600000, end: 2000000, rate: 0.20),
              _TaxSlab(start: 2000000, end: 2400000, rate: 0.25),
              _TaxSlab(start: 2400000, end: null, rate: 0.30),
            ],
          );
      }
    }

    switch (ageGroup) {
      case TaxAgeGroup.below60:
        return const _TaxRuleSet(
          standardDeduction: 50000,
          rebateThreshold: 500000,
          rebateLimit: 12500,
          allowsMarginalRelief: false,
          slabs: [
            _TaxSlab(start: 0, end: 250000, rate: 0),
            _TaxSlab(start: 250000, end: 500000, rate: 0.05),
            _TaxSlab(start: 500000, end: 1000000, rate: 0.20),
            _TaxSlab(start: 1000000, end: null, rate: 0.30),
          ],
        );
      case TaxAgeGroup.seniorCitizen:
        return const _TaxRuleSet(
          standardDeduction: 50000,
          rebateThreshold: 500000,
          rebateLimit: 12500,
          allowsMarginalRelief: false,
          slabs: [
            _TaxSlab(start: 0, end: 300000, rate: 0),
            _TaxSlab(start: 300000, end: 500000, rate: 0.05),
            _TaxSlab(start: 500000, end: 1000000, rate: 0.20),
            _TaxSlab(start: 1000000, end: null, rate: 0.30),
          ],
        );
      case TaxAgeGroup.superSeniorCitizen:
        return const _TaxRuleSet(
          standardDeduction: 50000,
          rebateThreshold: 500000,
          rebateLimit: 12500,
          allowsMarginalRelief: false,
          slabs: [
            _TaxSlab(start: 0, end: 500000, rate: 0),
            _TaxSlab(start: 500000, end: 1000000, rate: 0.20),
            _TaxSlab(start: 1000000, end: null, rate: 0.30),
          ],
        );
    }
  }

  String _buildNote(
    TaxCalculatorInput input,
    _TaxRuleSet rules,
    bool marginalReliefApplied,
  ) {
    final deductionNote = input.regime == TaxRegime.newRegime
        ? 'Other deductions are ignored in the new regime estimate.'
        : 'Old regime estimate includes the deductions you entered.';
    final marginalReliefNote = marginalReliefApplied
        ? 'Marginal relief has been applied near the Section 87A threshold.'
        : 'Health & education cess at 4% is included. Surcharge and special-rate income are excluded.';

    return '${input.financialYear.label} • ${rules.rebateThreshold.toInt()} rebate threshold • $deductionNote $marginalReliefNote';
  }
}

class _TaxRuleSet {
  final double standardDeduction;
  final double rebateThreshold;
  final double rebateLimit;
  final bool allowsMarginalRelief;
  final List<_TaxSlab> slabs;

  const _TaxRuleSet({
    required this.standardDeduction,
    required this.rebateThreshold,
    required this.rebateLimit,
    required this.allowsMarginalRelief,
    required this.slabs,
  });
}

class _TaxSlab {
  final double start;
  final double? end;
  final double rate;

  const _TaxSlab({
    required this.start,
    required this.end,
    required this.rate,
  });
}
