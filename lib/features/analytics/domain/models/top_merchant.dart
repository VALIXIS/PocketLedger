import 'package:flutter/foundation.dart';

@immutable
class TopMerchant {
  final String merchantName;
  final double totalSpending;
  final int transactionCount;

  const TopMerchant({
    required this.merchantName,
    required this.totalSpending,
    required this.transactionCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopMerchant &&
          runtimeType == other.runtimeType &&
          merchantName == other.merchantName &&
          totalSpending == other.totalSpending &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode =>
      merchantName.hashCode ^ totalSpending.hashCode ^ transactionCount.hashCode;

  @override
  String toString() {
    return 'TopMerchant($merchantName: \$totalSpending over $transactionCount txs)';
  }
}
