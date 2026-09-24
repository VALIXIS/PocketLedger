import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utilities/category_ui_helper.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/recurring_transaction.dart';
import '../providers/recurring_list_notifier.dart';

class RecurringForm extends ConsumerStatefulWidget {
  final RecurringTransaction? transaction;

  const RecurringForm({super.key, this.transaction});

  static Future<void> showAdd(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const RecurringForm(),
    );
  }

  static Future<void> showEdit(
    BuildContext context,
    RecurringTransaction transaction,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => RecurringForm(transaction: transaction),
    );
  }

  @override
  ConsumerState<RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<RecurringForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _merchantController;
  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  late final TextEditingController _reminderDaysController;

  late bool _isIncome;
  late String _selectedCategory;
  late RecurrenceType _selectedRecurrence;
  late DateTime _startDate;
  late DateTime _nextOccurrence;
  DateTime? _endDate;
  late bool _reminderEnabled;
  late String _selectedIconName;
  late RecurringTransactionStatus _selectedStatus;
  bool _isSubmitting = false;

  bool get _isEditing => widget.transaction != null;

  static const List<String> _expenseCategories = [
    'bills',
    'entertainment',
    'shopping',
    'food',
    'transport',
    'education',
    'health',
    'travel',
    'expense_other',
  ];

  static const List<String> _incomeCategories = [
    'salary',
    'freelance',
    'business',
    'investment',
    'income_other',
  ];

  static const List<String> _availableIcons = [
    'repeat',
    'receipt_long',
    'movie',
    'music_note',
    'fitness_center',
    'wifi',
    'bolt',
    'phone_android',
    'home',
    'directions_car',
  ];

  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'phone_android':
        return Icons.phone_android_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'repeat':
      default:
        return Icons.repeat_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    final now = DateTime.now();

    _nameController = TextEditingController(text: tx?.name ?? '');
    _merchantController = TextEditingController(text: tx?.merchantName ?? '');
    _descController = TextEditingController(text: tx?.description ?? '');
    _amountController = TextEditingController(
      text: tx != null ? (tx.amountInCents / 100).toStringAsFixed(2) : '',
    );
    _reminderDaysController = TextEditingController(
      text: (tx?.reminderDaysBefore ?? 3).toString(),
    );

    _isIncome = tx?.isIncome ?? false;
    _selectedCategory = tx?.category ?? (_isIncome ? 'salary' : 'bills');
    _selectedRecurrence = tx?.recurrenceType ?? RecurrenceType.monthly;
    _startDate = tx?.startDate ?? now;
    _nextOccurrence = tx?.nextOccurrence ?? now;
    _endDate = tx?.endDate;
    _reminderEnabled = tx?.reminderEnabled ?? true;
    _selectedIconName = tx?.iconName ?? 'repeat';
    _selectedStatus = tx?.status ?? RecurringTransactionStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _merchantController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _reminderDaysController.dispose();
    super.dispose();
  }

  int _parseCents(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(cleaned) ?? 0.0;
    return (parsed * 100).round();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2070),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_nextOccurrence.isBefore(_startDate)) {
          _nextOccurrence = _startDate;
        }
      });
    }
  }

  Future<void> _selectNextOccurrence() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextOccurrence,
      firstDate: DateTime(2020),
      lastDate: DateTime(2070),
    );
    if (picked != null) {
      setState(() => _nextOccurrence = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final initial = _endDate ?? _nextOccurrence.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_startDate) ? _startDate : initial,
      firstDate: _startDate,
      lastDate: DateTime(2070),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amountCents = _parseCents(_amountController.text);
    if (amountCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than zero'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final reminderDays = int.tryParse(_reminderDaysController.text) ?? 3;
    if (reminderDays < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder days before cannot be negative'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      if (_isEditing) {
        final existing = widget.transaction!;
        final updated = existing.copyWith(
          name: _nameController.text.trim(),
          merchantName: _merchantController.text.trim(),
          description: _descController.text.trim(),
          amountInCents: amountCents,
          isIncome: _isIncome,
          category: _selectedCategory,
          recurrenceType: _selectedRecurrence,
          startDate: _startDate,
          nextOccurrence: _nextOccurrence,
          endDate: _endDate,
          clearEndDate: _endDate == null,
          status: _selectedStatus,
          reminderEnabled: _reminderEnabled,
          reminderDaysBefore: reminderDays,
          iconName: _selectedIconName,
          updatedAt: now,
        );

        await ref
            .read(recurringListNotifierProvider.notifier)
            .updateRecurringTransaction(updated);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recurring payment "${updated.name}" updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final newTx = RecurringTransaction(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          merchantName: _merchantController.text.trim(),
          description: _descController.text.trim(),
          amountInCents: amountCents,
          isIncome: _isIncome,
          category: _selectedCategory,
          recurrenceType: _selectedRecurrence,
          startDate: _startDate,
          nextOccurrence: _nextOccurrence,
          endDate: _endDate,
          status: RecurringTransactionStatus.active,
          reminderEnabled: _reminderEnabled,
          reminderDaysBefore: reminderDays,
          iconName: _selectedIconName,
          createdAt: now,
          updatedAt: now,
        );

        await ref
            .read(recurringListNotifierProvider.notifier)
            .addRecurringTransaction(newTx);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recurring payment "${newTx.name}" added! 🔄'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recurring payment: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(settingsProvider).currency;
    final availableCategories = _isIncome
        ? _incomeCategories
        : _expenseCategories;

    if (!availableCategories.contains(_selectedCategory)) {
      _selectedCategory = availableCategories.first;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing
                        ? 'Edit Recurring Payment'
                        : 'New Recurring Payment',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Income vs Expense Segment
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward_rounded, color: Colors.red),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Income'),
                    icon: Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.green,
                    ),
                  ),
                ],
                selected: {_isIncome},
                onSelectionChanged: (set) {
                  setState(() {
                    _isIncome = set.first;
                    _selectedCategory = _isIncome
                        ? _incomeCategories.first
                        : _expenseCategories.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Subscription / Payment Name *',
                  hintText: 'e.g. Netflix, Rent, Spotify, Salary',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Merchant / Provider
              TextFormField(
                controller: _merchantController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Merchant / Provider (Optional)',
                  hintText: 'e.g. Netflix Inc., Landlord',
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount ($currency) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final cents = _parseCents(val);
                  if (cents <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recurrence Type Selector
              Text(
                'Billing Cycle *',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<RecurrenceType>(
                segments: const [
                  ButtonSegment(
                    value: RecurrenceType.weekly,
                    label: Text('Weekly'),
                  ),
                  ButtonSegment(
                    value: RecurrenceType.monthly,
                    label: Text('Monthly'),
                  ),
                  ButtonSegment(
                    value: RecurrenceType.yearly,
                    label: Text('Annual'),
                  ),
                ],
                selected: {_selectedRecurrence},
                onSelectionChanged: (set) {
                  setState(() => _selectedRecurrence = set.first);
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(CategoryUiHelper.getIcon(_selectedCategory)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: availableCategories.map((cat) {
                  final catName =
                      cat.substring(0, 1).toUpperCase() +
                      cat.substring(1).replaceAll('_', ' ');
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(
                          CategoryUiHelper.getIcon(cat),
                          size: 18,
                          color: CategoryUiHelper.getColor(cat),
                        ),
                        const SizedBox(width: 8),
                        Text(catName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Start Date & Next Occurrence
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          prefixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          CurrencyFormatter.formatDate(_startDate),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectNextOccurrence,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Next Due Date',
                          prefixIcon: const Icon(
                            Icons.schedule_rounded,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          CurrencyFormatter.formatDate(_nextOccurrence),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // End Date (Optional)
              InkWell(
                onTap: _selectEndDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date / Expiration (Optional)',
                    prefixIcon: const Icon(Icons.event_busy_outlined),
                    suffixIcon: _endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setState(() => _endDate = null),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _endDate != null
                        ? CurrencyFormatter.formatDate(_endDate!)
                        : 'No end date (Continuous)',
                    style: TextStyle(
                      color: _endDate != null
                          ? theme.textTheme.bodyMedium?.color
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status (Only on Edit)
              if (_isEditing) ...[
                DropdownButtonFormField<RecurringTransactionStatus>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: const Icon(Icons.info_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: RecurringTransactionStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Reminder Switch & Days
              SwitchListTile(
                title: const Text('Renewal Reminder'),
                subtitle: const Text('Get notified before payment is due'),
                value: _reminderEnabled,
                onChanged: (val) => setState(() => _reminderEnabled = val),
                contentPadding: EdgeInsets.zero,
              ),
              if (_reminderEnabled) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reminderDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Remind me (Days before)',
                    hintText: '3',
                    prefixIcon: const Icon(Icons.alarm_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final parsed = int.tryParse(val);
                    if (parsed == null || parsed < 0) {
                      return 'Must be 0 or greater';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Icon Picker
              Text(
                'Choose Icon',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableIcons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final iconName = _availableIcons[index];
                    final isSelected = iconName == _selectedIconName;
                    final iconData = getIconData(iconName);

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedIconName = iconName);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.cardColor,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade700,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Notes (Optional)',
                  hintText: 'Add notes about this subscription...',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save / Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
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
                      onPressed: _isSubmitting ? null : _saveTransaction,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Add Payment'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
