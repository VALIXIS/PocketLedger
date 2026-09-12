import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/financial_context_engine.dart';
import '../../../../core/ai/gemini_ai_service.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isAnomalyAlert;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isAnomalyAlert = false,
  });
}

class AIAssistantState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final FinancialTelemetry? telemetry;

  AIAssistantState({
    required this.messages,
    required this.isLoading,
    this.telemetry,
  });

  AIAssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    FinancialTelemetry? telemetry,
  }) {
    return AIAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      telemetry: telemetry ?? this.telemetry,
    );
  }
}

final geminiAIServiceProvider = Provider<GeminiAIService>((ref) {
  return GeminiAIService();
});

class AIAssistantNotifier extends StateNotifier<AIAssistantState> {
  final Ref ref;

  AIAssistantNotifier(this.ref)
      : super(
          AIAssistantState(
            messages: [
              ChatMessage(
                id: 'welcome',
                text:
                    "👋 **Hello! I am PocketLedger AI Advisor.**\n\nI analyze your transaction telemetry locally and provide real-time budget coaching, spending anomaly detection, and financial insights.\n\nTap a quick action below or ask me any question!",
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ],
            isLoading: false,
          ),
        );

  Future<void> sendUserQuery(String queryText) async {
    if (queryText.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: queryText.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    final transactionsAsync = ref.read(transactionListProvider);
    final transactions = transactionsAsync.value ?? [];
    final telemetry = FinancialContextEngine.aggregate(transactions);

    final aiService = ref.read(geminiAIServiceProvider);
    final aiAnswer = await aiService.answerFinancialQuestion(queryText, telemetry);

    final aiMsg = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: aiAnswer,
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
      telemetry: telemetry,
    );
  }

  Future<void> triggerSummary() async {
    state = state.copyWith(isLoading: true);

    final transactionsAsync = ref.read(transactionListProvider);
    final transactions = transactionsAsync.value ?? [];
    final telemetry = FinancialContextEngine.aggregate(transactions);

    final aiService = ref.read(geminiAIServiceProvider);
    final summaryText = await aiService.generateFinancialSummary(telemetry);

    final aiMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: summaryText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
      telemetry: telemetry,
    );
  }

  Future<void> triggerBudgetRecommendations() async {
    state = state.copyWith(isLoading: true);

    final transactionsAsync = ref.read(transactionListProvider);
    final transactions = transactionsAsync.value ?? [];
    final telemetry = FinancialContextEngine.aggregate(transactions);

    final aiService = ref.read(geminiAIServiceProvider);
    final recText = await aiService.generateBudgetRecommendations(telemetry);

    final aiMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: recText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
      telemetry: telemetry,
    );
  }

  void clearChat() {
    state = AIAssistantState(
      messages: [
        ChatMessage(
          id: 'welcome',
          text:
              "👋 **Hello! I am PocketLedger AI Advisor.**\n\nI analyze your transaction telemetry locally and provide real-time budget coaching, spending anomaly detection, and financial insights.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AIAssistantNotifier, AIAssistantState>((ref) {
      return AIAssistantNotifier(ref);
    });
