/// Standard multi-tag quick filters for rapid transaction filtering.
enum QuickFilterTag {
  income('Income'),
  expense('Expense'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month');

  final String label;
  const QuickFilterTag(this.label);

  /// Returns true if this tag represents a transaction type filter.
  bool get isTypeTag =>
      this == QuickFilterTag.income || this == QuickFilterTag.expense;

  /// Returns true if this tag represents a date period filter.
  bool get isDateTag =>
      this == QuickFilterTag.today ||
      this == QuickFilterTag.thisWeek ||
      this == QuickFilterTag.thisMonth;
}
