/// Supported sorting options for search results.
enum TransactionSortOption {
  newest('Newest First'),
  oldest('Oldest First'),
  highestAmount('Highest Amount'),
  lowestAmount('Lowest Amount');

  final String label;
  const TransactionSortOption(this.label);
}
