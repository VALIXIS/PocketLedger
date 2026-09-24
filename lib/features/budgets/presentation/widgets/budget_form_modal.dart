import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_list_notifier.dart';

class BudgetFormModal extends ConsumerStatefulWidget {
  final Budget? existingBudget;

  const BudgetFormModal({super.key, this.existingBudget});

  static Future<void> show(BuildContext context, {Budget? existingBudget}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => BudgetFormModal(existingBudget: existingBudget),
    );
  }

  @override
  ConsumerState<BudgetFormModal> createState() => _BudgetFormModalState();
}

class _BudgetFormModalState extends ConsumerState<BudgetFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late BudgetPeriod _selectedPeriod;
  late DateTime _startDate;
  late bool _rolloverEnabled;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBudget;
    _nameController = TextEditingController(text: b?.name ?? '');
    _amountController = TextEditingController(
      text: b != null ? (b.amountInCents / 100.0).toStringAsFixed(2) : '',
    );
    _categoryController = TextEditingController(text: b?.categoryId ?? '');
    _selectedPeriod = b?.period ?? BudgetPeriod.monthly;
    _startDate = b?.startDate ?? DateTime.now();
    _rolloverEnabled = b?.rolloverEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final amountDouble = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final amountInCents = (amountDouble * 100).round();

    final budget = Budget(
      id:
          widget.existingBudget?.id ??
          'budget_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      amountInCents: amountInCents,
      period: _selectedPeriod,
      startDate: _startDate,
      categoryId: _categoryController.text.trim(),
      rolloverEnabled: _rolloverEnabled,
    );

    try {
      final notifier = ref.read(budgetListNotifierProvider.notifier);
      if (widget.existingBudget == null) {
        await notifier.addBudget(budget);
      } else {
        await notifier.updateBudget(budget);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingBudget == null
                  ? 'Budget created successfully!'
                  : 'Budget updated successfully!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingBudget != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Budget' : 'Add New Budget',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close modal',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Budget Name',
                  hintText: 'e.g. Monthly Groceries',
                  prefixIcon: Icon(Icons.label_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a budget name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Allocation Amount (₹)',
                  hintText: 'e.g. 10000',
                  prefixIcon: Icon(Icons.currency_rupee_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  hintText: 'e.g. food, transport',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Budget Period',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<BudgetPeriod>(
                segments: const [
                  ButtonSegment(
                    value: BudgetPeriod.weekly,
                    label: Text('Weekly'),
                    icon: Icon(Icons.view_week_outlined),
                  ),
                  ButtonSegment(
                    value: BudgetPeriod.monthly,
                    label: Text('Monthly'),
                    icon: Icon(Icons.calendar_month_outlined),
                  ),
                  ButtonSegment(
                    value: BudgetPeriod.yearly,
                    label: Text('Yearly'),
                    icon: Icon(Icons.calendar_today_outlined),
                  ),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedPeriod = set.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickStartDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat.yMMMd().format(_startDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Enable Budget Rollover'),
                subtitle: const Text('Unused budget carries into next period'),
                value: _rolloverEnabled,
                onChanged: (val) {
                  setState(() {
                    _rolloverEnabled = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isEdit ? Icons.check : Icons.add),
                label: Text(
                  _isSubmitting
                      ? 'Saving...'
                      : (isEdit ? 'Save Changes' : 'Create Budget'),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
