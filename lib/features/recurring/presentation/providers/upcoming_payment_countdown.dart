import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recurring_transaction.dart';
import '../../domain/repositories/recurring_repository.dart';
import 'recurring_list_notifier.dart';

abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class UpcomingPaymentCountdown {
  final RecurringTransaction recurringTransaction;
  final DateTime occurrence;
  final Duration remaining;
  final int totalSeconds;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final bool isDueToday;
  final bool isOverdue;
  final bool isUpcoming;

  const UpcomingPaymentCountdown({
    required this.recurringTransaction,
    required this.occurrence,
    required this.remaining,
    required this.totalSeconds,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.isDueToday,
    required this.isOverdue,
    required this.isUpcoming,
  });

  factory UpcomingPaymentCountdown.calculate({
    required RecurringTransaction recurringTransaction,
    required DateTime now,
  }) {
    final occurrence = recurringTransaction.nextOccurrence;
    final isDueToday =
        occurrence.year == now.year &&
        occurrence.month == now.month &&
        occurrence.day == now.day;
    final isOverdue = occurrence.isBefore(now);
    final isUpcoming = !isOverdue;

    final Duration remaining;
    final int totalSeconds;
    final int days;
    final int hours;
    final int minutes;
    final int seconds;

    if (isOverdue) {
      remaining = Duration.zero;
      totalSeconds = 0;
      days = 0;
      hours = 0;
      minutes = 0;
      seconds = 0;
    } else {
      final difference = occurrence.difference(now);
      remaining = difference;
      totalSeconds = difference.inSeconds;
      days = difference.inDays;
      hours = difference.inHours % 24;
      minutes = difference.inMinutes % 60;
      seconds = difference.inSeconds % 60;
    }

    return UpcomingPaymentCountdown(
      recurringTransaction: recurringTransaction,
      occurrence: occurrence,
      remaining: remaining,
      totalSeconds: totalSeconds,
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      isDueToday: isDueToday,
      isOverdue: isOverdue,
      isUpcoming: isUpcoming,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpcomingPaymentCountdown &&
          runtimeType == other.runtimeType &&
          recurringTransaction == other.recurringTransaction &&
          occurrence == other.occurrence &&
          remaining == other.remaining &&
          totalSeconds == other.totalSeconds &&
          days == other.days &&
          hours == other.hours &&
          minutes == other.minutes &&
          seconds == other.seconds &&
          isDueToday == other.isDueToday &&
          isOverdue == other.isOverdue &&
          isUpcoming == other.isUpcoming;

  @override
  int get hashCode =>
      recurringTransaction.hashCode ^
      occurrence.hashCode ^
      remaining.hashCode ^
      totalSeconds.hashCode ^
      days.hashCode ^
      hours.hashCode ^
      minutes.hashCode ^
      seconds.hashCode ^
      isDueToday.hashCode ^
      isOverdue.hashCode ^
      isUpcoming.hashCode;
}

class CountdownState {
  final List<UpcomingPaymentCountdown> upcomingPayments;
  final UpcomingPaymentCountdown? nearestPayment;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastCalculatedAt;
  final String? userId;

  const CountdownState({
    this.upcomingPayments = const [],
    this.nearestPayment,
    this.isLoading = false,
    this.errorMessage,
    this.lastCalculatedAt,
    this.userId,
  });

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get isEmpty => upcomingPayments.isEmpty;

  CountdownState copyWith({
    List<UpcomingPaymentCountdown>? upcomingPayments,
    UpcomingPaymentCountdown? nearestPayment,
    bool clearNearestPayment = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastCalculatedAt,
    String? userId,
    bool clearUserId = false,
  }) {
    return CountdownState(
      upcomingPayments: upcomingPayments != null
          ? List.unmodifiable(upcomingPayments)
          : this.upcomingPayments,
      nearestPayment: clearNearestPayment
          ? null
          : (nearestPayment ?? this.nearestPayment),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
      userId: clearUserId ? null : (userId ?? this.userId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountdownState &&
          runtimeType == other.runtimeType &&
          nearestPayment == other.nearestPayment &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          lastCalculatedAt == other.lastCalculatedAt &&
          userId == other.userId &&
          _listEquals(upcomingPayments, other.upcomingPayments);

  static bool _listEquals(
    List<UpcomingPaymentCountdown> a,
    List<UpcomingPaymentCountdown> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      upcomingPayments.hashCode ^
      nearestPayment.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode ^
      lastCalculatedAt.hashCode ^
      userId.hashCode;
}

class UpcomingPaymentCountdownNotifier extends StateNotifier<CountdownState> {
  final RecurringRepository repository;
  final Clock clock;
  final bool autoStartTimer;

  Timer? _timer;
  List<RecurringTransaction> _cachedTransactions = [];

  UpcomingPaymentCountdownNotifier({
    required this.repository,
    Clock? clock,
    String? userId,
    this.autoStartTimer = true,
  }) : clock = clock ?? const SystemClock(),
       super(CountdownState(userId: userId)) {
    loadAndStart();
  }

  bool get isTimerRunning => _timer != null && _timer!.isActive;

  void setUserId(String? userId) {
    if (state.userId != userId) {
      state = state.copyWith(userId: userId);
      loadAndStart();
    }
  }

  Future<void> loadAndStart() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final List<RecurringTransaction> fetched;
      if (state.userId != null && state.userId!.isNotEmpty) {
        fetched = await repository.getRecurringTransactionsForUser(
          state.userId!,
        );
      } else {
        fetched = await repository.getAllRecurringTransactions();
      }

      // Filter active and non-ended transactions
      _cachedTransactions = fetched
          .where(
            (tx) =>
                tx.status == RecurringTransactionStatus.active && !tx.hasEnded,
          )
          .toList();

      _recalculate();

      if (autoStartTimer) {
        _startTimer();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void updateWithTransactions(List<RecurringTransaction> transactions) {
    _cachedTransactions = transactions
        .where(
          (tx) =>
              tx.status == RecurringTransactionStatus.active && !tx.hasEnded,
        )
        .toList();
    _recalculate();
  }

  void recalculateNow() {
    _recalculate();
  }

  void _recalculate() {
    final now = clock.now();
    final List<UpcomingPaymentCountdown> countdowns = [];

    for (final tx in _cachedTransactions) {
      if (tx.status == RecurringTransactionStatus.active && !tx.hasEnded) {
        countdowns.add(
          UpcomingPaymentCountdown.calculate(
            recurringTransaction: tx,
            now: now,
          ),
        );
      }
    }

    // Sort by occurrence ascending (nearest first)
    countdowns.sort((a, b) => a.occurrence.compareTo(b.occurrence));

    final nearest = countdowns.isNotEmpty ? countdowns.first : null;

    state = state.copyWith(
      upcomingPayments: countdowns,
      nearestPayment: nearest,
      clearNearestPayment: countdowns.isEmpty,
      isLoading: false,
      lastCalculatedAt: now,
      clearError: true,
    );
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recalculate();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    await loadAndStart();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

// Global Providers
final clockProvider = Provider<Clock>((ref) {
  return const SystemClock();
});

final upcomingPaymentCountdownProvider =
    StateNotifierProvider.autoDispose<
      UpcomingPaymentCountdownNotifier,
      CountdownState
    >((ref) {
      final repository = ref.watch(recurringRepositoryProvider);
      final clock = ref.watch(clockProvider);
      return UpcomingPaymentCountdownNotifier(
        repository: repository,
        clock: clock,
      );
    });
