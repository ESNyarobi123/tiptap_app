num _pNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}

/// Salary slip summary returned by GET /api/waiter/salary-slips
class SalarySlipSummary {
  final String periodMonth;
  final String periodLabel;
  final num netPay;
  final String? viewUrl;
  final String? downloadUrl;
  final String? apiDownloadPath;

  SalarySlipSummary({
    required this.periodMonth,
    required this.periodLabel,
    required this.netPay,
    this.viewUrl,
    this.downloadUrl,
    this.apiDownloadPath,
  });

  factory SalarySlipSummary.fromJson(Map<String, dynamic> json) {
    return SalarySlipSummary(
      periodMonth: json['period_month'] as String? ?? '',
      periodLabel: json['period_label'] as String? ?? '',
      netPay: _pNum(json['net_pay']),
      viewUrl: json['view_url'] as String?,
      downloadUrl: json['download_url'] as String?,
      apiDownloadPath: json['api_download_path'] as String?,
    );
  }
}

/// Full salary slip detail returned by GET /api/waiter/salary-slips/{period}
class SalarySlipDetail {
  final String periodMonth;
  final String periodLabel;
  final String? restaurantName;
  final String? waiterName;
  final String? waiterId;
  final num basicSalary;
  final num allowances;
  final num grossSalary;
  final num paye;
  final num nssf;
  final num totalDeduction;
  final num netPay;
  final String? paidAt;
  final String? viewUrl;
  final String? downloadUrl;
  final String? apiDownloadPath;

  SalarySlipDetail({
    required this.periodMonth,
    required this.periodLabel,
    this.restaurantName,
    this.waiterName,
    this.waiterId,
    required this.basicSalary,
    required this.allowances,
    required this.grossSalary,
    required this.paye,
    required this.nssf,
    required this.totalDeduction,
    required this.netPay,
    this.paidAt,
    this.viewUrl,
    this.downloadUrl,
    this.apiDownloadPath,
  });

  factory SalarySlipDetail.fromJson(Map<String, dynamic> json) {
    return SalarySlipDetail(
      periodMonth: json['period_month'] as String? ?? '',
      periodLabel: json['period_label'] as String? ?? '',
      restaurantName: json['restaurant_name'] as String?,
      waiterName: json['waiter_name'] as String?,
      waiterId: json['waiter_id'] as String?,
      basicSalary: _pNum(json['basic_salary']),
      allowances: _pNum(json['allowances']),
      grossSalary: _pNum(json['gross_salary']),
      paye: _pNum(json['paye']),
      nssf: _pNum(json['nssf']),
      totalDeduction: _pNum(json['total_deduction']),
      netPay: _pNum(json['net_pay']),
      paidAt: json['paid_at'] as String?,
      viewUrl: json['view_url'] as String?,
      downloadUrl: json['download_url'] as String?,
      apiDownloadPath: json['api_download_path'] as String?,
    );
  }
}

/// Work history entry returned by GET /api/waiter/history
class WorkHistoryEntry {
  final int id;
  final int restaurantId;
  final String? restaurantName;
  final String? restaurantLocation;
  final String? restaurantPhone;
  final String? employmentType;
  final String? linkedUntil;
  final String? linkedAt;
  final String? unlinkedAt;
  final bool isActive;

  WorkHistoryEntry({
    required this.id,
    required this.restaurantId,
    this.restaurantName,
    this.restaurantLocation,
    this.restaurantPhone,
    this.employmentType,
    this.linkedUntil,
    this.linkedAt,
    this.unlinkedAt,
    required this.isActive,
  });

  factory WorkHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkHistoryEntry(
      id: json['id'] as int? ?? 0,
      restaurantId: json['restaurant_id'] as int? ?? 0,
      restaurantName: json['restaurant_name'] as String?,
      restaurantLocation: json['restaurant_location'] as String?,
      restaurantPhone: json['restaurant_phone'] as String?,
      employmentType: json['employment_type'] as String?,
      linkedUntil: json['linked_until'] as String?,
      linkedAt: json['linked_at'] as String?,
      unlinkedAt: json['unlinked_at'] as String?,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}
