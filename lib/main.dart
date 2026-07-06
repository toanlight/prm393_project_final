import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories_impl/dynamic_repositories.dart';
import 'data/services/firebase_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with Mock Fallback support
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Create repository wrappers that dynamically switch modes
  final authRepository = DynamicAuthRepository();
  final userRepository = DynamicUserRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<UserRepository>.value(value: userRepository),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: authRepository,
            userRepository: userRepository,
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
