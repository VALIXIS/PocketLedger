import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/core/ai/financial_context_engine.dart';
import 'package:pocketledger/core/utilities/demo_data_seeder.dart';
import 'package:pocketledger/core/utilities/report_export_helper.dart';

void main() {
  group('Demo Data Seeder & Report Export Tests', () {
    test('sampleTransactions contains valid list of realistic transactions', () {
      final samples = DemoDataSeeder.sampleTransactions;

      expect(samples, isNotEmpty);
      expect(samples.length, greaterThanOrEqualTo(10));
      expect(samples.any((tx) => tx.category == 'salary'), isTrue);
      expect(samples.any((tx) => tx.category == 'food'), isTrue);
    });

    test('generateMarkdownReport generates clean formatted report', () {
      final samples = DemoDataSeeder.sampleTransactions;
      final telemetry = FinancialContextEngine.aggregate(samples);

      final report = ReportExportHelper.generateMarkdownReport(telemetry);

      expect(report, contains('# PocketLedger — AI Financial Telemetry Report'));
      expect(report, contains('Total Income:'));
      expect(report, contains('Total Expenses:'));
      expect(report, contains('Category Spending Breakdown'));
    });
  });
}
