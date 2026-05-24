enum JourneyType {
  ITR,
  EVerify,
  GST,
  Loan;

  String get apiValue {
    switch (this) {
      case JourneyType.ITR:
        return 'ITR';
      case JourneyType.EVerify:
        return 'E-Verify';
      case JourneyType.GST:
        return 'GST';
      case JourneyType.Loan:
        return 'Loan';
    }
  }
}
