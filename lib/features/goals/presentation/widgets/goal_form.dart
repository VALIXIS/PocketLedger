import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/accessibility/accessible_date_picker.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/financial_goal.dart';
import '../providers/goal_list_notifier.dart';
import 'goal_card.dart';

class GoalForm extends ConsumerStatefulWidget {
  final FinancialGoal? goal;

  const GoalForm({super.key, this.goal});

  static Future<void> showAddGoal(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const GoalForm(),
    );
  }

  static Future<void> showEditGoal(BuildContext context, FinancialGoal goal) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => GoalForm(goal: goal),
    );
  }

  @override
  ConsumerState<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<GoalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _savedAmountController;

  DateTime? _selectedTargetDate;
  late String _selectedIconName;
  late int _selectedColorValue;
  late GoalStatus _selectedStatus;
  bool _isSubmitting = false;

  static const List<String> _availableIcons = [
    'savings',
    'home',
    'car',
    'flight',
    'laptop',
    'school',
    'shopping',
    'heart',
    'emergency',
    'investment',
  ];

  static const List<int> _availableColors = [
    0xFF4CAF50, // Green
    0xFF2196F3, // Blue
    0xFF9C27B0, // Purple
    0xFFFF9800, // Orange
    0xFFE91E63, // Pink
    0xFF009688, // Teal
    0xFF3F51B5, // Indigo
    0xFFFF5722, // Deep Orange
    0xFF00BCD4, // Cyan
    0xFFFFC107, // Amber
  ];

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _descController = TextEditingController(text: g?.description ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? (g.targetAmountInCents / 100).toStringAsFixed(2) : '',
    );
    _savedAmountController = TextEditingController(
      text: g != null ? (g.savedAmountInCents / 100).toStringAsFixed(2) : '',
    );

    _selectedTargetDate = g?.targetDate;
    _selectedIconName = g?.iconName ?? 'savings';
    _selectedColorValue = g?.colorValue ?? 0xFF4CAF50;
    _selectedStatus = g?.status ?? GoalStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetAmountController.dispose();
    _savedAmountController.dispose();
    super.dispose();
  }

  int _parseCents(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(cleaned) ?? 0.0;
    return (parsed * 100).round();
  }

  Future<void> _selectTargetDate() async {
    final now = DateTime.now();
    final initial = _selectedTargetDate ?? now.add(const Duration(days: 90));
    final firstDate = DateTime(now.year - 1, 1, 1);
    final lastDate = DateTime(now.year + 50, 12, 31);

    final picked = await showAccessibleDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final targetCents = _parseCents(_targetAmountController.text);
    if (targetCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target amount must be greater than zero'),
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
        final existing = widget.goal!;
        final savedCents = _savedAmountController.text.isNotEmpty
            ? _parseCents(_savedAmountController.text)
            : existing.savedAmountInCents;

        final updated = existing.copyWith(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          targetAmountInCents: targetCents,
          savedAmountInCents: savedCents,
          targetDate: _selectedTargetDate,
          clearTargetDate: _selectedTargetDate == null,
          status: _selectedStatus,
          iconName: _selectedIconName,
          colorValue: _selectedColorValue,
          updatedAt: now,
        );

        await ref.read(goalListNotifierProvider.notifier).updateGoal(updated);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Goal "${updated.name}" updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final savedCents = _savedAmountController.text.isNotEmpty
            ? _parseCents(_savedAmountController.text)
            : 0;

        final isTargetReached = savedCents >= targetCents;
        final newGoal = FinancialGoal(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          targetAmountInCents: targetCents,
          savedAmountInCents: savedCents,
          targetDate: _selectedTargetDate,
          status: isTargetReached ? GoalStatus.completed : GoalStatus.active,
          iconName: _selectedIconName,
          colorValue: _selectedColorValue,
          createdAt: now,
          updatedAt: now,
        );

        await ref.read(goalListNotifierProvider.notifier).addGoal(newGoal);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Goal "${newGoal.name}" created successfully! 🎯'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal: $e'),
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
                    _isEditing ? 'Edit Savings Goal' : 'New Savings Goal',
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

              // Goal Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Goal Name *',
                  hintText: 'e.g. New Car, Emergency Fund',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add some details or notes...',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Target Amount
              TextFormField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Target Amount ($currency) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter target amount';
                  }
                  final cents = _parseCents(val);
                  if (cents <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Saved Amount (Starting or current)
              TextFormField(
                controller: _savedAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Current Saved Amount ($currency)'
                      : 'Starting Saved Amount ($currency, Optional)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.savings_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Target Date Picker
              InkWell(
                onTap: _selectTargetDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Target Date (Optional)',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: _selectedTargetDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() => _selectedTargetDate = null);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedTargetDate != null
                        ? CurrencyFormatter.formatDate(_selectedTargetDate!)
                        : 'Select deadline date',
                    style: TextStyle(
                      color: _selectedTargetDate != null
                          ? theme.textTheme.bodyMedium?.color
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status (Only on Edit)
              if (_isEditing) ...[
                DropdownButtonFormField<GoalStatus>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: const Icon(Icons.info_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: GoalStatus.values.map((status) {
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
                    final iconData = GoalCard.getIconData(iconName);

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
              const SizedBox(height: 16),

              // Color Picker
              Text(
                'Choose Color',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final colorValue = _availableColors[index];
                    final color = Color(colorValue);
                    final isSelected = colorValue == _selectedColorValue;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedColorValue = colorValue);
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  },
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
                      onPressed: _isSubmitting ? null : _saveGoal,
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
                          : Text(_isEditing ? 'Save Changes' : 'Create Goal'),
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
