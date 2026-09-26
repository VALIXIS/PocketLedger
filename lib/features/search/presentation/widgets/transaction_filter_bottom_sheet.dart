import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/category_ui_helper.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../providers/search_providers.dart';

/// Material 3 Bottom Sheet providing multi-parameter transaction filtering.
class TransactionFilterBottomSheet extends ConsumerStatefulWidget {
  const TransactionFilterBottomSheet({super.key});

  /// Helper static method to display the modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const TransactionFilterBottomSheet(),
    );
  }

  @override
  ConsumerState<TransactionFilterBottomSheet> createState() =>
      _TransactionFilterBottomSheetState();
}

class _TransactionFilterBottomSheetState
    extends ConsumerState<TransactionFilterBottomSheet> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  TransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(searchNotifierProvider);

    _selectedCategory = currentState.categoryId;
    _startDate = currentState.startDate;
    _endDate = currentState.endDate;
    _selectedType = currentState.transactionType;

    _minAmountController = TextEditingController(
      text: currentState.minAmount != null
          ? currentState.minAmount!.toStringAsFixed(2)
          : '',
    );
    _maxAmountController = TextEditingController(
      text: currentState.maxAmount != null
          ? currentState.maxAmount!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: _endDate ?? DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _applyFilters() {
    final minVal = double.tryParse(_minAmountController.text.trim());
    final maxVal = double.tryParse(_maxAmountController.text.trim());

    final notifier = ref.read(searchNotifierProvider.notifier);
    notifier.setCategory(_selectedCategory);
    notifier.setDateRange(_startDate, _endDate);
    notifier.setAmountRange(minAmount: minVal, maxAmount: maxVal);
    notifier.setTransactionType(_selectedType);

    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
      _selectedType = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
    ref.read(searchNotifierProvider.notifier).clearAllFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    final categories = categoriesAsync.maybeWhen(
      data: (cats) => cats.isNotEmpty ? cats : Category.defaultCategories,
      orElse: () => Category.defaultCategories,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Transactions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filter Form Contents
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Transaction Type
                  Text(
                    'Transaction Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<TransactionType?>(
                    segments: const [
                      ButtonSegment(
                        value: null,
                        label: Text('All'),
                        icon: Icon(Icons.all_inclusive),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // 2. Category Selector
                  Text(
                    'Category',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat.id;
                      final catIcon = CategoryUiHelper.getIcon(cat.id);
                      final catColor = CategoryUiHelper.getColor(cat.id);

                      return FilterChip(
                        avatar: CircleAvatar(
                          backgroundColor: catColor.withValues(alpha: 0.2),
                          child: Icon(catIcon, size: 14, color: catColor),
                        ),
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? cat.id : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 3. Date Range Selector
                  Text(
                    'Date Range',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickStartDate,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                          ),
                          label: Text(
                            _startDate != null
                                ? CurrencyFormatter.formatDate(_startDate!)
                                : 'Start Date',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_startDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Clear start date',
                          onPressed: () => setState(() => _startDate = null),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickEndDate,
                          icon: const Icon(
                            Icons.event_available_outlined,
                            size: 16,
                          ),
                          label: Text(
                            _endDate != null
                                ? CurrencyFormatter.formatDate(_endDate!)
                                : 'End Date',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_endDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Clear end date',
                          onPressed: () => setState(() => _endDate = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4. Amount Range Selector
                  Text(
                    'Amount Range (${settings.currency})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('filter_min_amount_field'),
                          controller: _minAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Min Amount',
                            prefixText: '${settings.currency} ',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          key: const Key('filter_max_amount_field'),
                          controller: _maxAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Max Amount',
                            prefixText: '${settings.currency} ',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _applyFilters,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
