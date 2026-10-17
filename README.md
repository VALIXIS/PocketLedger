# 💼 PocketLedger — Encrypted Personal Finance & Expense Manager

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-00D2B8)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/Database-Hive%20NoSQL-F89820)](https://pub.dev/packages/hive)
[![Charts](https://img.shields.io/badge/Visuals-FL%20Chart-FF6F00)](https://pub.dev/packages/fl_chart)
[![Security](https://img.shields.io/badge/Encryption-AES%20%2F%20PointyCastle-green)](https://pub.dev/packages/encrypt)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**PocketLedger** is a private, offline-first personal expense tracking and financial budgeting mobile application developed with **Flutter** and **Riverpod**. Built adhering strictly to **Clean Architecture** principles, PocketLedger empowers individuals to take full command of their personal cash flow, recurring subscription renewals, budget caps, and multi-category expense trends without leaking financial data to remote cloud servers.

---

## 🌟 Key Features

### 💰 Transaction Tracking & Cash Flow
* **Income & Expense Logging**: Rapid transaction logging with customizable tags, payment modes (Cash, Debit Card, Credit Card, UPI/Bank), and receipt notes.
* **Smart Categorization**: Granular categorization (Food & Dining, Utilities, Housing, Travel, Investments, Shopping, Healthcare).
* **Multi-Currency & Formatting**: Formatted currency rendering with custom symbol preferences.

### 🔄 Recurring Subscriptions & Renewal Manager
* **Subscription Management**: Track recurring monthly/annual subscriptions (Netflix, Spotify, SaaS tools, Gym memberships).
* **Upcoming Renewal Alerts**: Visual countdown chips (`UpcomingPaymentCountdown`) and automated alerts before renewal deadlines.
* **Auto-Recurring Generator**: Automatically logs recurring transactions on designated billing cycles (`AutoRecurringTransactionGenerator`).

### 📊 Deep Financial Analytics & Charts
* **Interactive Breakdown Charts**: High-performance category pie charts and spending trend bar graphs powered by `fl_chart`.
* **Cash Flow Trajectory**: Month-over-month income vs. expense balance comparisons.
* **Budget Threshold Warnings**: Real-time spending progress bars warning users when spending approaches category limits.

### 🔍 Advanced Instant Search & Filtering
* **Multi-Factor Filter Bottom Sheet**: Filter transactions simultaneously by date range, minimum/maximum amount, transaction type, and category tags (`TransactionSearchService`).
* **Instant Keyboard Filtering**: Real-time debounce searching across transaction descriptions and payees.

### 🛡️ End-to-End Local Vault Encryption
* **Client-Side Cryptography**: Sensitive financial records are encrypted on-device before storage using **AES** and **PointyCastle** algorithms.
* **100% Offline Resilience**: Operates entirely without network dependencies; zero financial logs leave your phone.

---

## 🏛️ Clean Architecture Design

PocketLedger enforces strict layer separation across all feature modules:

```
lib/
├── core/                    # Global theme, formatting utilities, constants
└── features/
    ├── analytics/           # Spending reports and FL Chart visualizations
    ├── budget/              # Category spending targets and limits
    ├── recurring/           # Subscriptions & recurring ledger items
    │   ├── data/            # Local data sources & Hive models
    │   ├── domain/          # Entities & repository contracts
    │   ├── presentation/    # Riverpod notifiers, screens, and widgets
    │   └── services/        # Automated cycle generator
    ├── search/              # Multi-faceted transaction search engine
    ├── settings/            # Currency selector, security, theme toggles
    └── transactions/        # Core ledger management
        ├── data/            # TransactionLocalDataSource & TransactionRepositoryImpl
        ├── domain/          # Transaction entities and use-cases
        └── presentation/    # TransactionFormScreen, TransactionListNotifier
```

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: `^3.12.2` or higher
* **Dart SDK**: `^3.12.2`
* **Android Studio / Xcode**: For mobile compilation

### Setup & Run

1. **Clone the Repository**
   ```bash
   git clone https://github.com/smiley-13/PocketLedger.git
   cd PocketLedger
   ```

2. **Install Flutter Packages**
   ```bash
   flutter pub get
   ```

3. **Generate Code & Hive Adapters**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Launch Application**
   ```bash
   # Run on connected mobile device or emulator
   flutter run
   ```

---

## 📦 Key Dependencies

| Dependency | Purpose |
| :--- | :--- |
| `flutter_riverpod` | Unidirectional reactive state management |
| `hive` & `hive_flutter` | High-performance, lightweight local NoSQL storage engine |
| `fl_chart` | Rich, responsive financial graphs and category breakdowns |
| `encrypt` & `pointycastle` | Strong cryptographic encryption primitives for data privacy |
| `intl` | International currency, number, and date formatting |
| `uuid` | Unique transaction identifier generation |

---

## 🧪 Testing & Code Quality

Run the unit and widget test suite:
```bash
flutter test
```

Execute Dart static analysis:
```bash
flutter analyze
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
