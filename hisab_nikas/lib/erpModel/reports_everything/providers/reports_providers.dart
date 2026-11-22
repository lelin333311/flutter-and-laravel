import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/day_wise_report_model.dart';
import '../services/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

class ReportFilterQuery {
  final String period;
  final DateTime? customDate;
  final DateTimeRange? customRange;

  const ReportFilterQuery({
    this.period = 'this_month',
    this.customDate,
    this.customRange,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportFilterQuery &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          customDate == other.customDate &&
          customRange == other.customRange;

  @override
  int get hashCode => period.hashCode ^ customDate.hashCode ^ customRange.hashCode;
}

final dayWiseReportProvider = FutureProvider.family<List<DayWiseReport>, ReportFilterQuery>((ref, query) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.fetchDayWiseReports(
    period: query.period,
    customDate: query.customDate,
    customRange: query.customRange,
  );
});

final reportsKpiProvider = Provider.family<ReportsSummaryKPI, List<DayWiseReport>>((ref, reports) {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.calculateKPI(reports);
});
