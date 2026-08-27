class InputValidators {
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    // Check if it's a valid decimal number
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    // Limit to two decimal places
    if (value.contains('.')) {
      final decimalPlaces = value.split('.')[1].length;
      if (decimalPlaces > 2) {
        return 'Maximum 2 decimal places allowed';
      }
    }

    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category is required';
    }
    return null;
  }
}
