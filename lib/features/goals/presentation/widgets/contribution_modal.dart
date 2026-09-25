import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/financial_goal.dart';
import '../providers/goal_list_notifier.dart';

class ContributionModal extends ConsumerStatefulWidget {
  final FinancialGoal goal;

  const ContributionModal({super.key, required this.goal});

  static Future<void> show(BuildContext context, FinancialGoal goal) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ContributionModal(goal: goal),
    );
  }

  @override
  ConsumerState<ContributionModal> createState() => _ContributionModalState();
}

class _ContributionModalState extends ConsumerState<ContributionModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _enteredAmountInCents = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      if (_enteredAmountInCents != 0) {
        setState(() {
          _enteredAmountInCents = 0;
        });
      }
      return;
    }

    final parsedDouble = double.tryParse(text);
    if (parsedDouble != null && parsedDouble > 0) {
      final cents = (parsedDouble * 100).round();
      if (cents != _enteredAmountInCents) {
        setState(() {
          _enteredAmountInCents = cents;
        });
      }
    } else {
      if (_enteredAmountInCents != 0) {
        setState(() {
          _enteredAmountInCents = 0;
        });
      }
    }
  }

  void _addQuickAmount(int dollars) {
    final currentText = _amountController.text.trim();
    final currentVal = double.tryParse(currentText) ?? 0.0;
    final newVal = currentVal + dollars;
    _amountController.text = newVal % 1 == 0
        ? newVal.toInt().toString()
        : newVal.toStringAsFixed(2);
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) return;
    if (_enteredAmountInCents <= 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currency = ref.read(settingsProvider).currency;

    try {
      await ref
          .read(goalListNotifierProvider.notifier)
          .addContribution(widget.goal.id, _enteredAmountInCents);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${CurrencyFormatter.formatCents(_enteredAmountInCents, currency)} added to ${widget.goal.name}',
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final newTotalInCents =
        widget.goal.savedAmountInCents + _enteredAmountInCents;
    final newProgress = widget.goal.targetAmountInCents > 0
        ? (newTotalInCents / widget.goal.targetAmountInCents).clamp(0.0, 1.0)
        : 1.0;
    final newPercentage = (newProgress * 100).toStringAsFixed(1);
    final willReachTarget =
        newTotalInCents >= widget.goal.targetAmountInCents &&
        widget.goal.targetAmountInCents > 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 8.0,
        bottom: bottomInset + 20.0,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.savings_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add to Goal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.goal.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Current Status Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1E262B)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Saved',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatCents(
                            widget.goal.savedAmountInCents,
                            settings.currency,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatCents(
                            widget.goal.targetAmountInCents,
                            settings.currency,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Contribution Amount',
                  hintText: '0.00',
                  prefixText: '${settings.currency} ',
                  prefixStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Quick Amount Chips
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('+10'),
                    onPressed: () => _addQuickAmount(10),
                  ),
                  ActionChip(
                    label: const Text('+50'),
                    onPressed: () => _addQuickAmount(50),
                  ),
                  ActionChip(
                    label: const Text('+100'),
                    onPressed: () => _addQuickAmount(100),
                  ),
                  ActionChip(
                    label: const Text('+500'),
                    onPressed: () => _addQuickAmount(500),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview Section
              if (_enteredAmountInCents > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: willReachTarget
                        ? Colors.green.shade50
                        : theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: willReachTarget
                          ? Colors.green.shade300
                          : theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        willReachTarget
                            ? '🏆 Target Reached!'
                            : 'After contribution:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: willReachTarget
                              ? Colors.green.shade800
                              : theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.formatCents(newTotalInCents, settings.currency)} ($newPercentage%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: willReachTarget
                              ? Colors.green.shade800
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error banner if any
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
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
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitContribution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Add Contribution',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
