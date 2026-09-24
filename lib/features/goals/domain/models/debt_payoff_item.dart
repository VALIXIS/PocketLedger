/// Represents one debt account used by the payoff calculators.
///
/// All monetary values are stored as integer cents.
/// Example:
/// ₹10,000.50 => 1000050 cents.
class DebtPayoffItem {
  final String id;
  final String name;

  /// Current outstanding principal in cents.
  final int balanceInCents;

  /// Annual percentage rate.
  ///
  /// Example:
  /// 12.5 means 12.5% APR.
  final double annualInterestRate;

  /// Required minimum monthly payment in cents.
  final int minimumPaymentInCents;

  /// Optional credit/debt limit in cents.
  final int? creditLimitInCents;

  /// Optional category/type.
  final String? category;

  const DebtPayoffItem({
    required this.id,
    required this.name,
    required this.balanceInCents,
    required this.annualInterestRate,
    required this.minimumPaymentInCents,
    this.creditLimitInCents,
    this.category,
  });

  bool get isPaidOff => balanceInCents <= 0;

  DebtPayoffItem copyWith({
    String? id,
    String? name,
    int? balanceInCents,
    double? annualInterestRate,
    int? minimumPaymentInCents,
    int? creditLimitInCents,
    String? category,
  }) {
    return DebtPayoffItem(
      id: id ?? this.id,
      name: name ?? this.name,
      balanceInCents: balanceInCents ?? this.balanceInCents,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      minimumPaymentInCents:
          minimumPaymentInCents ?? this.minimumPaymentInCents,
      creditLimitInCents: creditLimitInCents ?? this.creditLimitInCents,
      category: category ?? this.category,
    );
  }
}
