import 'financial_context_engine.dart';

class GeminiAIService {
  final String apiKey;

  GeminiAIService({this.apiKey = ''});

  /// Analyzes telemetry and returns an executive financial summary
  Future<String> generateFinancialSummary(FinancialTelemetry telemetry) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulated AI generation latency

    if (telemetry.totalTransactionCount == 0) {
      return "📊 **Financial Overview**\n\nNo transaction records were found in your ledger. Add your income and expenses to generate real-time AI insights!";
    }

    final net = telemetry.netBalance;
    final income = telemetry.totalIncome;
    final expense = telemetry.totalExpenses;

    final statusEmoji = net >= 0 ? '🟢' : '🔴';
    final statusText = net >= 0
        ? "Positive Net Cash Flow"
        : "Operating at a Deficit";

    final topCategory = telemetry.topCategories.isNotEmpty
        ? telemetry.topCategories.first.categoryId
        : 'N/A';

    final topCategoryPct = telemetry.topCategories.isNotEmpty
        ? telemetry.topCategories.first.percentageOfTotal.toStringAsFixed(1)
        : '0';

    return """
$statusEmoji **Financial Health Summary** ($statusText)

• **Total Income:** \$${income.toStringAsFixed(2)}
• **Total Expenses:** \$${expense.toStringAsFixed(2)}
• **Net Savings:** \$${net.toStringAsFixed(2)} (${income > 0 ? ((net / income) * 100).toStringAsFixed(1) : 0}% savings rate)

📌 **Key Spending Focus:**
Your primary spending category is **$topCategory**, representing **$topCategoryPct%** of your overall expenditures.
${telemetry.anomalyAlerts.isNotEmpty ? '\n⚠️ **Alerts Detected:**\n' + telemetry.anomalyAlerts.map((a) => '• $a').join('\n') : '\n✅ No critical spending anomalies detected.'}
""";
  }

  /// Generates AI budget recommendations based on spending distribution
  Future<String> generateBudgetRecommendations(FinancialTelemetry telemetry) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (telemetry.totalExpensesInCents == 0) {
      return "💡 **AI Budget Recommendation**\n\nAdd expense transactions to receive personalized category budget caps.";
    }

    final buffer = StringBuffer();
    buffer.writeln("💡 **AI Recommended Monthly Category Budgets**\n");
    buffer.writeln("Based on your spending telemetry, here are recommended monthly limits to optimize your savings rate:\n");

    for (final cat in telemetry.topCategories) {
      final monthlySpend = cat.totalInCents / 100.0;
      final recommendedCap = (monthlySpend * 0.9).roundToDouble(); // Recommend 10% reduction cap
      final categoryName = cat.categoryId.substring(0, 1).toUpperCase() +
          cat.categoryId.substring(1).replaceAll('_', ' ');

      buffer.writeln("• **$categoryName**: \$${recommendedCap.toStringAsFixed(2)} / month");
      buffer.writeln("  *(Current: \$${monthlySpend.toStringAsFixed(2)} | Target 10% reduction)*\n");
    }

    return buffer.toString();
  }

  /// Answers natural language questions using local financial telemetry
  Future<String> answerFinancialQuestion(
    String query,
    FinancialTelemetry telemetry,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final q = query.toLowerCase().trim();

    if (q.contains('income') || q.contains('earn') || q.contains('made')) {
      return "💰 **Income Insight:**\nYour total recorded income is **\$${telemetry.totalIncome.toStringAsFixed(2)}** across ${telemetry.totalTransactionCount} total transactions.";
    }

    if (q.contains('expense') || q.contains('spent') || q.contains('cost') || q.contains('spending')) {
      if (telemetry.topCategories.isNotEmpty) {
        final top = telemetry.topCategories.first;
        return "💸 **Expense Breakdown:**\nYour total expenses stand at **\$${telemetry.totalExpenses.toStringAsFixed(2)}**.\n\nYour highest expenditure category is **${top.categoryId}** at **\$${(top.totalInCents / 100.0).toStringAsFixed(2)}** (${top.percentageOfTotal.toStringAsFixed(1)}% of all expenses).";
      }
      return "💸 **Expense Breakdown:** Total recorded expenses are **\$${telemetry.totalExpenses.toStringAsFixed(2)}**.";
    }

    if (q.contains('save') || q.contains('saving') || q.contains('balance')) {
      final savingsRate = telemetry.totalIncome > 0
          ? ((telemetry.netBalance / telemetry.totalIncome) * 100).toStringAsFixed(1)
          : '0';
      return "🏦 **Savings & Balance:**\nYour current net balance is **\$${telemetry.netBalance.toStringAsFixed(2)}**.\nYour current savings rate is **$savingsRate%**.";
    }

    if (q.contains('anomaly') || q.contains('alert') || q.contains('warning')) {
      if (telemetry.anomalyAlerts.isEmpty) {
        return "🛡️ **Anomaly Audit:** No irregular spending spikes or budget overruns were detected in your ledger!";
      }
      return "⚠️ **Anomaly Audit:**\n" + telemetry.anomalyAlerts.map((a) => "• $a").join('\n');
    }

    // Default intelligent response synthesis
    return """
🤖 **PocketLedger AI Financial Advisory**

Based on your local transaction ledger:
• **Net Balance:** \$${telemetry.netBalance.toStringAsFixed(2)}
• **Income vs Expense Ratio:** \$${telemetry.totalIncome.toStringAsFixed(2)} / \$${telemetry.totalExpenses.toStringAsFixed(2)}
• **Total Transactions Logged:** ${telemetry.totalTransactionCount}

You can ask me specific questions like:
- *"How much did I spend?"*
- *"Show my income"*
- *"What are my spending anomalies?"*
- *"Give me budget recommendations"*
""";
  }
}
