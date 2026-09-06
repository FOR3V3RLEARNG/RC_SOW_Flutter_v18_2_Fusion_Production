enum AttendanceStatus { pending, present, halfDay, absent, excused }

extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.pending => 'Pending',
    AttendanceStatus.present => 'Present',
    AttendanceStatus.halfDay => 'Half day',
    AttendanceStatus.absent => 'Absent',
    AttendanceStatus.excused => 'Excused',
  };

  double get payableDay => switch (this) {
    AttendanceStatus.present => 1,
    AttendanceStatus.halfDay => .5,
    _ => 0,
  };

  bool get verifiedEligible => this != AttendanceStatus.pending;
}

class CrewAttendanceEntry {
  const CrewAttendanceEntry({
    required this.memberId,
    required this.memberName,
    required this.role,
    required this.status,
    required this.date,
    required this.verified,
  });

  final String memberId;
  final String memberName;
  final String role;
  final AttendanceStatus status;
  final DateTime date;
  final bool verified;

  double get payableDay => verified ? status.payableDay : 0;
}

class PaymentBreakdown {
  const PaymentBreakdown({
    required this.baseLabour,
    required this.demolitionAllowance,
    required this.additionalAllowance,
    required this.grossLabour,
    required this.attendanceDeductions,
    required this.adjustedPayment,
    required this.carpenterShare,
    required this.workerShare,
    required this.apprenticeShare,
  });

  final double baseLabour;
  final double demolitionAllowance;
  final double additionalAllowance;
  final double grossLabour;
  final double attendanceDeductions;
  final double adjustedPayment;
  final double carpenterShare;
  final double workerShare;
  final double apprenticeShare;
}

abstract final class RcPaymentRules {
  static const double ratePerSquare = 23000;
  static const double demolitionAllowance = 12000;
  static const double additionalAllowance = 6500;
  static const double carpenterPercent = .46;
  static const double workerPercent = .31;
  static const double apprenticePercent = .23;

  static PaymentBreakdown calculate({
    required double roofSquares,
    bool includeDemolition = false,
    bool includeAdditional = false,
    double attendanceDeductions = 0,
  }) {
    final base = roofSquares * ratePerSquare;
    final demolition = includeDemolition ? demolitionAllowance : 0.0;
    final additional = includeAdditional ? additionalAllowance : 0.0;
    final gross = base + demolition + additional;
    final adjusted = (gross - attendanceDeductions)
        .clamp(0.0, double.infinity)
        .toDouble();
    return PaymentBreakdown(
      baseLabour: base,
      demolitionAllowance: demolition,
      additionalAllowance: additional,
      grossLabour: gross,
      attendanceDeductions: attendanceDeductions,
      adjustedPayment: adjusted,
      carpenterShare: adjusted * carpenterPercent,
      workerShare: adjusted * workerPercent,
      apprenticeShare: adjusted * apprenticePercent,
    );
  }
}
