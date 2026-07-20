import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories_impl/dynamic_repositories.dart';
import 'data/services/firebase_service.dart';
import 'data/services/seed_data_service.dart';
import 'data/services/sync_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/ocr_scan_repository.dart';
import 'domain/repositories/invoice_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'presentation/providers/invoice_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Sync Service (handles offline-first database synchronization)
  await SyncService().initialize();

  // Initialize Firebase with Mock Fallback support
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Auto-seed initial sample data to Firebase if Firestore is empty
  await SeedDataService.seedIfEmpty();

  // Create repository wrappers that dynamically switch modes
  final authRepository = DynamicAuthRepository();
  final userRepository = DynamicUserRepository();
  final transactionRepository = DynamicTransactionRepository();
  final categoryRepository = DynamicCategoryRepository();
  final ocrScanRepository = DynamicOCRScanRepository();
  final invoiceRepository = DynamicInvoiceRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<UserRepository>.value(value: userRepository),
        Provider<TransactionRepository>.value(value: transactionRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<OCRScanRepository>.value(value: ocrScanRepository),
        Provider<InvoiceRepository>.value(value: invoiceRepository),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: authRepository,
            userRepository: userRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(
            transactionRepository: transactionRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(
            categoryRepository: categoryRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => InvoiceProvider(
            invoiceRepository: context.read<InvoiceRepository>(),
            transactionRepository: context.read<TransactionRepository>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MyAppContent();
  }
}

class _MyAppContent extends StatefulWidget {
  const _MyAppContent();

  @override
  State<_MyAppContent> createState() => _MyAppContentState();
}

class _MyAppContentState extends State<_MyAppContent> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Cache the router configuration once at the startup
    _router = AppRouter.createRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Viper Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
