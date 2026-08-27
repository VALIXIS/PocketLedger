import 'package:flutter/material.dart';

class CategoryUiHelper {
  static IconData getIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      // Income
      case 'salary':
        return Icons.work_outline;
      case 'freelance':
        return Icons.laptop_mac;
      case 'business':
        return Icons.storefront;
      case 'investment':
        return Icons.show_chart;
      case 'income_other':
        return Icons.account_balance_wallet_outlined;
      // Expense
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'entertainment':
        return Icons.local_play_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'health':
        return Icons.favorite_border;
      case 'travel':
        return Icons.flight_takeoff;
      case 'expense_other':
        return Icons.payment_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  static Color getColor(String categoryId) {
    switch (categoryId.toLowerCase()) {
      // Income
      case 'salary':
        return Colors.green;
      case 'freelance':
        return Colors.teal;
      case 'business':
        return Colors.blue;
      case 'investment':
        return Colors.purple;
      case 'income_other':
        return Colors.grey.shade600;
      // Expense
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.pink;
      case 'bills':
        return Colors.amber.shade700;
      case 'entertainment':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'health':
        return Colors.teal;
      case 'travel':
        return Colors.cyan.shade700;
      case 'expense_other':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade700;
    }
  }
}
